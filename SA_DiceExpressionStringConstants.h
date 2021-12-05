//
//  SA_DiceExpressionStringConstants.h
//
//  Copyright 2016-2021 Said Achmiz.
//  See LICENSE and README.md for more info.

#import <Foundation/Foundation.h>

/***************************************************************/
#pragma mark String constants for retrieving string format rules
/***************************************************************/

extern NSString * const SA_DB_STRING_FORMAT_RULES_PLIST_NAME;

/*
 The string format rules file (whose basename (i.e., filename minus the .plist
 extension) is given by the SA_DB_STRING_FORMAT_RULES_PLIST_NAME string) 
 contains values for variables that define the properties of legal die roll 
 strings, as well as certain variables that define the format of result strings.
 
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
// corresponding to the names of each of the supported operators.
extern NSString * const SA_DB_VALID_OPERATOR_CHARACTERS;

// The value for the key SA_DB_VALID_ROLL_COMMAND_DELIMITER_CHARACTERS is a
// dictionary that defines those characters that are recognized as valid
// representations of delimiters for each of the allowed roll commands. This
// dictionary has values for keys corresponding to the names of each of the
// supported roll modifiers.
extern NSString * const SA_DB_VALID_ROLL_COMMAND_DELIMITER_CHARACTERS;

// The value for the key SA_DB_VALID_ROLL_MODIFIER_DELIMITER_CHARACTERS is a
// dictionary that defines those characters that are recognized as valid
// representations of delimiters for each of the allowed roll modifiers. This
// dictionary has values for keys corresponding to the names of each of the
// supported roll modifiers.
extern NSString * const SA_DB_VALID_ROLL_MODIFIER_DELIMITER_CHARACTERS;

// The value for the top-level key SA_DB_CANONICAL_REPRESENTATIONS is a
// dictionary that defines canonical representations of certain components
// of a formatted die roll string. This dictionary has values for the keys 
// listed below whose names begin with SA_DB_CANONICAL_.
extern NSString * const SA_DB_CANONICAL_REPRESENTATIONS;

// The value for the key SA_DB_CANONICAL_OPERATOR_REPRESENTATIONS is a 
// dictionary that defines canonical representations of each of the 
// supported mathematical operators (for use when formatting results for 
// output). This dictionary has values for keys corresponding to the names of 
// each of the supported operators.
extern NSString * const SA_DB_CANONICAL_OPERATOR_REPRESENTATIONS;

// The value for the key SA_DB_CANONICAL_ROLL_COMMAND_DELIMITER_REPRESENTATIONS
// is a dictionary that defines canonical representations of each of the
// supported roll commands (for use when formatting results for
// output). This dictionary has values for keys corresponding to the names of
// each of the supported roll commands.
extern NSString * const SA_DB_CANONICAL_ROLL_COMMAND_DELIMITER_REPRESENTATIONS;

// The value for the key SA_DB_CANONICAL_ROLL_MODIFIER_REPRESENTATIONS is a
// dictionary that defines canonical representations of each of the
// supported roll modifiers (for use when formatting results for
// output). This dictionary has values for keys corresponding to the names of
// each of the supported roll modifiers.
extern NSString * const SA_DB_CANONICAL_ROLL_MODIFIER_DELIMITER_REPRESENTATIONS;
