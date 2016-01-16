//
//  SA_DiceBag.h
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.

#import <Foundation/Foundation.h>

/****************************************/
#pragma mark SA_DiceBag class declaration
/****************************************/

@interface SA_DiceBag : NSObject

/****************************/
#pragma mark - Public methods
/****************************/

- (unsigned long long)biggestPossibleDieSize;

- (unsigned long long)rollDie:(unsigned long long)die;
- (NSArray *)rollNumber:(NSNumber *)number ofDice:(unsigned long long)die;

@end
