//
//  SA_DiceEvaluator.h
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.

#import <Foundation/Foundation.h>

@class SA_DiceBag;

/************************************************/
#pragma mark SA_DiceEvaluator class declaration
/************************************************/

@interface SA_DiceEvaluator : NSObject

/************************/
#pragma mark - Properties
/************************/

@property NSInteger maxDieCount;
@property NSInteger maxDieSize;

@property (strong) SA_DiceBag *diceBag;

/****************************/
#pragma mark - Public methods
/****************************/

- (NSMutableDictionary *)resultOfExpression:(NSDictionary *)expression;

@end
