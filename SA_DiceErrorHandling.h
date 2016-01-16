//
//  SA_DiceErrorHandling.h
//
//	Copyright (c) 2016 Said Achmiz.
//
//	This software is licensed under the MIT license.
//	See the file "LICENSE" for more information.

#ifndef SA_DiceErrorHandling_h
#define SA_DiceErrorHandling_h

#import <Foundation/Foundation.h>

void addErrorToExpression (NSString *error, NSMutableDictionary *expression);
void addErrorsFromExpressionToExpression (NSDictionary *sourceExpression, NSMutableDictionary *targetExpression);
NSArray <NSString *> *getErrorsForExpression (NSDictionary *expression);

#endif /* SA_DiceErrorHandling_h */
