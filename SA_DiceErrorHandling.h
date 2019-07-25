//
//  SA_DiceErrorHandling.h
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.

#import <Foundation/Foundation.h>

@interface SA_DiceErrorHandler : NSObject

+(void) addError:(NSString *)error
	toExpression:(NSMutableDictionary *)expression;

+(void) addErrorsFromExpression:(NSDictionary *)sourceExpression
				   toExpression:(NSMutableDictionary *)targetExpression;

+(NSArray <NSString *> *) errorsForExpression:(NSDictionary *)expression;

@end
