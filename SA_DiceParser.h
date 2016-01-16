//
//  SA_DiceParser.h
//  RPGBot
//
//  Created by Sandy Achmiz on 12/30/15.
//
//

#import <Foundation/Foundation.h>

/*********************/
#pragma mark Constants
/*********************/
/*
 These constants describe one of several behavior modes for roll string parsing.
 
 Each behavior mode defines a set of capabilities - what sorts of expressions,
 operators, roll commands, etc. the parser recognizes in that mode, and the 
 syntax for using those capabilities.
 
 The structure and content of the expression tree generated by the parser from
 a given die roll string also depends on the behavior mode that the parser is 
 set to.
 
 NOTE: While SA_DiceEvaluator is modeless (it correctly evaluates all
 expressions generated by the parser in any supported mode),  
 SA_DiceFormatter is modal. SA_DiceFormatter provides several
 formatter behaviors, each of which supports one or more parser modes. Using the
 wrong formatter behavior mode for an expression tree (that is, passing an 
 SA_DiceFormatter instance an expression tree that was was generated 
 by a parser mode that is not supported by the formatter's currently set 
 formatter behavior mode) results in undefined behavior.
 
 See SA_DiceFormatter.h for a list of which formatter behavior modes are 
 appropriate for use with which parser modes. See also SA_DiceBot.h for a 
 discussion of how the currently set parser mode affects what die-roll-related
 bot commands are available. (Together, the parser behavior mode and the results
 formatter behavior mode define the behavior and capabilities of an SA_DiceBot.)
 
 Each mode is described below.
 
 ======================
 ==== DEFAULT mode ====
 ======================
 
 "Default" mode is an alias for whatever default behavior is currently set for 
 new SA_DiceParser instances. (The "default default" behavior for the current 
 implementation is "legacy".)
 
 =====================
 ==== LEGACY mode ====
 =====================
 
 Legacy mode (mostly) emulates DiceBot by Sabin (and Dawn by xthemage before 
 it). It replicates the parsing and evaluation functions of those venerable 
 bots, providing the following capabilities:
 
 1. Arithmetic operations: addition, subtraction, multiplication. Syntax is as
 normal for such operations, e.g.:
 
 2+3
 25*10
 5-3*2
 
 Normal operator precedence and behavior (commutativity, associativity) apply.

 2. Simple roll-and-sum. Roll X dice, each with Y sides, and take the sum of
 the rolled values, by inputting 'XdY' where X is a nonnegative integer and Y 
 is a positive integer, e.g.:
 
 1d20
 5d6
 8d27
 
 3. Left-associative recursive roll-and-sum. Roll X dice, each with Y sides, 
 and take the sum of the rolled values, by inputting 'XdY', where Y is a 
 positive integer and X may be a nonnegative integer or a recursive roll-and-sum
 expression, e.g.:
 
 5d6d10
 1d20d6
 4d4d4d4d4d4d4
 
 The above capabilities may be used indiscriminately in a single roll string:
  
 1d20-5
 5d6*10
 1d20+2d4*10
 5d6d10-2*3
 5+3-2*4d6+2d10d3-20+5d4*2
 
 NOTE: The 'd' operator takes precedence over arithmetic operators. (Legacy 
 mode does not support parentheses.)
 
 NOTE 2: Legacy mode does not support whitespace within roll strings.
 
 =====================
 ==== MODERN mode ====
 =====================
 
 >>> NOT YET IMPLEMENTED <<<
 
 Modern mode provides a comprehensive range of commands and capabilities.
 
 ======================
 ==== FEEPBOT mode ====
 ======================
 
 >>> NOT YET IMPLEMENTED <<<
 
 Feepbot mode emulates feepbot by feep.
 */
typedef enum
{
	SA_DiceParserBehaviorDefault	=	    0,
	SA_DiceParserBehaviorLegacy		=	 1337,
	SA_DiceParserBehaviorModern		=	 2001,
	SA_DiceParserBehaviorFeepbot	=	65516
} SA_DiceParserBehavior;

/*********************************************/
#pragma mark - SA_DiceParser class declaration
/*********************************************/

@interface SA_DiceParser : NSObject

/************************/
#pragma mark - Properties
/************************/

@property SA_DiceParserBehavior parserBehavior;

/****************************************/
#pragma mark - "Class property" accessors
/****************************************/

+ (void)setDefaultParserBehavior:(SA_DiceParserBehavior)defaultParserBehavior;
+ (SA_DiceParserBehavior)defaultParserBehavior;

/********************************************/
#pragma mark - Initializers & factory methods
/********************************************/

- (instancetype)init;
- (instancetype)initWithBehavior:(SA_DiceParserBehavior)parserBehavior NS_DESIGNATED_INITIALIZER;
+ (instancetype)defaultParser;
+ (instancetype)parserWithBehavior:(SA_DiceParserBehavior)parserBehavior;

/****************************/
#pragma mark - Public methods
/****************************/

- (NSDictionary *)expressionForString:(NSString *)dieRollString;

@end