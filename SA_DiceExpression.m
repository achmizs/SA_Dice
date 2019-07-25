//
//  SA_DiceExpression.m
//  SA_IRCBotServer
//
//  Created by Said Achmiz on 6/23/19.
//
//

#import "SA_DiceExpression.h"

/*********************/
#pragma mark Functions
/*********************/

NSString *NSStringFromSA_DiceExpressionOperator(SA_DiceExpressionOperator operator) {
	static NSDictionary <NSNumber *, NSString *> *SA_DiceExpressionOperatorStringValues;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		SA_DiceExpressionOperatorStringValues = @{ @(SA_DiceExpressionOperator_NONE)		: @"SA_DB_OPERATOR_NONE",
												   @(SA_DiceExpressionOperator_MINUS)	: @"SA_DB_OPERATOR_MINUS",
												   @(SA_DiceExpressionOperator_PLUS)		: @"SA_DB_OPERATOR_PLUS",
												   @(SA_DiceExpressionOperator_TIMES)	: @"SA_DB_OPERATOR_TIMES"
												   };
	});

	return SA_DiceExpressionOperatorStringValues[@(operator)];
}

NSString *NSStringFromSA_DiceExpressionRollCommand(SA_DiceExpressionRollCommand command) {
	static NSDictionary <NSNumber *, NSString *> *SA_DiceExpressionRollCommandStringValues;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		SA_DiceExpressionRollCommandStringValues = @{ 	@(SA_DiceExpressionRollCommand_SUM)				: @"SA_DB_ROLL_COMMAND_SUM",
														@(SA_DiceExpressionRollCommand_SUM_EXPLODING)	: @"SA_DB_ROLL_COMMAND_SUM_EXPLODING"
														};
	});

	return SA_DiceExpressionRollCommandStringValues[@(command)];
}

NSString *NSStringFromSA_DiceExpressionRollModifier(SA_DiceExpressionRollModifier modifier) {
	static NSDictionary <NSNumber *, NSString *> *SA_DiceExpressionRollModifierStringValues;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		SA_DiceExpressionRollModifierStringValues = @{ @(SA_DiceExpressionRollModifier_KEEP_HIGHEST)		: @"SA_DB_ROLL_MODIFIER_KEEP_HIGHEST",
													   @(SA_DiceExpressionRollModifier_KEEP_LOWEST)		: @"SA_DB_ROLL_MODIFIER_KEEP_LOWEST"
													   };
	});

	return SA_DiceExpressionRollModifierStringValues[@(modifier)];
}

NSString *NSStringFromSA_DiceExpressionError(SA_DiceExpressionError error) {
	static NSDictionary <NSNumber *, NSString *> *SA_DiceExpressionErrorStringValues;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		SA_DiceExpressionErrorStringValues = @{	@(SA_DiceExpressionError_ROLL_STRING_EMPTY)						: @"SA_DB_ERROR_ROLL_STRING_EMPTY",
												@(SA_DiceExpressionError_ROLL_STRING_HAS_ILLEGAL_CHARACTERS)		: @"SA_DB_ERROR_ROLL_STRING_HAS_ILLEGAL_CHARACTERS",
												@(SA_DiceExpressionError_UNKNOWN_ROLL_COMMAND)					: @"SA_DB_ERROR_UNKNOWN_ROLL_COMMAND",
												@(SA_DiceExpressionError_ROLL_MODIFIER_INAPPLICABLE)				: @"SA_DB_ERROR_ROLL_MODIFIER_INAPPLICABLE",
												@(SA_DiceExpressionError_UNKNOWN_ROLL_MODIFIER)					: @"SA_DB_ERROR_UNKNOWN_ROLL_MODIFIER",
												@(SA_DiceExpressionError_DIE_COUNT_NEGATIVE)						: @"SA_DB_ERROR_DIE_COUNT_NEGATIVE",
												@(SA_DiceExpressionError_DIE_COUNT_EXCESSIVE)					: @"SA_DB_ERROR_DIE_COUNT_EXCESSIVE",
												@(SA_DiceExpressionError_DIE_SIZE_INVALID)						: @"SA_DB_ERROR_DIE_SIZE_INVALID",
												@(SA_DiceExpressionError_DIE_SIZE_EXCESSIVE)						: @"SA_DB_ERROR_DIE_SIZE_EXCESSIVE",
												@(SA_DiceExpressionError_UNKNOWN_OPERATOR)						: @"SA_DB_ERROR_UNKNOWN_OPERATOR",
												@(SA_DiceExpressionError_INVALID_EXPRESSION)						: @"SA_DB_ERROR_INVALID_EXPRESSION",
												@(SA_DiceExpressionError_INTEGER_OVERFLOW_NEGATION)				: @"SA_DB_ERROR_INTEGER_OVERFLOW_NEGATION",
												@(SA_DiceExpressionError_INTEGER_OVERFLOW_ADDITION)				: @"SA_DB_ERROR_INTEGER_OVERFLOW_ADDITION",
												@(SA_DiceExpressionError_INTEGER_UNDERFLOW_ADDITION)				: @"SA_DB_ERROR_INTEGER_UNDERFLOW_ADDITION",
												@(SA_DiceExpressionError_INTEGER_OVERFLOW_SUBTRACTION)			: @"SA_DB_ERROR_INTEGER_OVERFLOW_SUBTRACTION",
												@(SA_DiceExpressionError_INTEGER_UNDERFLOW_SUBTRACTION)			: @"SA_DB_ERROR_INTEGER_UNDERFLOW_SUBTRACTION",
												@(SA_DiceExpressionError_INTEGER_OVERFLOW_MULTIPLICATION)		: @"SA_DB_ERROR_INTEGER_OVERFLOW_MULTIPLICATION",
												@(SA_DiceExpressionError_INTEGER_UNDERFLOW_MULTIPLICATION)		: @"SA_DB_ERROR_INTEGER_UNDERFLOW_MULTIPLICATION",
												@(SA_DiceExpressionError_KEEP_COUNT_EXCEEDS_ROLL_COUNT)			: @"SA_DB_ERROR_KEEP_COUNT_EXCEEDS_ROLL_COUNT",
												@(SA_DiceExpressionError_KEEP_COUNT_NEGATIVE)					: @"SA_DB_ERROR_KEEP_COUNT_NEGATIVE"

												};
	});

	return SA_DiceExpressionErrorStringValues[@(error)];
}

NSComparisonResult compareEvaluatedExpressionsByResult(SA_DiceExpression *expression1,
													   SA_DiceExpression *expression2) {
	if (expression1.result.integerValue < expression2.result.integerValue)
		return NSOrderedAscending;
	else if (expression1.result.integerValue > expression2.result.integerValue)
		return NSOrderedDescending;
	else
		return NSOrderedSame;

}

NSComparisonResult compareEvaluatedExpressionsByAttemptBonus(SA_DiceExpression *expression1,
															 SA_DiceExpression *expression2) {
	if (expression1.rightOperand.result.integerValue < expression2.rightOperand.result.integerValue)
		return NSOrderedAscending;
	else if (expression1.rightOperand.result.integerValue > expression2.rightOperand.result.integerValue)
		return NSOrderedDescending;
	else
		return NSOrderedSame;

}

/****************************************************/
#pragma mark - SA_DiceExpression class implementation
/****************************************************/

@implementation SA_DiceExpression

/*******************************/
#pragma mark - NSCopying methods
/*******************************/

-(instancetype) copyWithZone:(NSZone *)zone {
	SA_DiceExpression *copy = [SA_DiceExpression new];

	copy.type = _type;

	copy.errorBitMask = _errorBitMask;

	copy.operator = _operator;
	copy.leftOperand = [_leftOperand copy];
	copy.rightOperand = [_rightOperand copy];

	copy.rollCommand = _rollCommand;
	copy.dieCount = [_dieCount copy];
	copy.dieSize = [_dieSize copy];
	copy.dieType = _dieType;

	copy.rollModifier = _rollModifier;

	copy.value = _value;

	copy.inputString = _inputString;
	copy.attributedInputString = _attributedInputString;

	copy.result = _result;

	copy.rolls = _rolls;

	return copy;
}

@end
