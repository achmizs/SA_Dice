//
//  SA_DiceFormatter.m
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.

#import "SA_DiceFormatter.h"

#import "SA_DiceExpressionStringConstants.h"
#import "SA_DiceErrorHandling.h"

/********************************/
#pragma mark File-scope variables
/********************************/

static SA_DiceFormatterBehavior _defaultFormatterBehavior = SA_DiceFormatterBehaviorLegacy;
static NSDictionary *_errorDescriptions;
static NSDictionary *_stringFormatRules;

/**********************************************************/
#pragma mark - SA_DiceFormatter class implementation
/**********************************************************/

@implementation SA_DiceFormatter
{
	SA_DiceFormatterBehavior _formatterBehavior;
}

/**********************************/
#pragma mark - Properties (general)
/**********************************/

- (void)setFormatterBehavior:(SA_DiceFormatterBehavior)newFormatterBehavior
{
	_formatterBehavior = newFormatterBehavior;
	
	switch (_formatterBehavior)
	{
		case SA_DiceFormatterBehaviorLegacy:
			self.legacyModeErrorReportingEnabled = YES;
			break;

		case SA_DiceFormatterBehaviorSimple:
		case SA_DiceFormatterBehaviorModern:
		case SA_DiceFormatterBehaviorFeepbot:
			break;
			
		case SA_DiceFormatterBehaviorDefault:
		default:
			[self setFormatterBehavior:[SA_DiceFormatter defaultFormatterBehavior]];
			break;
	}
}

- (SA_DiceFormatterBehavior)formatterBehavior
{
	return _formatterBehavior;
}

/****************************************/
#pragma mark - "Class property" accessors
/****************************************/

+ (void)setDefaultFormatterBehavior:(SA_DiceFormatterBehavior)newDefaultFormatterBehavior
{
	if(newDefaultFormatterBehavior == SA_DiceFormatterBehaviorDefault)
	{
		_defaultFormatterBehavior = SA_DiceFormatterBehaviorLegacy;
	}
	else
	{
		_defaultFormatterBehavior = newDefaultFormatterBehavior;
	}
}

+ (SA_DiceFormatterBehavior)defaultFormatterBehavior
{
	return _defaultFormatterBehavior;
}

+ (NSDictionary *)stringFormatRules
{
	if(_stringFormatRules == nil)
	{
		[SA_DiceFormatter loadStringFormatRules];
	}
	
	return _stringFormatRules;
}

/********************************************/
#pragma mark - Initializers & factory methods
/********************************************/

- (instancetype)init
{
	return [self initWithBehavior:SA_DiceFormatterBehaviorDefault];
}

- (instancetype)initWithBehavior:(SA_DiceFormatterBehavior)formatterBehavior
{
	if(self = [super init])
	{
		self.formatterBehavior = formatterBehavior;
		
		if(_errorDescriptions == nil)
		{
			[SA_DiceFormatter loadErrorDescriptions];
		}
		if(_stringFormatRules == nil)
		{
			[SA_DiceFormatter loadStringFormatRules];
		}
	}
	return self;
}

+ (instancetype)defaultFormatter
{
	return [[SA_DiceFormatter alloc] initWithBehavior:SA_DiceFormatterBehaviorDefault];
}

+ (instancetype)formatterWithBehavior:(SA_DiceFormatterBehavior)formatterBehavior
{
	return [[SA_DiceFormatter alloc] initWithBehavior:formatterBehavior];
}

/****************************/
#pragma mark - Public methods
/****************************/

- (NSString *)stringFromExpression:(NSDictionary *)expression
{
	if(_formatterBehavior == SA_DiceFormatterBehaviorSimple)
	{
		return [self simpleStringFromExpression:expression];
	}
	else // if(_formatterBehavior == SA_DiceFormatterBehaviorLegacy)
	{
		return [self legacyStringFromExpression:expression];
	}
}

// NOT YET IMPLEMENTED
- (NSAttributedString *)attributedStringFromExpression:(NSDictionary *)expression
{
	return [[NSAttributedString alloc] initWithString:[self stringFromExpression:expression]];
}

/**********************************************/
#pragma mark - "Legacy" behavior implementation
/**********************************************/

// PROPERTIES

@synthesize legacyModeErrorReportingEnabled = _legacyModeErrorReportingEnabled;

// METHODS

- (NSString *)legacyStringFromExpression:(NSDictionary *)expression
{
	__block NSMutableString *formattedString = [NSMutableString string];
	
	// Attach the formatted string representation of the expression itself.
	[formattedString appendString:[self legacyStringFromIntermediaryExpression:expression]];
	
	// An expression may contain either a result, or one or more errors.
	// If a result is present, attach it. If errors are present, attach them
	// only if error reporting is enabled.
	if(expression[SA_DB_RESULT] != nil)
	{
		[formattedString appendFormat:@" = %@", expression[SA_DB_RESULT]];
	}
	else if(_legacyModeErrorReportingEnabled == YES && [getErrorsForExpression(expression) count] > 1)
	{
		if([getErrorsForExpression(expression) count] == 1)
		{
			[formattedString appendFormat:@" [ERROR: %@]", [SA_DiceFormatter descriptionForError:[getErrorsForExpression(expression) firstObject]]];
		}
		else
		{
			[formattedString appendFormat:@" [ERRORS: "];
			[getErrorsForExpression(expression) enumerateObjectsUsingBlock:^(NSString *error, NSUInteger idx, BOOL *stop)
			{
				[formattedString appendString:[SA_DiceFormatter descriptionForError:error]];
				if(idx != [getErrorsForExpression(expression) count] - 1)
				{
					[formattedString appendFormat:@", "];
				}
				else
				{
					[formattedString appendFormat:@"]"];
				}
			}];
		}
	}
	
	return formattedString;
}

- (NSString *)legacyStringFromIntermediaryExpression:(NSDictionary *)expression
{
	/*
	 In legacy behavior, we do not print the results of intermediate terms in 
	 the expression tree (since the legacy output format was designed for 
	 expressions generated by a parser that does not support parentheses, 
	 doing so would not make sense anyway).
	 
	 The exception is roll commands, where the result of a roll-and-sum command
	 is printed along with the rolls.
	 
	 For this reasons, when we recursively retrieve the string representations
	 of sub-expressions, we call this method, not legacyStringFromExpression:.
	 */
	
	if([expression[SA_DB_TERM_TYPE] isEqualToString:SA_DB_TERM_TYPE_OPERATION])
	{
		return [self legacyStringFromOperationExpression:expression];
	}
	else if([expression[SA_DB_TERM_TYPE] isEqualToString:SA_DB_TERM_TYPE_ROLL_COMMAND])
	{
		return [self legacyStringFromRollCommandExpression:expression];
	}
	else if([expression[SA_DB_TERM_TYPE] isEqualToString:SA_DB_TERM_TYPE_VALUE])
	{
		return [self legacyStringFromValueExpression:expression];
	}
	else // if([expression[SA_DB_TERM_TYPE] isEqualToString:SA_DB_TERM_TYPE_NONE]), probably
	{
		return expression[SA_DB_INPUT_STRING];
	}
}

- (NSString *)legacyStringFromOperationExpression:(NSDictionary *)expression
{
	NSMutableString *formattedString = [NSMutableString string];
	
	// Check to see if the term is a negation or subtraction operation.
	if([expression[SA_DB_OPERATOR] isEqualToString:SA_DB_OPERATOR_MINUS])
	{
		// Get the canonical representation for the operator.
		NSString *operatorString = [SA_DiceFormatter canonicalRepresentationForOperator:SA_DB_OPERATOR_MINUS];
		
		// If we have a left operand, it's subtraction. If we do not, it's
		// negation.
		if(expression[SA_DB_OPERAND_LEFT] == nil)
		{
			// Get the operand.
			NSDictionary *rightOperandExpression = expression[SA_DB_OPERAND_RIGHT];
			
			// Write out the string representations of operator and the 
			// right-hand-side expression.
			[formattedString appendString:operatorString];
			[formattedString appendString:[self legacyStringFromIntermediaryExpression:rightOperandExpression]];
			
			return formattedString;
		}
		else
		{
			// Get the operands.
			NSDictionary *leftOperandExpression = expression[SA_DB_OPERAND_LEFT];
			NSDictionary *rightOperandExpression = expression[SA_DB_OPERAND_RIGHT];
			
			// Write out the string representations of the left-hand-side
			// expression, the operator, and the right-hand-side expression.
			[formattedString appendString:[self legacyStringFromIntermediaryExpression:leftOperandExpression]];
			[formattedString appendFormat:@" %@ ", operatorString];
			[formattedString appendString:[self legacyStringFromIntermediaryExpression:rightOperandExpression]];
			
			return formattedString;
		}
	}
	// Check to see if the term is an addition or subtraction operation.
	else if([expression[SA_DB_OPERATOR] isEqualToString:SA_DB_OPERATOR_PLUS])
	{
		NSString *operatorString = [SA_DiceFormatter canonicalRepresentationForOperator:SA_DB_OPERATOR_PLUS];

		// Get the operands.
		NSDictionary *leftOperandExpression = expression[SA_DB_OPERAND_LEFT];
		NSDictionary *rightOperandExpression = expression[SA_DB_OPERAND_RIGHT];
				
		// Write out the string representations of the left-hand-side
		// expression, the operator, and the right-hand-side expression.
		[formattedString appendString:[self legacyStringFromIntermediaryExpression:leftOperandExpression]];
		[formattedString appendFormat:@" %@ ", operatorString];
		[formattedString appendString:[self legacyStringFromIntermediaryExpression:rightOperandExpression]];
		
		return formattedString;
	}
	// Check to see if the term is a multiplication operation.
	else if([expression[SA_DB_OPERATOR] isEqualToString:SA_DB_OPERATOR_TIMES])
	{
		// Get the canonical representation for the operator.
		NSString *operatorString = [SA_DiceFormatter canonicalRepresentationForOperator:SA_DB_OPERATOR_TIMES];
		
		// Get the operands.
		NSDictionary *leftOperandExpression = expression[SA_DB_OPERAND_LEFT];
		NSDictionary *rightOperandExpression = expression[SA_DB_OPERAND_RIGHT];
		
		// Write out the string representations of the left-hand-side
		// expression, the operator, and the right-hand-side expression.
		[formattedString appendString:[self legacyStringFromIntermediaryExpression:leftOperandExpression]];
		[formattedString appendFormat:@" %@ ", operatorString];
		[formattedString appendString:[self legacyStringFromIntermediaryExpression:rightOperandExpression]];
		
		return formattedString;
	}
	else
	{
		// If the operator is not one of the supported operators, default to
		// outputting the input string.
		return expression[SA_DB_INPUT_STRING];
	}
}

- (NSString *)legacyStringFromRollCommandExpression:(NSDictionary *)expression
{
	/*
	 In legacy behavior, we print the result of roll commands with the rolls
	 generated by the roll command. If a roll command generates a roll-related 
	 error (any of the errors that begin with SA_DB_DIE_), we print "ERROR" 
	 in place of a result.
	 
	 Legacy behavior assumes support for roll-and-sum only, so we do not need
	 to adjust the output format for different roll commands.
	*/
	__block NSMutableString *formattedString = [NSMutableString string];
	
	// Append the die roll expression itself.
	[formattedString appendString:[self legacyStringFromIntermediaryExpression:expression[SA_DB_ROLL_DIE_COUNT]]];
	[formattedString appendString:[SA_DiceFormatter canonicalRollCommandDelimiterRepresentation]];
	[formattedString appendString:[self legacyStringFromIntermediaryExpression:expression[SA_DB_ROLL_DIE_SIZE]]];
	
	[formattedString appendFormat:@" < "];

	// Append a list of the rolled values, if any.
	if(expression[SA_DB_ROLLS] != nil && [expression[SA_DB_ROLLS] count] > 0)
	{
		[expression[SA_DB_ROLLS] enumerateObjectsUsingBlock:^(NSNumber *roll, NSUInteger idx, BOOL *stop) {
			[formattedString appendFormat:@"%@ ", roll];
		}];
		
		[formattedString appendFormat:@"= "];
	}
	
	// Append either the result, or the word 'ERROR'.
	[formattedString appendFormat:@"%@ >", ((expression[SA_DB_RESULT] != nil) ? expression[SA_DB_RESULT] : @"ERROR")];
	
	return formattedString;
}

- (NSString *)legacyStringFromValueExpression:(NSDictionary *)expression
{
	// We use the value for the SA_DB_VALUE key and not the SA_DB_RESULT key
	// because they should be the same, and the SA_DB_RESULT key might not
	// have a value (if the expression was not evaluated); this saves us
	// having to compare it against nil, and saves code.
	return [expression[SA_DB_VALUE] stringValue];
}

/**********************************************/
#pragma mark - "Simple" behavior implementation
/**********************************************/

- (NSString *)simpleStringFromExpression:(NSDictionary *)expression
{
	NSMutableString *formattedString = [NSMutableString string];
	
	if(expression[SA_DB_RESULT] != nil)
	{
		[formattedString appendFormat:@"%@", expression[SA_DB_RESULT]];
	}
	else
	{
		[formattedString appendFormat:@"ERROR"];
	}
	
	return formattedString;
}

/****************************/
#pragma mark - Helper methods
/****************************/

+ (void)loadErrorDescriptions
{
	NSString* errorDescriptionsPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"SA_DB_ErrorDescriptions" ofType:@"plist"];
	_errorDescriptions = [NSDictionary dictionaryWithContentsOfFile:errorDescriptionsPath];
	if(_errorDescriptions)
	{
		NSLog(@"Error descriptions loaded successfully.");
	}
	else
	{
		NSLog(@"Could not load error descriptions!");
	}
}

+ (NSString *)descriptionForError:(NSString *)error
{
	if(_errorDescriptions == nil)
	{
		[SA_DiceFormatter loadErrorDescriptions];
	}
	
	if(_errorDescriptions[error] != nil)
	{
		return _errorDescriptions[error];
	}
	else
	{
		return error;
	}
}

+ (void)loadStringFormatRules
{
	NSString *stringFormatRulesPath = [[NSBundle bundleForClass:[self class]] pathForResource:SA_DB_STRING_FORMAT_RULES_PLIST_NAME ofType:@"plist"];
	_stringFormatRules = [NSDictionary dictionaryWithContentsOfFile:stringFormatRulesPath];
	if(_stringFormatRules)
	{
		NSLog(@"String format rules loaded successfully.");
	}
	else
	{
		NSLog(@"Could not load string format rules!");
	}
}

+ (NSString *)canonicalRepresentationForOperator:(NSString *)operatorName
{
	return [SA_DiceFormatter canonicalOperatorRepresentations][operatorName];
}

+ (NSDictionary *)canonicalOperatorRepresentations
{
	return [SA_DiceFormatter stringFormatRules][SA_DB_CANONICAL_REPRESENTATIONS][SA_DB_CANONICAL_OPERATOR_REPRESENTATIONS];
}

+ (NSString *)canonicalRollCommandDelimiterRepresentation
{
	return [SA_DiceFormatter stringFormatRules][SA_DB_CANONICAL_REPRESENTATIONS][SA_DB_CANONICAL_ROLL_COMMAND_DELIMITER_REPRESENTATION];
}

@end
