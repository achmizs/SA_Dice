//
//  SA_DiceBag.h
//  RPGBot
//
//  Created by Sandy Achmiz on 12/30/15.
//
//

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
