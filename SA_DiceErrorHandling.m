//
//  SA_DiceErrorHandling.m
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.

#import "SA_DiceErrorHandling.h"

#import "SA_DiceExpressionStringConstants.h"

void addErrorToExpression (NSString *error, NSMutableDictionary *expression)
{
	if(error == nil || expression == nil)
	{
		return;
	}
	
	if(expression[SA_DB_ERRORS] == nil)
	{
		expression[SA_DB_ERRORS] = [NSMutableArray <NSString *> arrayWithObjects:error, nil];
	}
	else
	{
		[expression[SA_DB_ERRORS] addObject:error];
	}
}

// Top-level errors only (i.e. the expression tree is not traversed in search
// of deeper errors).
void addErrorsFromExpressionToExpression (NSDictionary *sourceExpression, NSMutableDictionary *targetExpression)
{
	if(sourceExpression == nil || targetExpression == nil)
	{
		return;
	}
	
	if(sourceExpression[SA_DB_ERRORS] == nil || [sourceExpression[SA_DB_ERRORS] count] == 0)
	{
		// Do absolutely nothing; no errors to add.
	}
	else if(targetExpression[SA_DB_ERRORS] == nil)
	{
		targetExpression[SA_DB_ERRORS] = [NSMutableArray <NSString *> arrayWithArray:sourceExpression[SA_DB_ERRORS]];
	}
	else
	{
		[targetExpression[SA_DB_ERRORS] addObjectsFromArray:sourceExpression[SA_DB_ERRORS]];
	}
}

NSArray <NSString *> *getErrorsForExpression (NSDictionary *expression)
{
	return ([expression[SA_DB_ERRORS] count] > 0) ? expression[SA_DB_ERRORS] : nil;
}
