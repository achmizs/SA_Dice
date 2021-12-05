//
//  SA_DiceBag.h
//
//  Copyright 2016-2021 Said Achmiz.
//  See LICENSE and README.md for more info.

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, SA_DiceRollingOptions) {
	SA_DiceRollingExplodingDice = 1 << 1
};

/****************************************/
#pragma mark SA_DiceBag class declaration
/****************************************/

@interface SA_DiceBag : NSObject

/****************************/
#pragma mark - Public methods
/****************************/

-(NSUInteger) biggestPossibleDieSize;

// -------------
// Regular dice.
// -------------

-(NSUInteger) rollDie:(NSUInteger)dieSize;

-(NSArray <NSNumber *> *) rollNumber:(NSUInteger)number
							  ofDice:(NSUInteger)dieSize;

-(NSArray <NSNumber *> *) rollNumber:(NSUInteger)number
							  ofDice:(NSUInteger)dieSize
						 withOptions:(SA_DiceRollingOptions)options;

// -----------
// Fudge dice.
// -----------

-(char) rollFudgeDie;

-(NSArray <NSNumber *> *) rollFudgeDice:(NSUInteger)number;

@end
