//
//  SA_DiceFormatter.h
//
//  Copyright 2016-2021 Said Achmiz.
//  See LICENSE and README.md for more info.

#import <Foundation/Foundation.h>

#import "SA_DiceExpression.h"

/*********************/
#pragma mark Constants
/*********************/
/*
 These constants describe one of several behavior modes for die string results 
 formatting.
 
 NOTE: Each of the modes have their own set of settings, which may be configured
 via various of the SA_DiceFormatter properties. Be sure to use the 
 appropriate settings for the currently set behavior mode.

 NOTE 2: SA_DiceParser also has a behavior mode property, and can operate in 
 one of several parser behavior modes. Each formatter behavior mode is 
 appropriate for formatting results generated by some parser behavior modes but 
 not others. Attempting to format a results tree in a formatter mode that does 
 not support the parser mode in which those results were generated causes
 undefined behavior. Thus, when using any a formatter and a parser together, we
 must always make sure that the two objects are set to operate in compatible
 behavior modes.
 
 Each formatter behavior mode is described below. Each description also lists 
 the parser modes which are supported by that formatter mode.
 
 ======================
 ==== DEFAULT mode ====
 ======================
 
 “Default” mode is an alias for whatever default behavior is currently set for
 new SA_DiceFormatter instances. (The “default default” behavior for the
 current implementation is “legacy”.)
 
 =====================
 ==== LEGACY mode ====
 =====================
 
 Legacy mode mostly emulates the output format of DiceBot by Sabin (and Dawn by 
 xthemage before it). (It adds optional error reporting, and several minor 
 aesthetic enhancement options.)
 
 The legacy mode output format reproduces the entire die roll expression, in
 an expanded form (with whitespace inserted between operators and operands);
 prints each individual die roll (grouped by roll command), along with the 
 sum of each die group. The final result is also printed, as is a label 
 (if any). Typical legacy mode output looks like this:
 
 (Hasan_the_Great) 4d6 < 3 3 4 6 = 16 > + 2d4 < 2 4 = 6 > + 3 + 20 = 45
 
 This output line would be generated by a roll string as follows:
 
 4d6+2d4+3+20;Hasan_the_Great
 
 Here are some typical output strings for erroneous or malformed input strings.
 
 INPUT:
 8d6+4d0+5
 
 OUTPUT:
 8d6 < 3 1 2 5 2 2 1 6 = 22 > + 4d0 < ERROR > [ERROR: Invalid die size (zero or negative)]
 
 Legacy mode does not support attributed text of any kind.
 
 SUPPORTED PARSER MODES: Legacy.
 
 =====================
 ==== SIMPLE mode ====
 =====================
 
 Simple mode generates a very minimal output format. It prints the final result 
 of a die roll expression, or the word ‘ERROR’ if any error occurred. It also
 prints the label (if any).
 
 SUPPORTED PARSER MODES: Feepbot, Legacy.
 
 =====================
 ==== MODERN mode ====
 =====================
 
 >>> NOT YET IMPLEMENTED <<<
 
 Modern mode supports a comprehensive range of commands and capabilities, and 
 has many configurable options for extensive customizability of the output 
 format. It also supports attributed text.
 
 SUPPORTED PARSER MODES: Feepbot, Legacy, Modern.
 
 ======================
 ==== FEEPBOT mode ====
 ======================
 
 >>> NOT YET IMPLEMENTED <<<
 
 Feepbot mode emulates the output format of feepbot by feep.
 
 SUPPORTED PARSER MODES: Feepbot, Legacy.
 */
typedef NS_ENUM(unsigned int, SA_DiceFormatterBehavior) {
	SA_DiceFormatterBehaviorDefault	=	    0,
	SA_DiceFormatterBehaviorSimple	=	    1,
	SA_DiceFormatterBehaviorLegacy	=	 1337,
	SA_DiceFormatterBehaviorModern	=	 2001,
	SA_DiceFormatterBehaviorFeepbot	=	65536
};

/************************************************/
#pragma mark - SA_DiceFormatter class declaration
/************************************************/

@interface SA_DiceFormatter : NSObject

/**********************************/
#pragma mark - Properties (general)
/**********************************/

@property SA_DiceFormatterBehavior formatterBehavior;

/*************************************************/
#pragma mark - Properties (“legacy” behavior mode)
/*************************************************/

@property BOOL legacyModeErrorReportingEnabled;

/******************************/
#pragma mark - Class properties
/******************************/

@property (class) SA_DiceFormatterBehavior defaultFormatterBehavior;

/********************************************/
#pragma mark - Initializers & factory methods
/********************************************/

-(instancetype) init;
-(instancetype) initWithBehavior:(SA_DiceFormatterBehavior)formatterBehavior NS_DESIGNATED_INITIALIZER;
+(instancetype) defaultFormatter;
+(instancetype) formatterWithBehavior:(SA_DiceFormatterBehavior)formatterBehavior;

/****************************/
#pragma mark - Public methods
/****************************/

-(NSString *) stringFromExpression:(SA_DiceExpression *)expression;
-(NSAttributedString *) attributedStringFromExpression:(SA_DiceExpression *)expression;

+(NSString *) rectifyMinusSignInString:(NSString *)aString;
+(NSString *) canonicalRepresentationForOperator:(SA_DiceExpressionOperator)operator;

@end
