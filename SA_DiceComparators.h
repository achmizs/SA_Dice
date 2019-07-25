//
//  SA_DiceComparators.h
//  DieBot Mobile
//
//  Created by Sandy Achmiz on 5/4/16.
//
//

#import <Foundation/Foundation.h>

#ifndef SA_DiceComparators_h
#define SA_DiceComparators_h

NSComparisonResult compareEvaluatedExpressionsByResult(NSDictionary* expression1,
													   NSDictionary *expression2);
NSComparisonResult compareEvaluatedExpressionsByAttemptBonus(NSDictionary* expression1,
															 NSDictionary *expression2);

#endif /* SA_DiceComparators_h */
