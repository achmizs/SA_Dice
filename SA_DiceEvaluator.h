//
//  SA_DiceEvaluator.h
//
//  Copyright 2016-2021 Said Achmiz.
//  See LICENSE and README.md for more info.

#import <Foundation/Foundation.h>

@class SA_DiceBag;
@class SA_DiceExpression;

/************************************************/
#pragma mark SA_DiceEvaluator class declaration
/************************************************/

@interface SA_DiceEvaluator : NSObject

/************************/
#pragma mark - Properties
/************************/

@property NSUInteger maxDieCount;
@property NSUInteger maxDieSize;

/****************************/
#pragma mark - Public methods
/****************************/

-(SA_DiceExpression *) resultOfExpression:(SA_DiceExpression *)expression;

@end
