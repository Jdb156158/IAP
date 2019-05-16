//
//  ProductConsumableValidator.m
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "ProductConsumableValidator.h"

@implementation ProductConsumableValidator
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static ProductConsumableValidator *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (BOOL)validateTransaction:(SKPaymentTransaction *)transaction receiptJson:(NSDictionary *)receiptJson {
    if ([receiptJson[@"status"] integerValue] != 0) {
        return false;
    }
    
    NSArray *allPurchase = receiptJson[@"receipt"][@"in_app"];
    
    __block BOOL isTrue = false;
    [allPurchase enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"transaction_id"] isEqualToString:transaction.transactionIdentifier]) {
            isTrue = true;
            *stop = true;
        }
    }];
    
    return isTrue;
    
}
@end
