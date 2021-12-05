//
//  SA_DiceParser.m
//
//  Copyright 2016-2021 Said Achmiz.
//  See LICENSE and README.md for more info.

#import "SA_DiceParser.h"

#import "SA_DiceExpressionStringConstants.h"
#import "SA_DiceFormatter.h"

#import "SA_Utility.h"

/********************************/
#pragma mark File-scope variables
/********************************/

static SA_DiceParserBehavior _defaultParserBehavior = SA_DiceParserBehaviorLegacy;
static NSDictionary *_validCharactersDict;

/************************************************/
#pragma mark - SA_DiceParser class implementation
/************************************************/

@implementation SA_DiceParser {
	SA_DiceParserBehavior _parserBehavior;
}

/************************/
#pragma mark - Properties
/************************/

-(void) setParserBehavior:(SA_DiceParserBehavior)newParserBehavior {
	_parserBehavior = newParserBehavior;
	
	switch (_parserBehavior) {
		case SA_DiceParserBehaviorLegacy:
		case SA_DiceParserBehaviorModern:
		case SA_DiceParserBehaviorFeepbot:
			break;
			
		case SA_DiceParserBehaviorDefault:
		default:
			_parserBehavior = SA_DiceParser.defaultParserBehavior;
			break;
	}
}

-(SA_DiceParserBehavior) parserBehavior {
	return _parserBehavior;
}

/******************************/
#pragma mark - Class properties
/******************************/

+(void) setDefaultParserBehavior:(SA_DiceParserBehavior)newDefaultParserBehavior {
	if (newDefaultParserBehavior == SA_DiceParserBehaviorDefault) {
		_defaultParserBehavior = SA_DiceParserBehaviorLegacy;
	} else {
		_defaultParserBehavior = newDefaultParserBehavior;
	}
}

+(SA_DiceParserBehavior) defaultParserBehavior {
	return _defaultParserBehavior;
}

// TODO: Should this be on a per-mode, and therefore per-instance, basis?
+(NSDictionary *) validCharactersDict {
	if (_validCharactersDict == nil) {
		[SA_DiceParser loadValidCharactersDict];
	}
	
	return _validCharactersDict;
}

/********************************************/
#pragma mark - Initializers & factory methods
/********************************************/

-(instancetype) init {
	return [self initWithBehavior:SA_DiceParserBehaviorDefault];
}

-(instancetype) initWithBehavior:(SA_DiceParserBehavior)parserBehavior {
	if (!(self = [super init]))
		return nil;

	self.parserBehavior = parserBehavior;

	if (_validCharactersDict == nil) {
		[SA_DiceParser loadValidCharactersDict];
	}

	return self;
}

+(instancetype) defaultParser {
	return [[SA_DiceParser alloc] initWithBehavior:SA_DiceParserBehaviorDefault];
}

+(instancetype) parserWithBehavior:(SA_DiceParserBehavior)parserBehavior {
	return [[SA_DiceParser alloc] initWithBehavior:parserBehavior];
}

/****************************/
#pragma mark - Public methods
/****************************/

-(SA_DiceExpression *) expressionForString:(NSString *)dieRollString {
	if (_parserBehavior == SA_DiceParserBehaviorLegacy) {
		return [self legacyExpressionForString:dieRollString];
	} else {
		return nil;
	}
}

/**********************************************/
#pragma mark - “Legacy” behavior implementation
/**********************************************/

-(SA_DiceExpression *) legacyExpressionForString:(NSString *)dieRollString {
	// Check for forbidden characters.
	if ([dieRollString containsCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:[SA_DiceParser allValidCharacters]] invertedSet]]) {
		SA_DiceExpression *errorExpression = [SA_DiceExpression new];
		errorExpression.type = SA_DiceExpressionTerm_NONE;
		errorExpression.inputString = dieRollString;
		errorExpression.errorBitMask |= SA_DiceExpressionError_ROLL_STRING_HAS_ILLEGAL_CHARACTERS;
		return errorExpression;
	}
	
	// Since we have checked the entire string for forbidden characters, we can
	// now begin parsing the string; there is no need to check substrings for
	// illegal characters (which is why we do it only once, in this wrapper
	// method). When constructing the expression tree, we call 
	// legacyExpressionForLegalString:, not legacyExpressionForString:, when 
	// recursively parsing substrings.
	return [self legacyExpressionForLegalString:dieRollString];
}

-(SA_DiceExpression *) legacyExpressionForLegalString:(NSString *)dieRollString {
	// Make sure string is not empty.
	if (dieRollString.length == 0) {
		SA_DiceExpression *errorExpression = [SA_DiceExpression new];
		errorExpression.type = SA_DiceExpressionTerm_NONE;
		errorExpression.inputString = dieRollString;
		errorExpression.errorBitMask |= SA_DiceExpressionError_ROLL_STRING_EMPTY;
		return errorExpression;
	}
	
	// We now know the string describes one of the allowable expression types
	// (probably; it could be malformed in some way other than being empty or
	// containing forbidden characters, such as e.g. by starting with a + sign).

	// Check to see if the top-level term is an operation. Note that we parse
	// operator expressions left-associatively.
	NSRange lastOperatorRange = [dieRollString rangeOfCharacterFromSet:[NSCharacterSet
																		characterSetWithCharactersInString:[SA_DiceParser
																											allValidOperatorCharacters]]
															   options:NSBackwardsSearch];
	if (lastOperatorRange.location != NSNotFound) {
		NSString *operator = [dieRollString substringWithRange:lastOperatorRange];
		
		if (lastOperatorRange.location != 0) {
			return [self legacyExpressionForStringDescribingOperation:dieRollString
												   withOperatorString:operator
															  atRange:lastOperatorRange];
		} else {
			// If the last (and thus only) operator is the leading character of
			// the expression, then this is one of several possible special cases.
			// First, we check for whether there even is anything more to the
			// roll string besides the operator. If not, then the string is
			// malformed by definition...
			// If the last operator is the leading character (i.e. there’s just
			// one operator in the expression, and it’s at the beginning), and
			// there’s more to the expression than just the operator, then
			// this is either an expression whose first term (which may or may
			// not be its only term) is a simple value expression which
			// represents a negative number - or, it’s a malformed expression
			// (because operators other than negation cannot begin an
			// expression).
			// In the former case, we do nothing, letting the testing for
			// expression type fall through to the remaining cases (roll command
			// or simple value).
			// In the latter case, we register an error and return.
			if (   dieRollString.length == lastOperatorRange.length
				|| ([[SA_DiceParser validCharactersForOperator:SA_DiceExpressionOperator_MINUS] containsCharactersInString:operator] == NO)) {
				SA_DiceExpression *expression = [SA_DiceExpression new];
				expression.type = SA_DiceExpressionTerm_OPERATION;
				expression.inputString = dieRollString;
				expression.errorBitMask |= SA_DiceExpressionError_INVALID_EXPRESSION;
				return expression;
			}

			// We’ve determined that this expression begins with a simple
			// value expression that represents a negative number.
			// This next line is a hack to account for the fact that Cocoa’s
			// Unicode compliance is incomplete. :( NSString’s integerValue
			// method only accepts the hyphen as a negation sign when reading a
			// number - not any of the Unicode characters which officially
			// symbolize negation! But we are more modern-minded, and accept
			// arbitrary symbols as minus-sign. For proper parsing, though,
			// we have to replace it like this...
			dieRollString = [dieRollString stringByReplacingCharactersInRange:lastOperatorRange
																   withString:@"-"];

			// Now we fall through to “is it a roll command, or maybe a simple
			// value?”...
		}
	}
	
	// If not an operation, the top-level term might be a die roll command
	// or a die roll modifier.
	// Look for one of the characters recognized as valid die roll or die roll
	// modifier delimiters.
	// Note that we parse roll commands left-associatively, therefore e.g. 
	// 5d6d10 parses as “roll N d10s, where N is the result of rolling 5d6”.
	NSMutableCharacterSet *validDelimiterCharacters = [NSMutableCharacterSet characterSetWithCharactersInString:[SA_DiceParser allValidRollCommandDelimiterCharacters]];
	[validDelimiterCharacters addCharactersInString:[SA_DiceParser allValidRollModifierDelimiterCharacters]];
	NSRange lastDelimiterRange = [dieRollString rangeOfCharacterFromSet:validDelimiterCharacters
																options:NSBackwardsSearch];
	if (lastDelimiterRange.location != NSNotFound) {
		if ([[SA_DiceParser allValidRollCommandDelimiterCharacters] containsString:[dieRollString substringWithRange:lastDelimiterRange]])
			return [self legacyExpressionForStringDescribingRollCommand:dieRollString
												   withDelimiterAtRange:lastDelimiterRange];
		else if ([[SA_DiceParser allValidRollModifierDelimiterCharacters] containsString:[dieRollString substringWithRange:lastDelimiterRange]])
			return [self legacyExpressionForStringDescribingRollModifier:dieRollString
													withDelimiterAtRange:lastDelimiterRange];
		else
			// This should be impossible.
			NSLog(@"IMPOSSIBLE CONDITION ENCOUNTERED WHILE PARSING DIE ROLL STRING!");
	}
	
	// If not an operation nor a roll command, the top-level term can only be
	// a simple numeric value.
	return [self legacyExpressionForStringDescribingNumericValue:dieRollString];
}

-(SA_DiceExpression *) legacyExpressionForStringDescribingOperation:(NSString *)dieRollString
												 withOperatorString:(NSString *)operatorString
															atRange:(NSRange)operatorRange {
	SA_DiceExpression *expression = [SA_DiceExpression new];

	expression.type = SA_DiceExpressionTerm_OPERATION;
	expression.inputString = dieRollString;

	// Operands of a binary operator are the expressions generated by 
	// parsing the strings before and after the addition operator.
	expression.leftOperand = [self legacyExpressionForLegalString:[dieRollString substringToIndex:operatorRange.location]];
	expression.rightOperand = [self legacyExpressionForLegalString:[dieRollString substringFromIndex:(operatorRange.location + operatorRange.length)]];
	
	if ([[SA_DiceParser validCharactersForOperator:SA_DiceExpressionOperator_PLUS] containsCharactersInString:operatorString]) {
		// Check to see if the term is an addition operation.
		expression.operator = SA_DiceExpressionOperator_PLUS;
	} else if ([[SA_DiceParser validCharactersForOperator:SA_DiceExpressionOperator_MINUS] containsCharactersInString:operatorString]) {
		// Check to see if the term is a subtraction operation.
		expression.operator = SA_DiceExpressionOperator_MINUS;
	} else if ([[SA_DiceParser validCharactersForOperator:SA_DiceExpressionOperator_TIMES] containsCharactersInString:operatorString]) {
		// Check to see if the term is a multiplication operation.
		// Look for other, lower-precedence operators to the left of the
		// multiplication operator. If found, split the string there 
		// instead of at the current operator.
		NSString *allLowerPrecedenceOperators = [@[ [SA_DiceParser validCharactersForOperator:SA_DiceExpressionOperator_PLUS],
													[SA_DiceParser validCharactersForOperator:SA_DiceExpressionOperator_MINUS] ]
												 componentsJoinedByString:@""];
		NSRange lastLowerPrecedenceOperatorRange = [dieRollString rangeOfCharacterFromSet:[NSCharacterSet
																						   characterSetWithCharactersInString:allLowerPrecedenceOperators]
																				  options:NSBackwardsSearch
																					range:NSRangeMake(1, operatorRange.location - 1)];
		if (lastLowerPrecedenceOperatorRange.location != NSNotFound) {
			return [self legacyExpressionForStringDescribingOperation:dieRollString
												   withOperatorString:[dieRollString substringWithRange:lastLowerPrecedenceOperatorRange]
															  atRange:lastLowerPrecedenceOperatorRange];
		}
		
		expression.operator = SA_DiceExpressionOperator_TIMES;
	} else {
		expression.errorBitMask |= SA_DiceExpressionError_UNKNOWN_OPERATOR;
	}

	// The operands have now been parsed recursively; this parsing may have 
	// generated one or more errors. Inherit any error(s) from the 
	// error-generating operand(s).
	expression.errorBitMask |= expression.leftOperand.errorBitMask;
	expression.errorBitMask |= expression.rightOperand.errorBitMask;

	return expression;
}

-(SA_DiceExpression *) legacyExpressionForStringDescribingRollCommand:(NSString *)dieRollString
												 withDelimiterAtRange:(NSRange)delimiterRange {
	SA_DiceExpression *expression = [SA_DiceExpression new];

	expression.type = SA_DiceExpressionTerm_ROLL_COMMAND;
	expression.inputString = dieRollString;

	// For now, only two kinds of roll command is supported - roll-and-sum,
	// and roll-and-sum with exploding dice.
	// These roll one or more dice of a given sort, and determine the sum of
	// their rolled values. (In the “exploding dice” version, each die can
	// explode, of course.)
	if ([[SA_DiceParser validCharactersForRollCommandDelimiter:SA_DiceExpressionRollCommand_SUM]
		 containsString:[dieRollString substringWithRange:delimiterRange]])
		expression.rollCommand = SA_DiceExpressionRollCommand_SUM;
	else if ([[SA_DiceParser validCharactersForRollCommandDelimiter:SA_DiceExpressionRollCommand_SUM_EXPLODING]
			  containsString:[dieRollString substringWithRange:delimiterRange]])
		expression.rollCommand = SA_DiceExpressionRollCommand_SUM_EXPLODING;

	// Check to see if the delimiter is the initial character of the roll 
	// string. If so (i.e. if the die count is omitted), we assume it to be 1
	// (i.e. ‘d6’ is read as ‘1d6’).
	// Otherwise, the die count is the expression generated by parsing the
	// string before the delimiter.
	expression.dieCount = ((delimiterRange.location == 0) ?
						   [self legacyExpressionForStringDescribingNumericValue:@"1"] :
						   [self legacyExpressionForLegalString:[dieRollString substringToIndex:delimiterRange.location]]);

	// The die size is the expression generated by parsing the string after the 
	// delimiter.
	expression.dieSize = [self legacyExpressionForLegalString:[dieRollString substringFromIndex:(delimiterRange.location + delimiterRange.length)]];
	if ([expression.dieSize.inputString.lowercaseString isEqualToString:@"f"])
		expression.dieType = SA_DiceExpressionDice_FUDGE;

	// The die count and die size have now been parsed recursively; this parsing
	// may have generated one or more errors. Inherit any error(s) from the 
	// error-generating sub-terms.
	expression.errorBitMask |= expression.dieCount.errorBitMask;
	expression.errorBitMask |= expression.dieSize.errorBitMask;

	return expression;
}

-(SA_DiceExpression *) legacyExpressionForStringDescribingRollModifier:(NSString *)dieRollString
												  withDelimiterAtRange:(NSRange)delimiterRange {
	SA_DiceExpression *expression = [SA_DiceExpression new];

	expression.type = SA_DiceExpressionTerm_ROLL_MODIFIER;
	expression.inputString = dieRollString;

	// The possible roll modifiers are KEEP HIGHEST and KEEP LOWEST.
	// These take a roll command and a number, and keep that number of rolls
	// generated by the roll command (either the highest or lowest rolls,
	// respectively).
	if ([[SA_DiceParser validCharactersForRollModifierDelimiter:SA_DiceExpressionRollModifier_KEEP_HIGHEST]
		 containsString:[dieRollString substringWithRange:delimiterRange]])
		expression.rollModifier = SA_DiceExpressionRollModifier_KEEP_HIGHEST;
	else if ([[SA_DiceParser validCharactersForRollModifierDelimiter:SA_DiceExpressionRollModifier_KEEP_LOWEST]
			  containsString:[dieRollString substringWithRange:delimiterRange]])
		expression.rollModifier = SA_DiceExpressionRollModifier_KEEP_LOWEST;

	// Check to see if the delimiter is the initial character of the roll
	// string. If so, set an error, because a roll modifier requires a
	// roll command to modify.
	if (delimiterRange.location == 0) {
		expression.errorBitMask |= SA_DiceExpressionError_ROLL_STRING_EMPTY;
		return expression;
	}

	// Otherwise, the left operand is the expression generated by parsing the
	// string before the delimiter.
	expression.leftOperand = [self legacyExpressionForLegalString:[dieRollString substringToIndex:delimiterRange.location]];

	// The right operand is the expression generated by parsing the string after
	// the delimiter.
	expression.rightOperand = [self legacyExpressionForLegalString:[dieRollString substringFromIndex:(delimiterRange.location + delimiterRange.length)]];

	// The left and right operands have now been parsed recursively; this
	// parsing may have generated one or more errors. Inherit any error(s) from
	// the error-generating sub-terms.
	expression.errorBitMask |= expression.leftOperand.errorBitMask;
	expression.errorBitMask |= expression.rightOperand.errorBitMask;

	return expression;
}

-(SA_DiceExpression *) legacyExpressionForStringDescribingNumericValue:(NSString *)dieRollString {
	SA_DiceExpression *expression = [SA_DiceExpression new];

	expression.type = SA_DiceExpressionTerm_VALUE;
	expression.inputString = dieRollString;
	if ([expression.inputString.lowercaseString isEqualToString:@"f"])
		expression.value = @(-1);
	else
		expression.value = @(dieRollString.integerValue);

	return expression;
}

/****************************/
#pragma mark - Helper methods
/****************************/

+(void) loadValidCharactersDict {
	NSString *stringFormatRulesPath = [[NSBundle bundleForClass:[self class]] pathForResource:SA_DB_STRING_FORMAT_RULES_PLIST_NAME
																					   ofType:@"plist"];
	_validCharactersDict = [NSDictionary dictionaryWithContentsOfFile:stringFormatRulesPath][SA_DB_VALID_CHARACTERS];
	if (!_validCharactersDict) {
		NSLog(@"Could not load valid characters dictionary!");
	}
}

// TODO: Should this be on a per-mode, and therefore per-instance, basis?
+(NSString *) allValidCharacters {
	return [ @[ [SA_DiceParser validNumeralCharacters], 
				[SA_DiceParser allValidRollCommandDelimiterCharacters],
				[SA_DiceParser allValidRollModifierDelimiterCharacters],
				[SA_DiceParser allValidOperatorCharacters] ] componentsJoinedByString:@""];
}

+(NSString *) allValidOperatorCharacters {
	NSDictionary *validOperatorCharactersDict = [SA_DiceParser validCharactersDict][SA_DB_VALID_OPERATOR_CHARACTERS];
	
	return [validOperatorCharactersDict.allValues componentsJoinedByString:@""];
}

+(NSString *) validCharactersForOperator:(SA_DiceExpressionOperator)operator {
	return [SA_DiceParser validCharactersDict][SA_DB_VALID_OPERATOR_CHARACTERS][NSStringFromSA_DiceExpressionOperator(operator)];
}

+(NSString *) validNumeralCharacters {
	return [SA_DiceParser validCharactersDict][SA_DB_VALID_NUMERAL_CHARACTERS];
}

+(NSString *) validCharactersForRollCommandDelimiter:(SA_DiceExpressionRollCommand)command {
	return [SA_DiceParser validCharactersDict][SA_DB_VALID_ROLL_COMMAND_DELIMITER_CHARACTERS][NSStringFromSA_DiceExpressionRollCommand(command)];
}

+(NSString *) allValidRollCommandDelimiterCharacters {
	NSDictionary *validRollCommandDelimiterCharactersDict = [SA_DiceParser validCharactersDict][SA_DB_VALID_ROLL_COMMAND_DELIMITER_CHARACTERS];

	return [validRollCommandDelimiterCharactersDict.allValues componentsJoinedByString:@""];
}

+(NSString *) validCharactersForRollModifierDelimiter:(SA_DiceExpressionRollModifier)modifier {
	return [SA_DiceParser validCharactersDict][SA_DB_VALID_ROLL_MODIFIER_DELIMITER_CHARACTERS][NSStringFromSA_DiceExpressionRollModifier(modifier)];
}

+(NSString *) allValidRollModifierDelimiterCharacters {
	NSDictionary *validRollModifierDelimiterCharactersDict = [SA_DiceParser validCharactersDict][SA_DB_VALID_ROLL_MODIFIER_DELIMITER_CHARACTERS];

	return [validRollModifierDelimiterCharactersDict.allValues componentsJoinedByString:@""];
}

@end
