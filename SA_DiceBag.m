//
//  SA_DiceBag.m
//
//  Copyright 2016-2021 Said Achmiz.
//  See LICENSE and README.md for more info.

#import "SA_DiceBag.h"
#import <GameplayKit/GameplayKit.h>

/*******************************************/
#pragma mark SA_DiceBag class implementation
/*******************************************/

@implementation SA_DiceBag {
//	GKRandomSource *_randomSource;

	NSMutableDictionary <NSNumber *, GKRandomDistribution *> *_dice;
}

-(instancetype) init {
	if (!(self = [super init]))
		return nil;

//	_randomSource = [GKMersenneTwisterRandomSource new];

	_dice = [NSMutableDictionary dictionary];

	return self;
}

/****************************/
#pragma mark - Public methods
/****************************/

-(NSUInteger) biggestPossibleDieSize {
	return NSUIntegerMax;
}

-(NSUInteger) rollDie:(NSUInteger)dieSize {
//	return [_randomSource nextIntWithUpperBound:dieSize] + 1;
	return [[self dieOfSize:dieSize] nextInt];
}

-(NSArray <NSNumber *> *) rollNumber:(NSUInteger)number
							  ofDice:(NSUInteger)dieSize {
	return [self rollNumber:number
					 ofDice:dieSize
				withOptions:0];
}

-(NSArray <NSNumber *> *) rollNumber:(NSUInteger)number
							  ofDice:(NSUInteger)dieSize
						 withOptions:(SA_DiceRollingOptions)options {
	NSMutableArray *rollsArray = [NSMutableArray arrayWithCapacity:number];

	for (NSUInteger i = 0; i < number; i++) {
		NSUInteger dieRoll;
		do {
			dieRoll = [self rollDie:dieSize];
			[rollsArray addObject:@(dieRoll)];
		} while (   options & SA_DiceRollingExplodingDice
				 && dieSize > 1
				 && dieRoll == dieSize);
	}

	return rollsArray;
}

-(char) rollFudgeDie {
	NSInteger d3roll = [self rollDie:3];
	return (char) (d3roll - 2);
}

-(NSArray <NSNumber *> *) rollFudgeDice:(NSUInteger)number {
	NSMutableArray *rollsArray = [NSMutableArray arrayWithCapacity:number];

	for (NSUInteger i = 0; i < number; i++) {
		[rollsArray addObject:@([self rollFudgeDie])];
	}

	return rollsArray;
}

/****************************/
#pragma mark - Helper methods
/****************************/

-(GKRandomDistribution *) dieOfSize:(NSUInteger) dieSize {
	if (_dice[@(dieSize)] == nil)
		_dice[@(dieSize)] = [[GKRandomDistribution alloc] initWithRandomSource:[GKMersenneTwisterRandomSource new]
																   lowestValue:1
																  highestValue:dieSize];

	return _dice[@(dieSize)];
}

@end
