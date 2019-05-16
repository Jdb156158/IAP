//
//  LocalReceiptValidator.h
//  IAP
//
//  Created by shupeng on 2019/5/15.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAP.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const ReceiptValidatorErrorDomain;

NS_ERROR_ENUM(ReceiptValidatorErrorDomain)
{
    ReceiptValidatorReceiptIsNull = 1,
    ReceiptValidatorBundleIdentifierNotEqual,
    ReceiptValidatorBundleVersionNotEqual,
    ReceiptValidatorHashNotEqual,
    ReceiptValidatorProductIdentifierNotEqual,
    ReceiptValidatorProductIsNotInReceipt
};

@interface LocalReceiptValidator : NSObject <ReceiptValidatorProtocol>

@end

NS_ASSUME_NONNULL_END
