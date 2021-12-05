//
//  SA_DiceExpression.h
//  SA_IRCBotServer
//
//  Created by Said Achmiz on 6/23/19.
//
//

#import <Foundation/Foundation.h>

/***********************/
#pragma mark Definitions
/***********************/

typedef NS_ENUM(NSUInteger, SA_DiceExpressionTermType) {
	SA_DiceExpressionTerm_NONE,
	SA_DiceExpressionTerm_OPERATION,
	SA_DiceExpressionTerm_ROLL_COMMAND,
	SA_DiceExpressionTerm_ROLL_MODIFIER,
	SA_DiceExpressionTerm_VALUE
};

typedef NS_ENUM(NSUInteger, SA_DiceExpressionOperator) {
	SA_DiceExpressionOperator_NONE,
	SA_DiceExpressionOperator_MINUS,
	SA_DiceExpressionOperator_PLUS,
	SA_DiceExpressionOperator_TIMES
};

typedef NS_ENUM(NSUInteger, SA_DiceExpressionRollCommand) {
	SA_DiceExpressionRollCommand_NONE,
	SA_DiceExpressionRollCommand_SUM,
	SA_DiceExpressionRollCommand_SUM_EXPLODING
};

typedef NS_ENUM(NSUInteger, SA_DiceExpressionDieType) {
	SA_DiceExpressionDice_STANDARD,
	SA_DiceExpressionDice_FUDGE
};

typedef NS_ENUM(NSUInteger, SA_DiceExpressionRollModifier) {
	SA_DiceExpressionRollModifier_NONE,
	SA_DiceExpressionRollModifier_KEEP_HIGHEST,
	SA_DiceExpressionRollModifier_KEEP_LOWEST
};

typedef NS_OPTIONS(NSUInteger, SA_DiceExpressionError) {
	// Errors for expression parsing.
	SA_DiceExpressionError_NONE,
	SA_DiceExpressionError_ROLL_STRING_EMPTY						= 1 <<  0 ,
	SA_DiceExpressionError_ROLL_STRING_HAS_ILLEGAL_CHARACTERS	= 1 <<  1 ,

	// Errors for expression evaluation.
	SA_DiceExpressionError_UNKNOWN_ROLL_COMMAND					= 1 <<  2 ,
	SA_DiceExpressionError_ROLL_MODIFIER_INAPPLICABLE			= 1 <<  3 ,
	SA_DiceExpressionError_UNKNOWN_ROLL_MODIFIER					= 1 <<  4 ,
	SA_DiceExpressionError_DIE_COUNT_NEGATIVE					= 1 <<  5 ,
	SA_DiceExpressionError_DIE_COUNT_EXCESSIVE					= 1 <<  6 ,
	SA_DiceExpressionError_DIE_SIZE_INVALID						= 1 <<  7 ,
	SA_DiceExpressionError_DIE_SIZE_EXCESSIVE					= 1 <<  8 ,
	SA_DiceExpressionError_UNKNOWN_OPERATOR						= 1 <<  9 ,
	SA_DiceExpressionError_INVALID_EXPRESSION					= 1 << 10 ,
	SA_DiceExpressionError_INTEGER_OVERFLOW_NEGATION				= 1 << 11 ,
	SA_DiceExpressionError_INTEGER_OVERFLOW_ADDITION				= 1 << 12 ,
	SA_DiceExpressionError_INTEGER_UNDERFLOW_ADDITION			= 1 << 13 ,
	SA_DiceExpressionError_INTEGER_OVERFLOW_SUBTRACTION			= 1 << 14 ,
	SA_DiceExpressionError_INTEGER_UNDERFLOW_SUBTRACTION			= 1 << 15 ,
	SA_DiceExpressionError_INTEGER_OVERFLOW_MULTIPLICATION		= 1 << 16 ,
	SA_DiceExpressionError_INTEGER_UNDERFLOW_MULTIPLICATION		= 1 << 17 ,
	SA_DiceExpressionError_KEEP_COUNT_EXCEEDS_ROLL_COUNT			= 1 << 18 ,
	SA_DiceExpressionError_KEEP_COUNT_NEGATIVE					= 1 << 19
};

/***********************/
#pragma mark - Functions
/***********************/

NSString *NSStringFromSA_DiceExpressionOperator(SA_DiceExpressionOperator operator);

NSString *NSStringFromSA_DiceExpressionRollCommand(SA_DiceExpressionRollCommand command);

NSString *NSStringFromSA_DiceExpressionRollModifier(SA_DiceExpressionRollModifier modifier);

NSString *NSStringFromSA_DiceExpressionError(SA_DiceExpressionError error);

@class SA_DiceExpression;
NSComparisonResult compareEvaluatedExpressionsByResult(SA_DiceExpression *expression1,
													   SA_DiceExpression *expression2);
NSComparisonResult compareEvaluatedExpressionsByAttemptBonus(SA_DiceExpression *expression1,
															 SA_DiceExpression *expression2);

/*************************************************/
#pragma mark - SA_DiceExpression class declaration
/*************************************************/

@interface SA_DiceExpression : NSObject <NSCopying>

/************************/
#pragma mark - Properties
/************************/

// The expression’s type (operation, roll command, simple value, etc.).
@property SA_DiceExpressionTermType type;

/*==============================================================================
 The following four sets of properties pertain to expressions of specific types.
 */

// Expressions of type SA_DiceExpressionTerm_OPERATION.
@property SA_DiceExpressionOperator operator;
@property (nonatomic, strong) SA_DiceExpression *leftOperand;
@property (nonatomic, strong) SA_DiceExpression *rightOperand;

// Expressions of type SA_DiceExpressionTerm_ROLL_COMMAND.
@property SA_DiceExpressionRollCommand rollCommand;
@property (nonatomic, strong) SA_DiceExpression *dieCount;
@property (nonatomic, strong) SA_DiceExpression *dieSize;
@property SA_DiceExpressionDieType dieType;

// Expressions of type SA_DiceExpressionTerm_ROLL_MODIFIER.
@property SA_DiceExpressionRollModifier rollModifier;

// Expressions of type SA_DiceExpressionTerm_VALUE.
@property (nonatomic, strong) NSNumber *value;

/*===================================================
 The following properties pertain to all expressions.
 */

@property SA_DiceExpressionError errorBitMask;

@property (copy, nonatomic) NSString *inputString;
@property (copy, nonatomic) NSAttributedString *attributedInputString;

/*=========================================================================
 The following properties pertain to evaluated expressions only.
 (They have a nil value for expressions which have not yet been evaluated.)
 */

// Evaluated expressions (of any type).
@property (nonatomic, strong) NSNumber *result;

// Evaluated expressions of type SA_DiceExpressionTerm_ROLL_COMMAND.
@property (nonatomic, strong) NSArray <NSNumber *> *rolls;

/****************************/
#pragma mark - Public methods
/****************************/

+(instancetype) expressionByJoiningExpression:(SA_DiceExpression *)leftHandExpression
								 toExpression:(SA_DiceExpression *)rightHandExpression
								 withOperator:(SA_DiceExpressionOperator)operator;

@end
