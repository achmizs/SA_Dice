//
//  SA_DiceFormatter.m
//
//  Copyright 2016-2021 Said Achmiz.
//  See LICENSE and README.md for more info.

#import "SA_DiceFormatter.h"

#import "SA_DiceExpressionStringConstants.h"

#import "SA_Utility.h"

/********************************/
#pragma mark File-scope variables
/********************************/

static SA_DiceFormatterBehavior _defaultFormatterBehavior = SA_DiceFormatterBehaviorLegacy;
static NSDictionary *_errorDescriptions;
static NSDictionary *_stringFormatRules;

/***************************************************/
#pragma mark - SA_DiceFormatter class implementation
/***************************************************/

@implementation SA_DiceFormatter {
	SA_DiceFormatterBehavior _formatterBehavior;
}

/**********************************/
#pragma mark - Properties (general)
/**********************************/

-(void) setFormatterBehavior:(SA_DiceFormatterBehavior)newFormatterBehavior {
	_formatterBehavior = newFormatterBehavior;
	
	switch (_formatterBehavior) {
		case SA_DiceFormatterBehaviorLegacy:
			self.legacyModeErrorReportingEnabled = YES;
			break;

		case SA_DiceFormatterBehaviorSimple:
		case SA_DiceFormatterBehaviorModern:
		case SA_DiceFormatterBehaviorFeepbot:
			break;
			
		case SA_DiceFormatterBehaviorDefault:
		default:
			self.formatterBehavior = SA_DiceFormatter.defaultFormatterBehavior;
			break;
	}
}

-(SA_DiceFormatterBehavior) formatterBehavior {
	return _formatterBehavior;
}

/******************************/
#pragma mark - Class properties
/******************************/

+(void) setDefaultFormatterBehavior:(SA_DiceFormatterBehavior)newDefaultFormatterBehavior {
	if (newDefaultFormatterBehavior == SA_DiceFormatterBehaviorDefault) {
		_defaultFormatterBehavior = SA_DiceFormatterBehaviorLegacy;
	} else {
		_defaultFormatterBehavior = newDefaultFormatterBehavior;
	}
}

+(SA_DiceFormatterBehavior) defaultFormatterBehavior {
	return _defaultFormatterBehavior;
}

+(NSDictionary *) stringFormatRules {
	if (_stringFormatRules == nil) {
		[SA_DiceFormatter loadStringFormatRules];
	}
	
	return _stringFormatRules;
}

/********************************************/
#pragma mark - Initializers & factory methods
/********************************************/

-(instancetype) init {
	return [self initWithBehavior:SA_DiceFormatterBehaviorDefault];
}

-(instancetype) initWithBehavior:(SA_DiceFormatterBehavior)formatterBehavior {
	if (self = [super init]) {
		self.formatterBehavior = formatterBehavior;
		
		if (_errorDescriptions == nil) {
			[SA_DiceFormatter loadErrorDescriptions];
		}

		if (_stringFormatRules == nil) {
			[SA_DiceFormatter loadStringFormatRules];
		}
	}
	return self;
}

+(instancetype) defaultFormatter {
	return [[SA_DiceFormatter alloc] initWithBehavior:SA_DiceFormatterBehaviorDefault];
}

+(instancetype) formatterWithBehavior:(SA_DiceFormatterBehavior)formatterBehavior {
	return [[SA_DiceFormatter alloc] initWithBehavior:formatterBehavior];
}

/****************************/
#pragma mark - Public methods
/****************************/

-(NSString *) stringFromExpression:(SA_DiceExpression *)expression {
	if (_formatterBehavior == SA_DiceFormatterBehaviorSimple) {
		return [self simpleStringFromExpression:expression];
	} else { // if(_formatterBehavior == SA_DiceFormatterBehaviorLegacy)
		return [self legacyStringFromExpression:expression];
	}
}

// NOT YET IMPLEMENTED
-(NSAttributedString *) attributedStringFromExpression:(SA_DiceExpression *)expression {
	return [[NSAttributedString alloc] initWithString:[self stringFromExpression:expression]];
}

/**********************************************/
#pragma mark - “Legacy” behavior implementation
/**********************************************/

// METHODS

-(NSString *) legacyStringFromExpression:(SA_DiceExpression *)expression {
	NSMutableString *formattedString = [NSMutableString string];
	
	// Attach the formatted string representation of the expression itself.
	[formattedString appendString:[self legacyStringFromIntermediaryExpression:expression]];
	
	// An expression may contain either a result, or one or more errors.
	// If a result is present, attach it. If errors are present, attach them
	// only if error reporting is enabled.
	if (expression.result != nil) {
		[formattedString appendFormat:@" = %@", expression.result];
	} else if (   _legacyModeErrorReportingEnabled == YES
			   && expression.errorBitMask != 0) {
		[formattedString appendFormat:((__builtin_popcountl(expression.errorBitMask) == 1)
									   ? @" [ERROR: %@]"
									   : @" [ERRORS: %@]"),
		 [SA_DiceFormatter descriptionForErrors:expression.errorBitMask]];
	}
	
	// Make all instances of the minus sign be represented with the proper,
	// canonical minus sign.
	return [SA_DiceFormatter rectifyMinusSignInString:formattedString];
}

-(NSString *) legacyStringFromIntermediaryExpression:(SA_DiceExpression *)expression {
	/*
	 In legacy behavior, we do not print the results of intermediate terms in 
	 the expression tree (since the legacy output format was designed for 
	 expressions generated by a parser that does not support parentheses, 
	 doing so would not make sense anyway).
	 
	 The exception is roll commands, where the result of a roll-and-sum command
	 is printed along with the rolls.
	 
	 For this reasons, when we recursively retrieve the string representations
	 of sub-expressions, we call this method, not -[legacyStringFromExpression:].
	 */

	switch (expression.type) {
		case SA_DiceExpressionTerm_OPERATION: {
			return [self legacyStringFromOperationExpression:expression];
			break;
		}
		case SA_DiceExpressionTerm_ROLL_COMMAND: {
			return [self legacyStringFromRollCommandExpression:expression];
			break;
		}
		case SA_DiceExpressionTerm_ROLL_MODIFIER: {
			return [self legacyStringFromRollModifierExpression:expression];
			break;
		}
		case SA_DiceExpressionTerm_VALUE: {
			return [self legacyStringFromValueExpression:expression];
			break;
		}
		default: {
			return expression.inputString;
			break;
		}
	}
}

-(NSString *) legacyStringFromOperationExpression:(SA_DiceExpression *)expression {
	if (expression.operator == SA_DiceExpressionOperator_MINUS &&
		expression.leftOperand == nil) {
		// Check to see if the term is a negation operation.
		return [@[ [SA_DiceFormatter canonicalRepresentationForOperator:SA_DiceExpressionOperator_MINUS],
				   [self legacyStringFromIntermediaryExpression:expression.rightOperand]
				   ] componentsJoinedByString:@""];
	} else if (expression.operator == SA_DiceExpressionOperator_MINUS ||
			   expression.operator == SA_DiceExpressionOperator_PLUS ||
			   expression.operator == SA_DiceExpressionOperator_TIMES) {
		// Check to see if the term is an addition, subtraction, or
		// multiplication operation.
		return [@[ [self legacyStringFromIntermediaryExpression:expression.leftOperand],
				   [SA_DiceFormatter canonicalRepresentationForOperator:expression.operator],
				   [self legacyStringFromIntermediaryExpression:expression.rightOperand]
				   ] componentsJoinedByString:@" "];
	} else {
		// If the operator is not one of the supported operators, default to
		// outputting the input string.
		return expression.inputString;
	}
}

-(NSString *) legacyStringFromRollCommandExpression:(SA_DiceExpression *)expression {
	/*
	 In legacy behavior, we print the result of roll commands with the rolls
	 generated by the roll command. If a roll command generates a roll-related 
	 error (any of the errors that begin with DIE_), we print “ERROR” in place 
	 of a result.
	 
	 Legacy behavior assumes support for roll-and-sum only, so we do not need
	 to adjust the output format for different roll commands.
	*/
	return [NSString stringWithFormat:@"%@%@%@ < %@%@ >",
			[self legacyStringFromIntermediaryExpression:expression.dieCount],
			[SA_DiceFormatter canonicalRepresentationForRollCommandDelimiter:expression.rollCommand],
			[self legacyStringFromIntermediaryExpression:expression.dieSize],
			((expression.rolls != nil) ?
			 [NSString stringWithFormat:@"%@ = ",
			  [(expression.dieType == SA_DiceExpressionDice_FUDGE ?
				[self formattedFudgeRolls:expression.rolls] :
				expression.rolls
				) componentsJoinedByString:@" "]] :
			 @""),
			(expression.result ?: @"ERROR")];
}

-(NSArray *) formattedFudgeRolls:(NSArray <NSNumber *> *)rolls {
	static NSDictionary *fudgeDieRollRepresentations;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		fudgeDieRollRepresentations = @{ @(-1): [SA_DiceFormatter canonicalRepresentationForOperator:SA_DiceExpressionOperator_MINUS],
										 @(0): @"0",
										 @(1): [SA_DiceFormatter canonicalRepresentationForOperator:SA_DiceExpressionOperator_PLUS]
										 };
	});

	return [rolls map:^NSString *(NSNumber *roll) {
		return fudgeDieRollRepresentations[roll];
	}];
}

-(NSString *) legacyStringFromRollModifierExpression:(SA_DiceExpression *)expression {
	/*
	 In legacy behavior, we print the result of roll modifiers with the rolls
	 generated by the roll command, plus the modifications. If a roll modifier 
	 generates an error, we print “ERROR” in place of any of the components.

	 Legacy behavior assumes support for the ‘keep’ modifier only, so we do not 
	 need to adjust the output format for different roll modifiers.
	 */
	NSUInteger keptHowMany = expression.rightOperand.result.unsignedIntegerValue;
	return [NSString stringWithFormat:@"%@%@%@%@%@ < %@ less %@ leaves %@ = %@ >",
			[self legacyStringFromIntermediaryExpression:expression.leftOperand.dieCount],
			[SA_DiceFormatter canonicalRepresentationForRollCommandDelimiter:expression.leftOperand.rollCommand],
			[self legacyStringFromIntermediaryExpression:expression.leftOperand.dieSize],
			[SA_DiceFormatter canonicalRepresentationForRollModifierDelimiter:expression.rollModifier],
			expression.rightOperand.result,
			((expression.leftOperand.rolls != nil) ?
			 [(expression.leftOperand.dieType == SA_DiceExpressionDice_FUDGE ?
			   [self formattedFudgeRolls:expression.rolls] :
			   expression.leftOperand.rolls
			   ) componentsJoinedByString:@" "] :
			 @""),
			[(expression.leftOperand.dieType == SA_DiceExpressionDice_FUDGE ?
			  [self formattedFudgeRolls:[expression.rolls subarrayWithRange:NSRangeMake(keptHowMany, expression.rolls.count - keptHowMany)]] :
			  [expression.rolls subarrayWithRange:NSRangeMake(keptHowMany, expression.rolls.count - keptHowMany)]
			  ) componentsJoinedByString:@" "],
			[(expression.leftOperand.dieType == SA_DiceExpressionDice_FUDGE ?
			  [self formattedFudgeRolls:[expression.rolls subarrayWithRange:NSRangeMake(0, keptHowMany)]] :
			  [expression.rolls subarrayWithRange:NSRangeMake(0, keptHowMany)]
			  ) componentsJoinedByString:@" "],
			(expression.result ?: @"ERROR")];
}

-(NSString *) legacyStringFromValueExpression:(SA_DiceExpression *)expression {
	if ([expression.inputString.lowercaseString isEqualToString:@"f"]) {
		return @"F";
	} else {
		// We use the value for the ‘value’ property and not the ‘result’ property
		// because they should be the same, and the ‘result’ property might not
		// have a value (if the expression was not evaluated); this saves us
		// having to compare it against nil, and saves code.
		return [expression.value stringValue];
	}
}

/**********************************************/
#pragma mark - “Simple” behavior implementation
/**********************************************/

-(NSString *) simpleStringFromExpression:(SA_DiceExpression *)expression {
	NSString *formattedString = [NSString stringWithFormat:@"%@", 
								 (expression.result ?: @"ERROR")];
	
	// Make all instances of the minus sign be represented with the proper,
	// canonical minus sign.
	return [SA_DiceFormatter rectifyMinusSignInString:formattedString];
}

/****************************/
#pragma mark - Helper methods
/****************************/

+(NSString *) rectifyMinusSignInString:(NSString *)aString {
	NSMutableString* sameStringButMutable = aString.mutableCopy;
	
	NSString *validMinusSignCharacters = [SA_DiceFormatter stringFormatRules][SA_DB_VALID_CHARACTERS][SA_DB_VALID_OPERATOR_CHARACTERS][NSStringFromSA_DiceExpressionOperator(SA_DiceExpressionOperator_MINUS)];
	[validMinusSignCharacters enumerateSubstringsInRange:NSRangeMake(0, validMinusSignCharacters.length) 
												 options:NSStringEnumerationByComposedCharacterSequences 
											  usingBlock:^(NSString *aValidMinusSignCharacter,
														   NSRange characterRange,
														   NSRange enclosingRange,
														   BOOL *stop) {
		 [sameStringButMutable replaceOccurrencesOfString:aValidMinusSignCharacter 
											   withString:[SA_DiceFormatter canonicalRepresentationForOperator:SA_DiceExpressionOperator_MINUS]
												  options:NSLiteralSearch 
													range:NSRangeMake(0, sameStringButMutable.length)];
	 }];
	
	return [sameStringButMutable copy];
}

+(void) loadErrorDescriptions {
	NSString* errorDescriptionsPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"SA_DB_ErrorDescriptions"
																					   ofType:@"plist"];
	_errorDescriptions = [NSDictionary dictionaryWithContentsOfFile:errorDescriptionsPath];
	if (!_errorDescriptions) {
		NSLog(@"Could not load error descriptions!");
	}
}

+(NSString *) descriptionForErrors:(NSUInteger)errorBitMask {
	if (_errorDescriptions == nil) {
		[SA_DiceFormatter loadErrorDescriptions];
	}

	NSMutableArray <NSString *> *errorDescriptions = [NSMutableArray array];
	for (int i = 0; i <= 19; i++) {
		if ((errorBitMask & (1 << i)) == 0)
			continue;
		NSString *errorName = NSStringFromSA_DiceExpressionError((SA_DiceExpressionError) (1 << i));
		[errorDescriptions addObject:(_errorDescriptions[errorName] ?: errorName)];
	}

	return [errorDescriptions componentsJoinedByString:@" / "];
}

+(void) loadStringFormatRules {
	NSString *stringFormatRulesPath = [[NSBundle bundleForClass:[self class]] pathForResource:SA_DB_STRING_FORMAT_RULES_PLIST_NAME
																					   ofType:@"plist"];
	_stringFormatRules = [NSDictionary dictionaryWithContentsOfFile:stringFormatRulesPath];
	if (!_stringFormatRules) {
		NSLog(@"Could not load string format rules!");
	}
}

+(NSString *) canonicalRepresentationForOperator:(SA_DiceExpressionOperator)operator {
	return [SA_DiceFormatter canonicalOperatorRepresentations][NSStringFromSA_DiceExpressionOperator(operator)];
}

+(NSDictionary *) canonicalOperatorRepresentations {
	return [SA_DiceFormatter stringFormatRules][SA_DB_CANONICAL_REPRESENTATIONS][SA_DB_CANONICAL_OPERATOR_REPRESENTATIONS];
}

+(NSString *) canonicalRepresentationForRollCommandDelimiter:(SA_DiceExpressionRollCommand)command {
	return [SA_DiceFormatter canonicalRollCommandDelimiterRepresentations][NSStringFromSA_DiceExpressionRollCommand(command)];
}

+(NSDictionary *) canonicalRollCommandDelimiterRepresentations {
	return [SA_DiceFormatter stringFormatRules][SA_DB_CANONICAL_REPRESENTATIONS][SA_DB_CANONICAL_ROLL_COMMAND_DELIMITER_REPRESENTATIONS];
}

+(NSString *) canonicalRepresentationForRollModifierDelimiter:(SA_DiceExpressionRollModifier)modifier {
	return [SA_DiceFormatter canonicalRollModifierDelimiterRepresentations][NSStringFromSA_DiceExpressionRollModifier(modifier)];
}

+(NSDictionary *) canonicalRollModifierDelimiterRepresentations {
	return [SA_DiceFormatter stringFormatRules][SA_DB_CANONICAL_REPRESENTATIONS][SA_DB_CANONICAL_ROLL_MODIFIER_DELIMITER_REPRESENTATIONS];
}

@end
