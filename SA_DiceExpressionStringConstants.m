//
//  SA_DiceExpressionStringConstants.m
//  RPGBot
//
//  Created by Sandy Achmiz on 1/2/16.
//
//

#import "SA_DiceExpressionStringConstants.h"

/***************************************************/
#pragma mark String constants for expression parsing
/***************************************************/

NSString * const SA_DB_TERM_TYPE										=	@"SA_DB_TERM_TYPE";
NSString * const SA_DB_TERM_TYPE_VALUE									=	@"SA_DB_TERM_TYPE_VALUE";
NSString * const SA_DB_TERM_TYPE_ROLL_COMMAND							=	@"SA_DB_TERM_TYPE_ROLL_COMMAND";
NSString * const SA_DB_TERM_TYPE_OPERATION								=	@"SA_DB_TERM_TYPE_OPERATION";
NSString * const SA_DB_TERM_TYPE_NONE									=	@"SA_DB_TERM_TYPE_NONE";

NSString * const SA_DB_ERRORS											=	@"SA_DB_ERRORS";
NSString * const SA_DB_ERROR_ROLL_STRING_EMPTY							=	@"SA_DB_ERROR_ROLL_STRING_EMPTY";
NSString * const SA_DB_ERROR_ROLL_STRING_HAS_ILLEGAL_CHARACTERS			=	@"SA_DB_ERROR_ROLL_STRING_HAS_ILLEGAL_CHARACTERS";

NSString * const SA_DB_OPERATOR											=	@"SA_DB_OPERATOR";
NSString * const SA_DB_OPERATOR_MINUS									=	@"SA_DB_OPERATOR_MINUS";
NSString * const SA_DB_OPERATOR_PLUS									=	@"SA_DB_OPERATOR_PLUS";
NSString * const SA_DB_OPERATOR_TIMES									=	@"SA_DB_OPERATOR_TIMES";
NSString * const SA_DB_OPERAND_LEFT										=	@"SA_DB_OPERAND_LEFT";
NSString * const SA_DB_OPERAND_RIGHT									=	@"SA_DB_OPERAND_RIGHT";

NSString * const SA_DB_ROLL_COMMAND										=	@"SA_DB_ROLL_COMMAND";
NSString * const SA_DB_ROLL_COMMAND_SUM									=	@"SA_DB_ROLL_COMMAND_SUM";
NSString * const SA_DB_ROLL_DIE_COUNT									=	@"SA_DB_ROLL_DIE_COUNT";
NSString * const SA_DB_ROLL_DIE_SIZE									=	@"SA_DB_ROLL_DIE_SIZE";

NSString * const SA_DB_VALUE											=	@"SA_DB_VALUE";

NSString * const SA_DB_INPUT_STRING										=	@"SA_DB_INPUT_STRING";			
NSString * const SA_DB_ATTRIBUTED_INPUT_STRING							=	@"SA_DB_ATTRIBUTED_INPUT_STRING";

/******************************************************/
#pragma mark String constants for expression evaluation
/******************************************************/

NSString * const SA_DB_ERROR_UNKNOWN_ROLL_COMMAND						=	@"SA_DB_ERROR_UNKNOWN_ROLL_COMMAND";
NSString * const SA_DB_ERROR_DIE_COUNT_NEGATIVE							=	@"SA_DB_ERROR_DIE_COUNT_NEGATIVE";
NSString * const SA_DB_ERROR_DIE_COUNT_EXCESSIVE						=	@"SA_DB_ERROR_DIE_COUNT_EXCESSIVE";
NSString * const SA_DB_ERROR_DIE_SIZE_INVALID							=	@"SA_DB_ERROR_DIE_SIZE_INVALID";
NSString * const SA_DB_ERROR_DIE_SIZE_EXCESSIVE							=	@"SA_DB_ERROR_DIE_SIZE_EXCESSIVE";
NSString * const SA_DB_ERROR_UNKNOWN_OPERATOR							=	@"SA_DB_ERROR_UNKNOWN_OPERATOR";
NSString * const SA_DB_ERROR_INVALID_EXPRESSION							=	@"SA_DB_ERROR_INVALID_EXPRESSION";
NSString * const SA_DB_ERROR_INTEGER_OVERFLOW_NEGATION					=	@"SA_DB_ERROR_INTEGER_OVERFLOW_NEGATION";
NSString * const SA_DB_ERROR_INTEGER_OVERFLOW_ADDITION					=	@"SA_DB_ERROR_INTEGER_OVERFLOW_ADDITION";
NSString * const SA_DB_ERROR_INTEGER_UNDERFLOW_ADDITION					=	@"SA_DB_ERROR_INTEGER_UNDERFLOW_ADDITION";
NSString * const SA_DB_ERROR_INTEGER_OVERFLOW_SUBTRACTION				=	@"SA_DB_ERROR_INTEGER_OVERFLOW_SUBTRACTION";
NSString * const SA_DB_ERROR_INTEGER_UNDERFLOW_SUBTRACTION				=	@"SA_DB_ERROR_INTEGER_UNDERFLOW_SUBTRACTION";
NSString * const SA_DB_ERROR_INTEGER_OVERFLOW_MULTIPLICATION			=	@"SA_DB_ERROR_INTEGER_OVERFLOW_MULTIPLICATION";
NSString * const SA_DB_ERROR_INTEGER_UNDERFLOW_MULTIPLICATION			=	@"SA_DB_ERROR_INTEGER_UNDERFLOW_MULTIPLICATION";

NSString * const SA_DB_RESULT											=	@"SA_DB_RESULT";

NSString * const SA_DB_ROLLS											=	@"SA_DB_ROLLS";

/******************************************************/
#pragma mark String constants for expression formatting
/******************************************************/

NSString * const SA_DB_LABEL											=	@"SA_DB_LABEL";

/***************************************************************/
#pragma mark String constants for retrieving string format rules
/***************************************************************/

NSString * const SA_DB_STRING_FORMAT_RULES_PLIST_NAME					=	@"SA_DB_StringFormatRules";

NSString * const SA_DB_VALID_CHARACTERS									=	@"SA_DB_VALID_CHARACTERS";
NSString * const SA_DB_VALID_NUMERAL_CHARACTERS							=	@"SA_DB_VALID_NUMERAL_CHARACTERS";
NSString * const SA_DB_VALID_OPERATOR_CHARACTERS						=	@"SA_DB_VALID_OPERATOR_CHARACTERS";
NSString * const SA_DB_VALID_ROLL_COMMAND_DELIMITER_CHARACTERS			=	@"SA_DB_VALID_ROLL_COMMAND_DELIMITER_CHARACTERS";

NSString * const SA_DB_CANONICAL_REPRESENTATIONS						=	@"SA_DB_CANONICAL_REPRESENTATIONS";
NSString * const SA_DB_CANONICAL_OPERATOR_REPRESENTATIONS				=	@"SA_DB_CANONICAL_OPERATOR_REPRESENTATIONS";
NSString * const SA_DB_CANONICAL_ROLL_COMMAND_DELIMITER_REPRESENTATION	=	@"SA_DB_CANONICAL_ROLL_COMMAND_DELIMITER_REPRESENTATION";
