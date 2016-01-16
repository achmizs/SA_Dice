//
//  SA_DiceBot.h
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.
/*
 The SA_DiceBot class hierarchy works like this:
 
 SA_DiceBot is the root class. A user of the SA_DiceBot package usually only
 needs to create and manage objects of this class. An SA_DiceBot creates and
 manages all other objects and classes in the package (directly or through its
 other members), as needed.
 
 An SA_DiceBot owns a single SA_DiceRoller and a single SA_DiceFormatter.
 
 The objects owned by an SA_DiceBot are for the SA_DiceBot's internal use 
 only, and not accessible to users of the package. (But see SA_DiceRoller.h 
 and SA_DiceFormatter.h for information on standalone use.)
 
 An SA_DiceRoller owns an SA_DiceParser and an SA_DiceEvaluator. An
 SA_DiceEvaluator owns an SA_DiceBag. (See Figure 1, below.)
 
 *--------------------------------------------------------------------------*
 |	Fig. 1. SA_DiceBot class hierarchy diagram.								|
 |																			|
 |																			|
 |								SA_DiceBot									|
 |								/		 \									|
 |			SA_DiceFormatter		SA_DiceRoller						|
 |										/			\						|
 |							SA_DiceParser			SA_DiceEvaluator		|
 |															|				|
 |														SA_DiceBag			|
 |																			|
 *--------------------------------------------------------------------------*
 
 When the SA_DiceBot receives a recognized command that involves rolling some
 dice or otherwise evaluating some sort of string of semantically meaningful
 text (like just adding some numbers), it extracts that string (which may 
 optionally include some text label) from the rest of the message body, and 
 passes it to the SA_DiceRoller.
 
 The SA_DiceRoller strips off the label (if any), and passes the 'pure' string
 to the SA_DiceParser.
 
 The SA_DiceParser parses the string and produces an 'expression tree' 
 representation of the string. An expression tree is an NSDictionary with a 
 certain structure (which is described in SA_DiceExpressionStringConstants.h).
 
 The SA_DiceRoller then passes the expression tree to the SA_DiceEvaluator.
 The evaluator recursively traverses the expression tree in a depth-first 
 manner, computing the results of each subtree, and storing those results in 
 (a mutable copy of) the expression tree itself. Once the entire tree has been
 evaluated, (a mutable copy of) it is returned to the SA_DiceRoller. The 
 SA_DiceRoller reattaches the stripped-off label (inserting it into the top
 level of the expresion tree) and returns the evaluated expression tree 
 (now called a result) to the SA_DiceBot.
 
 The SA_DiceBot passes the evaluated result tree to its SA_DiceFormatter.
 The formatter traverses the tree, constructing a human-readable string form of 
 the results, with whatever formatting it (the formatter) has been configured
 to provide. The formatter then returns this formatted result string to the
 SA_DiceBot.
 
 The SA_DiceBot then incorporates the formatted result string into some 
 appropriate reply message or messages, and sends the reply(ies) back to its
 delegate, for transmission to the appropriate endpoint.
 */

#import <Foundation/Foundation.h>
#import "SA_Bot.h"

@class SA_CommandResponder;

/*
 ######################################
 #### SA_DiceBot Usage Information ####
 ######################################
 
 I. SUPPORTED COMMANDS & PARSER MODES
 
 The set of commands, and the syntax and behavior of those commands, that an
 SA_DiceBot supports depends on its currently set parser behavior mode (and, in 
 some cases, also on the currently set formatter behavior mode). (Read more 
 about parser behavior modes in SA_DiceParser.h, and about formatter behavior 
 modes in SA_DiceFormatter.h.)
 
 Below is a list of available parser modes, along with the commands supported in
 each mode. (See section II for a list of commands that are supported in all
 parser modes.)
 
 NOTE: Commands are not case-sensitive; e.g., 'roll', 'ROLL', and 'rOLl' all 
 work equally well.
 
 1. DEFAULT mode
 
 "Default" mode is an alias for whatever default behavior is currently set for 
 new SA_DiceParser instances. (The "default default" behavior for the current 
 implementation is "legacy".)
 
 2. LEGACY mode
 
 "Legacy" mode (mostly) emulates DiceBot by Sabin (and Dawn by xthemage before 
 it). The following commands are available in legacy mode.
 
	1. ROLL command.
	
	Takes 1 or more whitespace-delimited roll strings as parameters. The roll 
	command is executed once for every parameter, and each execution generates 
	a separate result string. One reply message is sent for each result string
	(or, if the simple formatter is being used, the results may optionally be
	collapsed into a single reply message).
 
	Each roll string may optionally be suffixed with with a (configurable) 
	delimiter character (such as ';'), which may be followed with an arbitrary
	text label (which may not contain whitespace, however). That label may then
	be included in the result string (depending on the selected formatter 
	behavior mode and other formatter settings).
 
	The body of the roll string (up to the label delimiter, if any) is simply 
	parsed and evaluated.
 
	EXAMPLES (assuming legacy formatter behavior):
 
	   Obormot: !roll 1d20
	SA_DiceBot:	1d20 < 14 = 14 > = 14
	   Obormot: .roll 2+4-5
	SA_DiceBot: 2 + 4 - 5 = 1
	   Obormot: /roll 2d4 1d20+19 4d10
	SA_DiceBot: 2d4 < 3 1 = 4 > = 4
	SA_DiceBot: 1d20 < 5 = 5 > + 19 = 24
	SA_DiceBot: 4d10 < 2 2 1 2 = 7 > = 7
	   Obormot: !roll 1d20+4;fort_save
	SA_DiceBot: (fort_save) 1d20 < 8 = 8 > + 4 = 12
	   Obormot: SA_DiceBot: 1d8+6;longsword 1d6+3;shortsword
	SA_DiceBot: (longsword) 1d8 < 4 = 4 > + 6 = 10
	SA_DiceBot: (shortsword) 1d6 < 2 = 2 > + 3 = 5
 
	2. TRY command.
 
	Takes 1 or more whitespace-delimited roll strings. Prepends "1d20+" to each
	roll string, and otherwise behaves in the same way as the ROLL command.
 
	3. CHAR command.
 
 II. OTHER COMMANDS
 
 III. CONFIGURATION
 */
/****************************************/
#pragma mark SA_DiceBot class declaration
/****************************************/

@interface SA_DiceBot : SA_Bot

/************************/
#pragma mark - Properties
/************************/

@property (strong) SA_CommandResponder *botCommandresponder;
@property (strong) SA_CommandResponder *legacyCommandResponder;

@property (strong) SA_CommandResponder *currentCommandResponder;

@property (copy) NSString *commandDesignatorCharacters;

/****************************/
#pragma mark - Public methods
/****************************/

- (void)message:(NSString *)messageBody withInfo:(NSDictionary *)messageInfo;

/****************************/
#pragma mark - Helper methods
/****************************/

- (NSArray <NSDictionary *> *)repliesForCommandString:(NSString *)commandString messageInfo:(NSDictionary *)messageInfo byName:(BOOL)byName;

- (void)loadDefaultCommandResponders;

@end
