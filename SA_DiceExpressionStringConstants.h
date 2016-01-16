//
//  SA_DiceExpressionStringConstants.h
//  RPGBot
//
//  Created by Sandy Achmiz on 1/2/16.
//
//

#import <Foundation/Foundation.h>

/***************************************************/
#pragma mark String constants for expression parsing
/***************************************************/

// Each term in an expression (i.e. each node in the expression tree) has a 
// value for the SA_DB_TERM_TYPE key, which may be one of the term types listed 
// below. SA_DB_TERM_TYPE_NONE is used for terms that fail to be parsed at all,
// because their input strings contain illegal characters or are empty.
extern NSString * const SA_DB_TERM_TYPE;										// key
extern NSString * const SA_DB_TERM_TYPE_VALUE;									// value
extern NSString * const SA_DB_TERM_TYPE_ROLL_COMMAND;							// value
extern NSString * const SA_DB_TERM_TYPE_OPERATION;								// value
extern NSString * const SA_DB_TERM_TYPE_NONE;									// value

// Terms that are erroneous (malformed or illegal in some way) have a value for 
// the SA_DB_ERRORS key. Whether they have values for any other keys is 
// undefined. The value for this key is an NSArray of NSString objects, each 
// having one of the listed values.
extern NSString * const SA_DB_ERRORS;											// key
extern NSString * const SA_DB_ERROR_ROLL_STRING_EMPTY;							// value
extern NSString * const SA_DB_ERROR_ROLL_STRING_HAS_ILLEGAL_CHARACTERS;			// value

// Terms of type SA_DB_TERM_TYPE_OPERATION (a.k.a. operation expressions) have a 
// value for the SA_DB_OPERATOR key, which may be any of the allowed operators 
// listed below.
// Operation expressions also have a value for the SA_DB_OPERAND_RIGHT key,
// and, possibly, a value for the SA_DB_OPERAND_LEFT key as well.
// (An operation expression with an SA_DB_OPERATOR value of SA_DB_OPERATOR_MINUS 
//  that does not have an SA_DB_OPERAND_LEFT value is simply a negation of the 
//  SA_DB_OPERAND_RIGHT value.)
// The values for the SA_DB_OPERAND_RIGHT (and, if present, SA_DB_OPERAND_LEFT)
// are themselves expressions of some type (i.e. NSDictionary objects), which
// must be recursively evaluated.
extern NSString * const SA_DB_OPERATOR;											// key
extern NSString * const SA_DB_OPERATOR_MINUS;									// value
extern NSString * const SA_DB_OPERATOR_PLUS;									// value
extern NSString * const SA_DB_OPERATOR_TIMES;									// value
extern NSString * const SA_DB_OPERAND_LEFT;										// key
extern NSString * const SA_DB_OPERAND_RIGHT;									// key

// Terms of type SA_DB_TERM_TYPE_ROLL_COMMAND (a.k.a. roll command expressions)
// have a value for the SA_DB_ROLL_COMMAND key, which may be any of the roll 
// commands listed below.
// Roll command expressions also have values for the keys SA_DB_ROLL_DIE_COUNT
// and SA_DB_ROLL_DIE_SIZE, which are themselves expressions of some type
// (i.e. NSDictionary objects), which must be recursively evaluated.
extern NSString * const SA_DB_ROLL_COMMAND;										// key
extern NSString * const SA_DB_ROLL_COMMAND_SUM;									// value
extern NSString * const SA_DB_ROLL_DIE_COUNT;									// key
extern NSString * const SA_DB_ROLL_DIE_SIZE;									// key

// Terms of type SA_DB_TERM_TYPE_VALUE (a.k.a. simple value expressions) have a 
// value for the SA_DB_VALUE key, which is an NSNumber that represents an 
// NSInteger value.
// NOTE: Despite being an NSInteger, this numeric value may not be negative.
extern NSString * const SA_DB_VALUE;											// key

// All terms that were generated via parsing a string should have a value for 
// the SA_DB_INPUT_STRING key. This is in order to be able to reconstruct the
// input, for useful output later (i.e., it's used by the results formatter).
// The value is, of course, an NSString.
// Optionally, there may also be a value for the SA_DB_ATTRIBUTED_INPUT_STRING
// key. The current implementation does not set a value for this key, nor is it
// used in any way, but it may be used in future versions or in alternate
// implementations.
extern NSString * const SA_DB_INPUT_STRING;										// key
extern NSString * const SA_DB_ATTRIBUTED_INPUT_STRING;							// key

/******************************************************/
#pragma mark String constants for expression evaluation
/******************************************************/

// Additional values for key SA_DB_ERROR
extern NSString * const SA_DB_ERROR_UNKNOWN_ROLL_COMMAND;						// value
extern NSString * const SA_DB_ERROR_DIE_COUNT_NEGATIVE;							// value
extern NSString * const SA_DB_ERROR_DIE_COUNT_EXCESSIVE;						// value
extern NSString * const SA_DB_ERROR_DIE_SIZE_INVALID;							// value
extern NSString * const SA_DB_ERROR_DIE_SIZE_EXCESSIVE;							// value
extern NSString * const SA_DB_ERROR_UNKNOWN_OPERATOR;							// value
extern NSString * const SA_DB_ERROR_INVALID_EXPRESSION;							// value
extern NSString * const SA_DB_ERROR_INTEGER_OVERFLOW_NEGATION;					// value
extern NSString * const SA_DB_ERROR_INTEGER_OVERFLOW_ADDITION;					// value
extern NSString * const SA_DB_ERROR_INTEGER_UNDERFLOW_ADDITION;					// value
extern NSString * const SA_DB_ERROR_INTEGER_OVERFLOW_SUBTRACTION;				// value
extern NSString * const SA_DB_ERROR_INTEGER_UNDERFLOW_SUBTRACTION;				// value
extern NSString * const SA_DB_ERROR_INTEGER_OVERFLOW_MULTIPLICATION;			// value
extern NSString * const SA_DB_ERROR_INTEGER_UNDERFLOW_MULTIPLICATION;			// value

// Successfully evaluated terms (i.e., those that have no errors) have a value 
// for the SA_DB_RESULT key. This value is an NSNumber that represents an 
// NSInteger value.
extern NSString * const SA_DB_RESULT;											// key

// Successfully evaluated roll command terms (i.e. those that have no errors)
// have a value for the SA_DB_ROLLS key. This is an NSArray containing all of 
// the individual die rolls that were generated by executing the roll command.
extern NSString * const SA_DB_ROLLS;											// key

/***************************************************************/
#pragma mark String constants for retrieving string format rules
/***************************************************************/

extern NSString * const SA_DB_STRING_FORMAT_RULES_PLIST_NAME;

/*
 The string format rules file (whose filename - minus the .plist extension - 
 is given by the SA_DB_STRING_FORMAT_RULES_PLIST_NAME string) contains 
 values for variables that define the properties of legal die roll strings,
 as well as certain variables that define the format of result strings.
 
 The file is organized as a dictionary contaning several sub-dictionaries. The
 valid keys (those for which values are present in the file), and the values
 that those keys may be expected to have, are listed below.
 */

// The value for the top-level key SA_DB_VALID_CHARACTERS is a dictionary that 
// defines those characters that are recognized as valid representations of 
// various components of a die roll string. This dictionary has values for the
// keys listed below whose names begin with SA_DB_VALID_.
extern NSString * const SA_DB_VALID_CHARACTERS;

// The value for the key SA_DB_VALID_NUMERAL_CHARACTERS is a string that 
// contains all characters that are recognized as representing decimal numerals.
// (Usually, this will be the 10 characters representing the standard Arabic
// numerals.)
extern NSString * const SA_DB_VALID_NUMERAL_CHARACTERS;

// The value for the key SA_DB_VALID_OPERATOR_CHARACTERS is a dictionary that
// defines those characters that are recognized as valid representations of
// the supported mathematical operators. This dictionary has values for keys
// corresponding to the names of each of the supported operators (see 
// the "String constants for expression parsing" section, above).
extern NSString * const SA_DB_VALID_OPERATOR_CHARACTERS;

// The value for the key SA_DB_VALID_ROLL_COMMAND_DELIMITER_CHARACTERS is a 
// string that contains all the characters that are recognized as representing
// die roll command delimiters. (Usually this is the lowercase and uppercase
// versions of the letter 'd', as in '1d20' or '4D6'.)
extern NSString * const SA_DB_VALID_ROLL_COMMAND_DELIMITER_CHARACTERS;

// The value for the top-level key SA_DB_CANONICAL_REPRESENTATIONS is a 
// dictionary that defines canonical representations of certain components
// of a formatted die roll string. This dictionary has values for the keys 
// listed below whose names begin with SA_DB_CANONICAL_.
extern NSString * const SA_DB_CANONICAL_REPRESENTATIONS;

// The value for the key SA_DB_CANONICAL_OPERATOR_REPRESENTATIONS is a 
// dictionary that defines canonical representations of each of the 
// supported mathematical operators (for use when formatting results for 
// output). This dictionary has values for keys corresponding to the names of 
// each of the supported operators (see the "String constants for expression
// parsing" section, above).
extern NSString * const SA_DB_CANONICAL_OPERATOR_REPRESENTATIONS;

// The value for the key SA_DB_CANONICAL_ROLL_COMMAND_DELIMITER_REPRESENTATION
// is the canonical representation of the die roll command delimiter.
extern NSString * const SA_DB_CANONICAL_ROLL_COMMAND_DELIMITER_REPRESENTATION;