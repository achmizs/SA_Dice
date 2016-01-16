//
//  SA_DiceBag.m
//  RPGBot
//
//  Created by Sandy Achmiz on 12/30/15.
//
//

#import "SA_DiceBag.h"

/*******************************************/
#pragma mark SA_DiceBag class implementation
/*******************************************/

@implementation SA_DiceBag

/****************************/
#pragma mark - Public methods
/****************************/

- (unsigned long long)biggestPossibleDieSize
{
	return UINT32_MAX;
}

- (unsigned long long)rollDie:(unsigned long long)dieSize
{
	if(dieSize > UINT32_MAX)
	{
		return -1;
	}

	return (unsigned long long) arc4random_uniform((u_int32_t) dieSize) + 1;
}

- (NSArray *)rollNumber:(NSNumber *)number ofDice:(unsigned long long)dieSize
{
	if(dieSize > UINT32_MAX)
	{
		return nil;
	}
	
	unsigned long long numRolls = number.unsignedLongLongValue;
	
	NSMutableArray *rollsArray = [NSMutableArray arrayWithCapacity:numRolls];
	for(unsigned long long i = 0; i < numRolls; i++)
	{
		rollsArray[i] = @((unsigned long long) arc4random_uniform((u_int32_t) dieSize) + 1);
	}
	
	return rollsArray;
}

@end
