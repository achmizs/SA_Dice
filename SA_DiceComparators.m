//
//  SA_DiceComparators.m
//  DieBot Mobile
//
//  Created by Sandy Achmiz on 5/4/16.
//
//

#import "SA_DiceComparators.h"

#import "SA_DiceExpressionStringConstants.h"

NSComparisonResult compareEvaluatedExpressionsByResult(NSDictionary* expression1, NSDictionary *expression2)
{
	if([expression1[SA_DB_RESULT] integerValue] < [expression2[SA_DB_RESULT] integerValue])
	{
		return NSOrderedAscending;
	}
	else if([expression1[SA_DB_RESULT] integerValue] > [expression2[SA_DB_RESULT] integerValue])
	{
		return NSOrderedDescending;
	}
	else
	{
		return NSOrderedSame;
	}
}

NSComparisonResult compareEvaluatedExpressionsByAttemptBonus(NSDictionary* expression1, NSDictionary *expression2)
{
	if([expression1[SA_DB_OPERAND_RIGHT][SA_DB_RESULT] integerValue] < [expression2[SA_DB_OPERAND_RIGHT][SA_DB_RESULT] integerValue])
	{
		return NSOrderedAscending;
	}
	else if([expression1[SA_DB_OPERAND_RIGHT][SA_DB_RESULT] integerValue] > [expression2[SA_DB_OPERAND_RIGHT][SA_DB_RESULT] integerValue])
	{
		return NSOrderedDescending;
	}
	else
	{
		return NSOrderedSame;
	}				 
}
