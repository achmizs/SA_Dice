//
//  SA_DiceErrorHandling.h
//  RPGBot
//
//  Created by Sandy Achmiz on 1/11/16.
//
//

#ifndef SA_DiceErrorHandling_h
#define SA_DiceErrorHandling_h

#import <Foundation/Foundation.h>

void addErrorToExpression (NSString *error, NSMutableDictionary *expression);
void addErrorsFromExpressionToExpression (NSDictionary *sourceExpression, NSMutableDictionary *targetExpression);
NSArray <NSString *> *getErrorsForExpression (NSDictionary *expression);

#endif /* SA_DiceErrorHandling_h */
