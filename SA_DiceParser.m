//
//  SA_DiceParser.m
//  RPGBot
//
//  Created by Sandy Achmiz on 12/30/15.
//
//

#import "SA_DiceParser.h"

#import "SA_DiceExpressionStringConstants.h"
#import "SA_DiceErrorHandling.h"
#import "NSString+SA_NSStringExtensions.h"

/********************************/
#pragma mark File-scope variables
/********************************/

static SA_DiceParserBehavior _defaultParserBehavior = SA_DiceParserBehaviorLegacy;
static NSDictionary *_validCharactersDict;

/************************************************/
#pragma mark - SA_DiceParser class implementation
/************************************************/

@implementation SA_DiceParser
{
	SA_DiceParserBehavior _parserBehavior;
}

/************************/
#pragma mark - Properties
/************************/

- (void)setParserBehavior:(SA_DiceParserBehavior)newParserBehavior
{
	_parserBehavior = newParserBehavior;
	
	switch (_parserBehavior)
	{
		case SA_DiceParserBehaviorLegacy:
		case SA_DiceParserBehaviorModern:
		case SA_DiceParserBehaviorFeepbot:
			break;
			
		case SA_DiceParserBehaviorDefault:
		default:
			_parserBehavior = [SA_DiceParser defaultParserBehavior];
			break;
	}
}

- (SA_DiceParserBehavior)parserBehavior
{
	return _parserBehavior;
}

/****************************************/
#pragma mark - "Class property" accessors
/****************************************/

+ (void)setDefaultParserBehavior:(SA_DiceParserBehavior)newDefaultParserBehavior
{
	if(newDefaultParserBehavior == SA_DiceParserBehaviorDefault)
	{
		_defaultParserBehavior = SA_DiceParserBehaviorLegacy;
	}
	else
	{
		_defaultParserBehavior = newDefaultParserBehavior;
	}
}

+ (SA_DiceParserBehavior)defaultParserBehavior
{
	return _defaultParserBehavior;
}

+ (NSDictionary *)validCharactersDict
{
	if(_validCharactersDict == nil)
	{
		[SA_DiceParser loadValidCharactersDict];
	}
	
	return _validCharactersDict;
}

/********************************************/
#pragma mark - Initializers & factory methods
/********************************************/

- (instancetype)init
{
	return [self initWithBehavior:SA_DiceParserBehaviorDefault];
}

- (instancetype)initWithBehavior:(SA_DiceParserBehavior)parserBehavior
{
	if(self = [super init])
	{
		self.parserBehavior = parserBehavior;
		
		if(_validCharactersDict == nil)
		{
			[SA_DiceParser loadValidCharactersDict];
		}
	}
	return self;
}

+ (instancetype)defaultParser
{
	return [[SA_DiceParser alloc] initWithBehavior:SA_DiceParserBehaviorDefault];
}

+ (instancetype)parserWithBehavior:(SA_DiceParserBehavior)parserBehavior
{
	return [[SA_DiceParser alloc] initWithBehavior:parserBehavior];
}

/****************************/
#pragma mark - Public methods
/****************************/

- (NSDictionary *)expressionForString:(NSString *)dieRollString
{
	if(_parserBehavior == SA_DiceParserBehaviorLegacy)
	{
		return [self legacyExpressionForString:dieRollString];
	}
	else
	{
		return @{};
	}
}

/**********************************************/
#pragma mark - "Legacy" behavior implementation
/**********************************************/

- (NSDictionary *)legacyExpressionForString:(NSString *)dieRollString
{
	// Check for forbidden characters.
	NSCharacterSet *forbiddenCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:[SA_DiceParser allValidCharacters]] invertedSet];
	if([dieRollString containsCharactersInSet:forbiddenCharacterSet])
	{
		return @{ SA_DB_TERM_TYPE		: SA_DB_TERM_TYPE_NONE,
				  SA_DB_INPUT_STRING	: dieRollString,
				  SA_DB_ERRORS			: @[SA_DB_ERROR_ROLL_STRING_HAS_ILLEGAL_CHARACTERS] };
	}
	
	// Since we have checked the entire string for forbidden characters, we can
	// now begin parsing the string; there is no need to check substrings for
	// illegal characters (which is why we do it only once, in this wrapper
	// method). When constructing the expression tree, we call 
	// legacyExpressionForLegalString:, not legacyExpressionForString:, when 
	// recursively parsing substrings.
	return [self legacyExpressionForLegalString:dieRollString];
}

- (NSDictionary *)legacyExpressionForLegalString:(NSString *)dieRollString
{
	// Make sure string is not empty.
	if(dieRollString.length == 0)
	{
		return @{ SA_DB_TERM_TYPE		: SA_DB_TERM_TYPE_NONE,
				  SA_DB_INPUT_STRING	: dieRollString,
				  SA_DB_ERRORS			: @[SA_DB_ERROR_ROLL_STRING_EMPTY] };
	}
	
	// We now know the string describes one of the allowable expression types
	// (probably; it could be malformed in some way other than being empty or
	// containing forbidden characters, such as e.g. by starting with a + sign).

	// Check to see if the top-level term is an operation. Note that we parse
	// operator expressions left-associatively.
	NSRange lastOperatorRange = [dieRollString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:[SA_DiceParser allValidOperatorCharacters]] options:NSBackwardsSearch];
	if(lastOperatorRange.location != NSNotFound)
	{
		NSString *operator = [dieRollString substringWithRange:lastOperatorRange];
		
		return [self legacyExpressionForStringDescribingOperation:dieRollString withOperator:operator atRange:lastOperatorRange];
	}
	
	// If not an operation, the top-level term might be a die roll command.
	// Look for one of the characters recognized as valid die roll delimiters. 
	// Note that we parse roll commands left-associatively, therefore e.g. 
	// 5d6d10 parses as "roll N d10s, where N is the result of rolling 5d6".
	NSRange lastRollCommandDelimiterRange = [dieRollString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:[SA_DiceParser validRollCommandDelimiterCharacters]] options:NSBackwardsSearch];
	if(lastRollCommandDelimiterRange.location != NSNotFound)
	{
		return [self legacyExpressionForStringDescribingRollCommand:dieRollString withDelimiterAtRange:lastRollCommandDelimiterRange];
	}
	
	// If not an operation nor a roll command, the top-level term can only be
	// a simple numeric value.
	return [self legacyExpressionForStringDescribingNumericValue:dieRollString];
}

- (NSDictionary *)legacyExpressionForStringDescribingOperation:(NSString *)dieRollString withOperator:(NSString *)operator atRange:(NSRange)operatorRange
{
	NSMutableDictionary *expression;
	
	// If the operator is at the beginning, this may be negation; we handle that
	// case later below. Otherwise, it's a binary operator.
	if(operatorRange.location != 0)
	{
		expression = [NSMutableDictionary dictionary];
		expression[SA_DB_TERM_TYPE] = SA_DB_TERM_TYPE_OPERATION;
		expression[SA_DB_INPUT_STRING] = dieRollString;
		
		// Operands of a binary operator are the expressions generated by 
		// parsing the strings before and after the addition operator.
		expression[SA_DB_OPERAND_LEFT] = [self legacyExpressionForLegalString:[dieRollString substringToIndex:operatorRange.location]];
		expression[SA_DB_OPERAND_RIGHT] = [self legacyExpressionForLegalString:[dieRollString substringFromIndex:(operatorRange.location + operatorRange.length)]];
		
		// Check to see if the term is a subtraction operation.
		if([[SA_DiceParser validCharactersForOperator:SA_DB_OPERATOR_MINUS] containsCharactersInString:operator])
		{
			expression[SA_DB_OPERATOR] = SA_DB_OPERATOR_MINUS;
		}
		// Check to see if the term is an addition operation.
		else if([[SA_DiceParser validCharactersForOperator:SA_DB_OPERATOR_PLUS] containsCharactersInString:operator])
		{
			expression[SA_DB_OPERATOR] = SA_DB_OPERATOR_PLUS;
		}
		// Check to see if the term is a multiplication operation.
		else if([[SA_DiceParser validCharactersForOperator:SA_DB_OPERATOR_TIMES] containsCharactersInString:operator])
		{
			// Look for other, lower-precedence operators to the left of the 
			// multiplication operator. If found, split the string there 
			// instead of at the current operator.
			NSString *allLowerPrecedenceOperators = [NSString stringWithFormat:@"%@%@", [SA_DiceParser validCharactersForOperator:SA_DB_OPERATOR_PLUS], [SA_DiceParser validCharactersForOperator:SA_DB_OPERATOR_MINUS]];
			NSRange lastLowerPrecedenceOperatorRange = [dieRollString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:allLowerPrecedenceOperators] options:NSBackwardsSearch range:NSMakeRange(1, operatorRange.location - 1)];
			if(lastLowerPrecedenceOperatorRange.location != NSNotFound)
			{
				NSString *lowerPrecedenceOperator = [dieRollString substringWithRange:lastLowerPrecedenceOperatorRange];
				return [self legacyExpressionForStringDescribingOperation:dieRollString withOperator:lowerPrecedenceOperator atRange:lastLowerPrecedenceOperatorRange];
			}
			
			expression[SA_DB_OPERATOR] = SA_DB_OPERATOR_TIMES;
		}
		else
		{
			addErrorToExpression(SA_DB_ERROR_UNKNOWN_OPERATOR, expression);
		}
	}
	// Check to see if the term is a negation operation (we can only reach this
	// case if the subtraction operator is at the beginning).
	else
	{
		if(dieRollString.length == operatorRange.length)
		{
			expression = [NSMutableDictionary dictionary];
			expression[SA_DB_TERM_TYPE] = SA_DB_TERM_TYPE_OPERATION;
			expression[SA_DB_INPUT_STRING] = dieRollString;
			
			addErrorToExpression(SA_DB_ERROR_INVALID_EXPRESSION, expression);
			
			return expression;
		}		
		if([[SA_DiceParser validCharactersForOperator:SA_DB_OPERATOR_MINUS] containsCharactersInString:operator])
		{
			// It turns out this isn't actually an operation expression. It's a
			// simple value expression with a negative number.
			
			// This next line is a hack to account for the fact that Cocoa's 
			// Unicode compliance is incomplete. :( NSString's integerValue
			// method only accepts the hyphen as a negation sign when reading a
			// number - not any of the Unicode characters which officially
			// symbolize negation! But we are more modern-minded, and accept 
			// arbitrary symbols as minus-sign. For proper parsing, though, 
			// we have to replace it like this...
			NSString *fixedRollString = [dieRollString stringByReplacingCharactersInRange:operatorRange withString:@"-"];
			
			return [self legacyExpressionForStringDescribingNumericValue:fixedRollString];			
		}
		else
		{
			expression = [NSMutableDictionary dictionary];
			expression[SA_DB_TERM_TYPE] = SA_DB_TERM_TYPE_OPERATION;
			expression[SA_DB_INPUT_STRING] = dieRollString;
			
			addErrorToExpression(SA_DB_ERROR_INVALID_EXPRESSION, expression);
			
			return expression;
		}
	}
	
	// The operands have now been parsed recursively; this parsing may have 
	// generated one or more errors. Inherit any error(s) from the 
	// error-generating operand(s).
	addErrorsFromExpressionToExpression(expression[SA_DB_OPERAND_RIGHT], expression);
	addErrorsFromExpressionToExpression(expression[SA_DB_OPERAND_LEFT], expression);
	
	return expression;
}

- (NSDictionary *)legacyExpressionForStringDescribingRollCommand:(NSString *)dieRollString withDelimiterAtRange:(NSRange)delimiterRange
{
	NSMutableDictionary *expression = [NSMutableDictionary dictionary];
	expression[SA_DB_TERM_TYPE] = SA_DB_TERM_TYPE_ROLL_COMMAND;
	expression[SA_DB_INPUT_STRING] = dieRollString;

	// For now, only one kind of roll command is supported - roll-and-sum.
	// This rolls one or more dice of a given sort, and determines the sum of
	// their rolled values.
	// In the future, support for other, more complex roll commands might be 
	// added, such as "roll several and return the highest", exploding dice, 
	// etc.
	expression[SA_DB_ROLL_COMMAND] = SA_DB_ROLL_COMMAND_SUM;
	
	// Check to see if the delimiter is the initial character of the roll 
	// string. If so (i.e. if the die count is omitted), we assume it to be 1
	// (i.e. 'd6' is read as '1d6').
	if(delimiterRange.location == 0)
	{
		expression[SA_DB_ROLL_DIE_COUNT] = [self legacyExpressionForStringDescribingNumericValue:@"1"];
	}
	else
	{
		// The die count is the expression generated by parsing the string 
		// before the delimiter.
		expression[SA_DB_ROLL_DIE_COUNT] = [self legacyExpressionForLegalString:[dieRollString substringToIndex:delimiterRange.location]];
	}

	// The die size is the expression generated by parsing the string after the 
	// delimiter.
	expression[SA_DB_ROLL_DIE_SIZE] = [self legacyExpressionForLegalString:[dieRollString substringFromIndex:(delimiterRange.location + delimiterRange.length)]];

	// The die count and die size have now been parsed recursively; this parsing
	// may have generated one or more errors. Inherit any error(s) from the 
	// error-generating sub-terms.
	addErrorsFromExpressionToExpression(expression[SA_DB_ROLL_DIE_COUNT], expression);
	addErrorsFromExpressionToExpression(expression[SA_DB_ROLL_DIE_SIZE], expression);
	
	return expression;
}

- (NSDictionary *)legacyExpressionForStringDescribingNumericValue:(NSString *)dieRollString
{
	NSMutableDictionary *expression = [NSMutableDictionary dictionary];
	expression[SA_DB_TERM_TYPE] = SA_DB_TERM_TYPE_VALUE;
	expression[SA_DB_INPUT_STRING] = dieRollString;
	
	expression[SA_DB_VALUE] = @(dieRollString.integerValue);
	
	return expression;
}

/****************************/
#pragma mark - Helper methods
/****************************/

+ (void)loadValidCharactersDict
{
	NSString *stringFormatRulesPath = [[NSBundle bundleForClass:[self class]] pathForResource:SA_DB_STRING_FORMAT_RULES_PLIST_NAME ofType:@"plist"];
	_validCharactersDict = [NSDictionary dictionaryWithContentsOfFile:stringFormatRulesPath][SA_DB_VALID_CHARACTERS];
	if(_validCharactersDict)
	{
		NSLog(@"Valid characters dictionary loaded successfully.");
	}
	else
	{
		NSLog(@"Could not load valid characters dictionary!");
	}
}

+ (NSString *)allValidCharacters
{
	NSMutableString *validCharactersString = [NSMutableString string];
	
	[validCharactersString appendString:[SA_DiceParser validNumeralCharacters]];
	[validCharactersString appendString:[SA_DiceParser validRollCommandDelimiterCharacters]];
	[validCharactersString appendString:[SA_DiceParser allValidOperatorCharacters]];
	
	return validCharactersString;
}

+ (NSString *)allValidOperatorCharacters
{
	NSDictionary *validCharactersDict = [SA_DiceParser validCharactersDict];
		
	__block NSMutableString *validOperatorCharactersString = [NSMutableString string];
	
	[validCharactersDict[SA_DB_VALID_OPERATOR_CHARACTERS] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
		[validOperatorCharactersString appendString:value];
	}];
	
	return validOperatorCharactersString;
}

+ (NSString *)validCharactersForOperator:(NSString *)operatorName
{
	return [SA_DiceParser validCharactersDict][SA_DB_VALID_OPERATOR_CHARACTERS][operatorName];
}

+ (NSString *)validNumeralCharacters
{
	NSDictionary *validCharactersDict = [SA_DiceParser validCharactersDict];
	
	return validCharactersDict[SA_DB_VALID_NUMERAL_CHARACTERS];
}

+ (NSString *)validRollCommandDelimiterCharacters
{
	NSDictionary *validCharactersDict = [SA_DiceParser validCharactersDict];

	return validCharactersDict[SA_DB_VALID_ROLL_COMMAND_DELIMITER_CHARACTERS];
}

@end