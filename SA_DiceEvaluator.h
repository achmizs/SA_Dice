//
//  SA_DiceEvaluator.h
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.

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
