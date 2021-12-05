//
//  SA_DiceEvaluator.m
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.

#import "SA_DiceEvaluator.h"

#import "SA_DiceBag.h"
#import "SA_DiceParser.h"
#import "SA_DiceExpression.h"
#import "SA_DiceExpressionStringConstants.h"

#import "SA_Utility.h"

/**************************/
#pragma mark Defined values
/**************************/

#define DEFAULT_MAX_DIE_COUNT	 1000	// One thousand
#define DEFAULT_MAX_DIE_SIZE	10000	// Ten thousand

/***************************************************/
#pragma mark - SA_DiceEvaluator class implementation
/***************************************************/

@implementation SA_DiceEvaluator {
	SA_DiceBag *_diceBag;

	NSUInteger _maxDieCount;
	NSUInteger _maxDieSize;
}

/************************/
#pragma mark - Properties
/************************/

-(NSUInteger) maxDieCount {
	return _maxDieCount;
}
-(void) setMaxDieCount:(NSUInteger)maxDieCount {
	if (maxDieCount > (NSUIntegerMax / _maxDieSize)) {
		_maxDieCount = NSUIntegerMax / _maxDieSize;
	} else {
		_maxDieCount = maxDieCount;
	}
}

-(NSUInteger) maxDieSize {
	return _maxDieSize;
}
-(void) setMaxDieSize:(NSUInteger)maxDieSize {
	if (   maxDieSize > [_diceBag biggestPossibleDieSize]
		|| maxDieSize > (NSIntegerMax / _maxDieCount)) {
		_maxDieSize = (([_diceBag biggestPossibleDieSize] < (NSIntegerMax / _maxDieCount))
					   ? [_diceBag biggestPossibleDieSize]
					   : (NSIntegerMax / _maxDieCount));
	} else {
		_maxDieSize = maxDieSize;
	}
}

/**************************/
#pragma mark - Initializers
/**************************/

-(instancetype) init {
	if (!(self = [super init]))
		return nil;

	_maxDieCount = DEFAULT_MAX_DIE_COUNT;
	_maxDieSize = DEFAULT_MAX_DIE_SIZE;

	_diceBag = [SA_DiceBag new];

	return self;
}

/****************************/
#pragma mark - Public methods
/****************************/

// TODO: Possibly refuse to evaluate an expression that’s already evaluated?
// (i.e., it has a  ...  .result?? .value??)
-(SA_DiceExpression *) resultOfExpression:(SA_DiceExpression *)expression {
	// Check to see if the expression is erroneous (i.e. the parser has judged
	// that it is malformed, etc.). If so, decline to evaluate the expression;
	// return (a copy of) it, unchanged.
	if (expression.errorBitMask != 0) {
		return [expression copy];
	}
	
	/*
	 NOTE: Even if an expression is not erroneous (i.e. if it has no syntax 
	 errors), it may still not be possible to evaluate it. For example, ‘5d0’ 
	 is a perfectly well-formed die string, and will yield an expression tree 
	 as follows:
	 
	 [ type			: SA_DiceExpressionTerm_ROLL_COMMAND,
	   rollCommand	: SA_DiceExpressionRollCommand_SUM,
	   dieCount		: [ type	: SA_DiceExpressionTerm_VALUE,
						value	: @(5)
						],
	   dieSize		: [ type	: SA_DiceExpressionTerm_VALUE,
						value	: @(0)
						]
	   ]
	 
	 This is, of course, an illegal expression; we can’t roll a die of size 0
	 (a die with zero sides?).
	 
	 If we encounter such an illegal expression, we add an appropriate error to 
	 the -[errorBitMask]. We are not required to set a value (-[value] property)
	 in such a case.
	 */

	switch (expression.type) {
		case SA_DiceExpressionTerm_OPERATION: {
			return [self resultOfExpressionDescribingOperation:expression];
			break;
		}
		case SA_DiceExpressionTerm_ROLL_COMMAND: {
			return [self resultOfExpressionDescribingRollCommand:expression];
			break;
		}
		case SA_DiceExpressionTerm_ROLL_MODIFIER: {
			return [self resultOfExpressionDescribingRollModifier:expression];
			break;
		}
		case SA_DiceExpressionTerm_VALUE:
		default: {
			return [self resultOfExpressionDescribingValue:expression];
			break;
		}
	}
}

/****************************/
#pragma mark - Helper methods
/****************************/

-(SA_DiceExpression *) resultOfExpressionDescribingValue:(SA_DiceExpression *)expression {
	SA_DiceExpression *result = [expression copy];
	
	result.result = result.value;
	
	return result;
}

-(SA_DiceExpression *) resultOfExpressionDescribingRollCommand:(SA_DiceExpression *)expression {
	SA_DiceExpression *result = [expression copy];

	// For now, only sum and exploding sum (i.e., sum but with exploding dice)
	// are supported. Other sorts of roll commands may be added later.
	switch (result.rollCommand) {
		case SA_DiceExpressionRollCommand_SUM:
		case SA_DiceExpressionRollCommand_SUM_EXPLODING: {
			// First, recursively evaluate the expressions that represent the
			// die count and (for standard dice) the die size.
			result.dieCount = [self resultOfExpression:result.dieCount];
			if (result.dieType == SA_DiceExpressionDice_STANDARD)
				result.dieSize = [self resultOfExpression:result.dieSize];

			// Evaluating those expressions may have generated an error(s);
			// propagate any errors up to the current term.
			result.errorBitMask |= result.dieCount.errorBitMask;
			if (result.dieType == SA_DiceExpressionDice_STANDARD)
				result.errorBitMask |= result.dieSize.errorBitMask;

			// If indeed we’ve turned up errors, return.
			if (result.errorBitMask != 0)
				return result;

			// Evaluating the two sub-expressions didn’t generate errors; this means
			// that we have successfully generated values for both the die count and
			// (for standard dice) the die size...
			NSInteger dieCount = result.dieCount.result.integerValue;
			NSInteger dieSize = 0;
			if (result.dieType == SA_DiceExpressionDice_STANDARD)
				dieSize = result.dieSize.result.integerValue;

			// ... but, the resulting values of the expressions may make it
			// impossible to evaluate the roll command. Check to see whether the die
			// count and die size have legal values.
			if (dieCount < 0) {
				result.errorBitMask |= SA_DiceExpressionError_DIE_COUNT_NEGATIVE;
			} else if (dieCount > _maxDieCount) {
				result.errorBitMask |= SA_DiceExpressionError_DIE_COUNT_EXCESSIVE;
			}

			// Die type only matters for standard dice, not for Fudge dice.
			if (result.dieType == SA_DiceExpressionDice_STANDARD) {
				if (dieSize < 1) {
					result.errorBitMask |= SA_DiceExpressionError_DIE_SIZE_INVALID;
				} else if (dieSize > _maxDieSize) {
					result.errorBitMask |= SA_DiceExpressionError_DIE_SIZE_EXCESSIVE;
				}
			}

			// If indeed the die count or die size fall outside of their allowed
			// ranges, return.
			if (result.errorBitMask != 0)
				return result;

			// The die count and die size have legal values. We can safely roll the
			// requisite number of dice, and take the sum of the rolls (if needed).
			// NOTE: _maxDieSize is guaranteed to be no greater than the largest die
			// size that the SA_DiceBag can roll (this is enforced by the setter
			// method for the maxDieSize property), so we need not check to see
			// if the return value of rollDie: or rollNumber:ofDice: is valid.
			// We are also guaranteed that the product of _maxDieCount and
			// _maxDieSize is no greater than the largest unsigned value that can be
			// stored by whatever numeric type we specify simple value terms (terms
			// of type SA_DiceExpressionTerm_VALUE) to contain (likewise enforced
			// by the setters for both maxDieSize and maxDieCount), therefore we
			// need not worry about overflow here.
			if (dieCount == 0) {
				result.result = @(0);
				result.rolls = @[];
			} else {
				NSArray *rolls;
				if (result.dieType == SA_DiceExpressionDice_STANDARD) {
					SA_DiceRollingOptions options = (result.rollCommand == SA_DiceExpressionRollCommand_SUM_EXPLODING) ? SA_DiceRollingExplodingDice : 0;
					rolls = [_diceBag rollNumber:dieCount
										  ofDice:dieSize
									 withOptions:options];
				} else if (result.dieType == SA_DiceExpressionDice_FUDGE) {
					rolls = [_diceBag rollFudgeDice:dieCount];
				}

				result.result = [rolls valueForKeyPath:@"@sum.self"];
				result.rolls = rolls;
			}

			break;
		}
		default: {
			result.errorBitMask |= SA_DiceExpressionError_UNKNOWN_ROLL_COMMAND;

			break;
		}
	}

	return result;
}

-(SA_DiceExpression *) resultOfExpressionDescribingRollModifier:(SA_DiceExpression *)expression {
	SA_DiceExpression *result = [expression copy];

	switch (result.rollModifier) {
		case SA_DiceExpressionRollModifier_KEEP_HIGHEST:
		case SA_DiceExpressionRollModifier_KEEP_LOWEST: {
			// These roll modifiers takes the highest, or the lowest, N rolls
			// out of all the rolls generated by a roll command, discarding the
			// rest, and summing the kept ones.

			// First, check if the left-hand operand is a roll command (and
			// specifically, a simple sum; though this latter requirement may
			// be dropped later).
			// TODO: re-evaluate this ^
			// If the left-hand operand is not a roll-and-sum, then the KEEP
			// modifier cannot be applied to it. In that case, we add an error
			// and return the result without evaluating.
			if (   result.leftOperand.type != SA_DiceExpressionTerm_ROLL_COMMAND
				|| (   result.leftOperand.rollCommand != SA_DiceExpressionRollCommand_SUM
					&& result.leftOperand.rollCommand != SA_DiceExpressionRollCommand_SUM_EXPLODING)
				) {
				result.errorBitMask |= SA_DiceExpressionError_ROLL_MODIFIER_INAPPLICABLE;
				return result;
			}

			// We now know the left-hand operand is a roll command. Recursively
			// evaluate the expressions that represent the roll command and the
			// modifier value (the right-hand operand).
			result.leftOperand = [self resultOfExpression:result.leftOperand];
			result.rightOperand = [self resultOfExpression:result.rightOperand];

			// Evaluating the operands may have generated an error(s); propagate any
			// errors up to the current term.
			result.errorBitMask |= result.leftOperand.errorBitMask;
			result.errorBitMask |= result.rightOperand.errorBitMask;

			// If indeed we’ve turned up errors, return.
			if (result.errorBitMask != 0)
				return result;

			// Evaluating the operands didn’t generate any errors; this means
			// that on the left hand we have a set of rolls (as well as a
			// result, which we are ignoring), and on the right hand we have a
			// result, which specifies how many rolls to keep.
			NSArray <NSNumber *> *rolls = result.leftOperand.rolls;
			NSNumber *keepHowMany = result.rightOperand.result;

			// However, it is now possible that the “keep how many” value
			// exceeds the number of rolls, which would make the expression
			// incoherent. If so, add an error and return.
			if (keepHowMany.unsignedIntegerValue > rolls.count) {
				result.errorBitMask |= SA_DiceExpressionError_KEEP_COUNT_EXCEEDS_ROLL_COUNT;
				return result;
			}

			// It is also possible that the “keep how many” value is negative.
			// This, too, would make the expression incoherent. Likewise, add
			// an error and return.
			if (keepHowMany < 0) {
				result.errorBitMask |= SA_DiceExpressionError_KEEP_COUNT_NEGATIVE;
				return result;
			}

			// We sort the rolls array...
			BOOL sortAscending = (result.rollModifier == SA_DiceExpressionRollModifier_KEEP_LOWEST);
			result.rolls = [rolls sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"integerValue"
																							   ascending:sortAscending] ]];

			// And the ‘result’ property of the result expression is the sum of
			// the first <keepHowMany> elements of the sorted rolls array.
			result.result = [[result.rolls subarrayWithRange:NSRangeMake(0, keepHowMany.unsignedIntegerValue)] valueForKeyPath:@"@sum.self"];

			break;
		}
		default: {
			result.errorBitMask |= SA_DiceExpressionError_UNKNOWN_ROLL_MODIFIER;

			break;
		}
	}
	
	return result;
}

-(SA_DiceExpression *) resultOfExpressionDescribingOperation:(SA_DiceExpression *)expression {
	SA_DiceExpression *result = [expression copy];
	
	// First, recursively evaluate the expressions that represent the 
	// left-hand-side and right-hand-side operands.
	result.leftOperand = [self resultOfExpression:result.leftOperand];
	result.rightOperand = [self resultOfExpression:result.rightOperand];
	
	// Evaluating the operands may have generated an error(s); propagate any
	// errors up to the current term.
	result.errorBitMask |= result.leftOperand.errorBitMask;
	result.errorBitMask |= result.rightOperand.errorBitMask;

	// If indeed we’ve turned up errors, return.
	if (result.errorBitMask != 0)
		return result;

	// Evaluating the operands didn’t generate any errors. We have valid
	// operands.
	NSInteger leftOperand = result.leftOperand.result.integerValue;
	NSInteger rightOperand = result.rightOperand.result.integerValue;

	switch (result.operator) {
		case SA_DiceExpressionOperator_MINUS: {
			// First, we check for possible overflow...
			if (   leftOperand > 0
				&& rightOperand < 0
				&& (NSIntegerMax + rightOperand) < leftOperand) {
				result.errorBitMask |= SA_DiceExpressionError_INTEGER_OVERFLOW_SUBTRACTION;
				break;
			} else if (   leftOperand < 0
					   && rightOperand > 0
					   && (NSIntegerMin + rightOperand) > leftOperand) {
				result.errorBitMask |= SA_DiceExpressionError_INTEGER_UNDERFLOW_SUBTRACTION;
				break;
			}

			// No overflow will occur. We can perform the subtraction operation.
			result.result = @(leftOperand - rightOperand);
			break;
		}
		case SA_DiceExpressionOperator_PLUS: {
			// First, we check for possible overflow...
			if (   rightOperand > 0
				&& leftOperand > 0
				&& (NSIntegerMax - rightOperand) < leftOperand) {
				result.errorBitMask |= SA_DiceExpressionError_INTEGER_OVERFLOW_ADDITION;
				break;
			} else if (   rightOperand < 0
					   && leftOperand < 0
					   && (NSIntegerMin - rightOperand) > leftOperand) {
				result.errorBitMask |= SA_DiceExpressionError_INTEGER_UNDERFLOW_ADDITION;
				break;
			}

			// No overflow will occur. We can perform the addition operation.
			result.result = @(leftOperand + rightOperand);
			break;
		}
		case SA_DiceExpressionOperator_TIMES: {
			// First, we check for possible overflow...
			if (   (   leftOperand == NSIntegerMin
					&& (   rightOperand != 0
						|| rightOperand != 1 ))
				|| (   rightOperand == NSIntegerMin
					&& (   leftOperand != 0
						|| leftOperand != 1 ))
				|| (   leftOperand != 0
					&& ((NSIntegerMax / ABS(leftOperand)) < rightOperand))
				) {
				if (   (   leftOperand > 0
						&& rightOperand > 0)
					|| (   leftOperand < 0
						&& rightOperand < 0)) {
					result.errorBitMask |= SA_DiceExpressionError_INTEGER_OVERFLOW_MULTIPLICATION;
				} else {
					result.errorBitMask |= SA_DiceExpressionError_INTEGER_UNDERFLOW_MULTIPLICATION;
				}
				break;
			}

			// No overflow will occur. We can perform the multiplication operation.
			result.result = @(leftOperand * rightOperand);
			break;
		}
		default: {
			// We add the appropriate error. We do not set a value for the
			// result property.
			result.errorBitMask |= SA_DiceExpressionError_UNKNOWN_OPERATOR;
			break;
		}
	}

	return result;
}

@end
