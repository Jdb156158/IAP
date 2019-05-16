//
//  LocalValidator.h
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransactionValidator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ProductValidator <NSObject>

- (BOOL)validateTransaction:(SKPaymentTransaction *)transaction receiptJson:(NSDictionary *)receiptJson;

@end

FOUNDATION_EXPORT NSString * const LocalValidatorErrorDomain;

NS_ERROR_ENUM(LocalValidatorErrorDomain)
{
    LocalValidatorErrorNoReceipt = 1,
    LocalValidatorErrorRequestDataError,
    LocalValidatorErrorDecodeJsonError
    
};

@interface LocalValidator : NSObject <TransactionValidator>

- (id)initWithPassword:(NSString *)password;
@end

NS_ASSUME_NONNULL_END
