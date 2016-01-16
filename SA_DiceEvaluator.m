//
//  SA_DiceEvaluator.m
//  RPGBot
//
//  Created by Sandy Achmiz on 1/2/16.
//
//

#import "SA_DiceEvaluator.h"

#import "SA_DiceBag.h"
#import "SA_DiceParser.h"
#import "SA_DiceExpressionStringConstants.h"
#import "SA_DiceErrorHandling.h"

/**************************/
#pragma mark Defined values
/**************************/

#define DEFAULT_MAX_DIE_COUNT	 1000	// One thousand
#define DEFAULT_MAX_DIE_SIZE	10000	// Ten thousand

/***************************************************/
#pragma mark - SA_DiceEvaluator class implementation
/***************************************************/

@implementation SA_DiceEvaluator
{
	NSInteger _maxDieCount;
	NSInteger _maxDieSize;
}

/************************/
#pragma mark - Properties
/************************/

- (NSInteger)maxDieCount
{
	return _maxDieCount;
}
- (void)setMaxDieCount:(NSInteger)maxDieCount
{
	if(maxDieCount < 1)
	{
		_maxDieCount = 1;
	}
	else if(maxDieCount > NSIntegerMax / _maxDieSize)
	{
		_maxDieCount = NSIntegerMax / _maxDieSize;
	}
	else
	{
		_maxDieCount = maxDieCount;
	}
}

- (NSInteger)maxDieSize
{
	return _maxDieSize;
}
- (void)setMaxDieSize:(NSInteger)maxDieSize
{
	if(maxDieSize < 1)
	{
		_maxDieSize = 1;
	}
	else if(maxDieSize > [self.diceBag biggestPossibleDieSize] || maxDieSize > NSIntegerMax / _maxDieCount)
	{
		_maxDieSize = ([self.diceBag biggestPossibleDieSize] < (NSIntegerMax / _maxDieCount)) ? [_diceBag biggestPossibleDieSize] : NSIntegerMax / _maxDieCount;
	}
	else
	{
		_maxDieSize = maxDieSize;
	}
}

/**************************/
#pragma mark - Initializers
/**************************/

- (instancetype)init
{
	if(self = [super init])
	{
		_maxDieCount = DEFAULT_MAX_DIE_COUNT;
		_maxDieSize = DEFAULT_MAX_DIE_SIZE;
		
		self.diceBag = [[SA_DiceBag alloc] init];
	}
	return self;
}

/****************************/
#pragma mark - Public methods
/****************************/

- (NSMutableDictionary *)resultOfExpression:(NSDictionary *)expression
{
	// Check to see if the expression is erroneous (i.e. the parser has judged
	// that it is malformed, etc.). If so, decline to evaluate the expression;
	// return (a mutable copy of) it, unchanged.
	if(getErrorsForExpression(expression) != nil)
	{
		return [expression mutableCopy];
	}
	
	/*
	 Even if an expression is not erroneous (i.e. if it has no syntax errors), 
	 it may still not be possible to evaluate it. For example, '5d0' is a 
	 perfectly well-formed die string, and will yield an expression tree as follows:
	 
	 @{SA_DB_TERM_TYPE		: SA_DB_TERM_TYPE_ROLL_COMMAND,
	   SA_DB_ROLL_COMMAND	: SA_DB_ROLL_COMMAND_SUM,
	   SA_DB_ROLL_DIE_COUNT	: @{SA_DB_TERM_TYPE : SA_DB_TERM_TYPE_VALUE,
								SA_DB_VALUE		: @(5)
								},
	   SA_DB_ROLL_DIE_SIZE	: @{SA_DB_TERM_TYPE : SA_DB_TERM_TYPE_VALUE,
								SA_DB_VALUE		: @(0)
								}
	   }
	 
	 This is, of course, an illegal expression; we can't roll a die of size 0 
	 (a die with zero sides?).
	 
	 If we encounter such an illegal expression, we add an appropriate error to 
	 the term. We are not required to set a value for the SA_DB_RESULT key in 
	 such a case.
	 */
	
	// Check to see if the current term is an operation.
	if([expression[SA_DB_TERM_TYPE] isEqualToString:SA_DB_TERM_TYPE_OPERATION])
	{
		return [self resultOfExpressionDescribingOperation:expression];
	}
	// Check to see if the current term is a roll command.
	else if([expression[SA_DB_TERM_TYPE] isEqualToString:SA_DB_TERM_TYPE_ROLL_COMMAND])
	{
		return [self resultOfExpressionDescribingRollCommand:expression];
	}
	// If not an operation or a roll command, the current term can only be a 
	// simple value expression (term type of SA_DB_TERM_TYPE_VALUE).
	else
	{
		return [self resultOfExpressionDescribingValue:expression];
	}
}

/****************************/
#pragma mark - Helper methods
/****************************/

- (NSMutableDictionary *)resultOfExpressionDescribingValue:(NSDictionary *)expression
{
	NSMutableDictionary *result = [expression mutableCopy];
	
	result[SA_DB_RESULT] = result[SA_DB_VALUE];
	
	return result;
}

- (NSMutableDictionary *)resultOfExpressionDescribingRollCommand:(NSDictionary *)expression
{
	NSMutableDictionary *result = [expression mutableCopy];
	
	// For now, only a simple sum is supported. Other sorts of roll commands
	// may be added later.
	if([result[SA_DB_ROLL_COMMAND] isEqualToString:SA_DB_ROLL_COMMAND_SUM])
	{
		// First, recursively evaluate the expressions that represent the
		// die size and die count.
		result[SA_DB_ROLL_DIE_COUNT] = [self resultOfExpression:result[SA_DB_ROLL_DIE_COUNT]];
		result[SA_DB_ROLL_DIE_SIZE] = [self resultOfExpression:result[SA_DB_ROLL_DIE_SIZE]];
		
		// Evaluating those expressions may have generated an error(s); 
		// propagate any errors up to the current term.
		addErrorsFromExpressionToExpression(result[SA_DB_ROLL_DIE_COUNT], result);
		addErrorsFromExpressionToExpression(result[SA_DB_ROLL_DIE_SIZE], result);
		
		// If indeed we've turned up errors, return.
		if(getErrorsForExpression(result) != nil)
		{
			return result;
		}
		
		// Evaluating the two sub-expressions didn't generate errors; this means
		// that we have successfully generated values for both the die count and
		// the die size...
		NSInteger dieCount = [result[SA_DB_ROLL_DIE_COUNT][SA_DB_RESULT] integerValue];
		NSInteger dieSize = [result[SA_DB_ROLL_DIE_SIZE][SA_DB_RESULT] integerValue];
		
		// ... but, the resulting values of the expressions may make it 
		// impossible to evaluate the roll command. Check to see whether the die
		// count and die size have legal values.
		if(dieCount < 0)
		{
			addErrorToExpression(SA_DB_ERROR_DIE_COUNT_NEGATIVE, result);
		}
		else if(dieCount > _maxDieCount)
		{
			addErrorToExpression(SA_DB_ERROR_DIE_COUNT_EXCESSIVE, result);
		}
		
		if(dieSize < 1)
		{
			addErrorToExpression(SA_DB_ERROR_DIE_SIZE_INVALID, result);
		}
		else if(dieSize > _maxDieSize)
		{
			addErrorToExpression(SA_DB_ERROR_DIE_SIZE_EXCESSIVE, result);
		}
		
		// If indeed the die count or die size fall outside of their allowed 
		// ranges, return.
		if(getErrorsForExpression(result) != nil)
		{
			return result;
		}
		
		// The die count and die size have legal values. We can safely roll the
		// requisite number of dice, and take the sum of the rolls (if needed).
		// NOTE: _maxDieSize is gauranteed to be no greater than the largest die
		// size that the SA_DiceBag can roll (this is enforced by the setter
		// method for the maxDieSize property), so we need not check to see
		// if the return value of rollDie: or rollNumber:ofDice: is valid.
		// We are also gauranteed that the product of _maxDieCount and 
		// _maxDieSize is no greater than the largest unsigned value that can be
		// stored by whatever numeric type we specify simple value terms (terms
		// of type SA_DB_TERM_TYPE_VALUE) to contain (likewise enforced by the 
		// setters for both maxDieSize and maxDieCount), therefore we need not 
		// worry about overflow here.
		if(dieCount == 0)
		{
			result[SA_DB_RESULT] = @(0);
			result[SA_DB_ROLLS] = @[];
		}
		else if(dieCount == 1)
		{
			NSNumber *roll = @([self.diceBag rollDie:dieSize]);
			
			result[SA_DB_RESULT] = roll;
			result[SA_DB_ROLLS] = @[roll];
		}
		else
		{
			NSArray *rolls = [self.diceBag rollNumber:@(dieCount) ofDice:dieSize];
			
			result[SA_DB_RESULT] = [rolls valueForKeyPath:@"@sum.self"];
			result[SA_DB_ROLLS] = rolls;
		}
		
		// Return the successfully evaluated roll command expression.
		return result;
	}
	else
	{
		addErrorToExpression(SA_DB_ERROR_UNKNOWN_ROLL_COMMAND, result);
		
		return result;
	}
}

- (NSMutableDictionary *)resultOfExpressionDescribingOperation:(NSDictionary *)expression
{
	NSMutableDictionary *result = [expression mutableCopy];
	
	// First, recursively evaluate the expressions that represent the 
	// left-hand-side and right-hand-side operands.
	result[SA_DB_OPERAND_LEFT] = [self resultOfExpression:result[SA_DB_OPERAND_LEFT]];
	result[SA_DB_OPERAND_RIGHT] = [self resultOfExpression:result[SA_DB_OPERAND_RIGHT]];
	
	// Evaluating the operand may have generated an error(s); propagate any
	// errors up to the current term.
	addErrorsFromExpressionToExpression(result[SA_DB_OPERAND_LEFT], result);
	addErrorsFromExpressionToExpression(result[SA_DB_OPERAND_RIGHT], result);
	
	// If indeed we've turned up errors, return.
	if(getErrorsForExpression(result) != nil)
	{
		return result;
	}
	
	// Evaluating the operands didn't generate any errors. We have valid
	// operands.
	NSInteger leftOperand = [result[SA_DB_OPERAND_LEFT][SA_DB_RESULT] integerValue];
	NSInteger rightOperand = [result[SA_DB_OPERAND_RIGHT][SA_DB_RESULT] integerValue];
	
	// Check to see if the operation is subtraction.
	if([result[SA_DB_OPERATOR] isEqualToString:SA_DB_OPERATOR_MINUS])
	{
		// First, we check for possible overflow...
		if(leftOperand > 0  && rightOperand < 0 && NSIntegerMax + rightOperand < leftOperand)
		{
			addErrorToExpression(SA_DB_ERROR_INTEGER_OVERFLOW_SUBTRACTION, result);
			
			return result;
		}
		else if(leftOperand < 0 && rightOperand > 0 && NSIntegerMin + rightOperand > leftOperand)
		{
			addErrorToExpression(SA_DB_ERROR_INTEGER_UNDERFLOW_SUBTRACTION, result);
			
			return result;
		}
		
		// No overflow will occur. We can perform the subtraction operation.
		result[SA_DB_RESULT] = @(leftOperand - rightOperand);
		
		// Return the successfully evaluated negation expression.
		return result;
	}
	// Check to see if the operation is addition.
	else if([result[SA_DB_OPERATOR] isEqualToString:SA_DB_OPERATOR_PLUS])
	{
		// First, we check for possible overflow...
		if(rightOperand > 0 && leftOperand > 0 && NSIntegerMax - rightOperand < leftOperand)
		{
			addErrorToExpression(SA_DB_ERROR_INTEGER_OVERFLOW_ADDITION, result);
			
			return result;
		}
		else if(rightOperand < 0 && leftOperand < 0 && NSIntegerMin - rightOperand > leftOperand)
		{
			addErrorToExpression(SA_DB_ERROR_INTEGER_UNDERFLOW_ADDITION, result);
			
			return result;
		}
		
		// No overflow will occur. We can perform the addition operation.
		result[SA_DB_RESULT] = @(leftOperand + rightOperand);
		
		// Return the successfully evaluated addition expression.
		return result;
	}
	// Check to see if the operation is multiplication.
	else if([result[SA_DB_OPERATOR] isEqualToString:SA_DB_OPERATOR_TIMES])
	{
		// First, we check for possible overflow...
		if( ( leftOperand == NSIntegerMin && ( rightOperand != 0 || rightOperand != 1 ) )  || 
		    ( rightOperand == NSIntegerMin && ( leftOperand != 0 || leftOperand != 1 ) ) || 
			( leftOperand != 0 && ( (NSIntegerMax / ABS(leftOperand)) < rightOperand ) ) )
		{
			if((leftOperand > 0 && rightOperand > 0) || (leftOperand < 0 && rightOperand < 0))
			{
				addErrorToExpression(SA_DB_ERROR_INTEGER_OVERFLOW_MULTIPLICATION, result);
			}
			else
			{
				addErrorToExpression(SA_DB_ERROR_INTEGER_UNDERFLOW_MULTIPLICATION, result);
			}
			
			return result;
		}
		
		// No overflow will occur. We can perform the multiplication operation.
		result[SA_DB_RESULT] = @(leftOperand * rightOperand);
		
		// Return the successfully evaluated multiplication expression.
		return result;
	}
	// The operation is not one of the supported operators.
	else
	{
		// We add the appropriate error. We do not set a value for the 
		// SA_DB_RESULT key.
		
		addErrorToExpression(SA_DB_ERROR_UNKNOWN_OPERATOR, result);
		
		return result;
	}
}

@end
