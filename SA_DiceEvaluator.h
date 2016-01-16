//
//  SA_DiceEvaluator.h
//  RPGBot
//
//  Created by Sandy Achmiz on 1/2/16.
//
//

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
