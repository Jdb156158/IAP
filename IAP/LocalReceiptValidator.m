//
//  LocalReceiptValidator.m
//  IAP
//
//  Created by shupeng on 2019/5/15.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "LocalReceiptValidator.h"

#ifdef DEBUG
#define LRVLog(...) NSLog(@"LocalReceiptValidator: %@", [NSString stringWithFormat:__VA_ARGS__]);
#else
#define LRVLog(...)
#endif

NSString * const ReceiptValidatorErrorDomain = @"ReceiptValidatorErrorDomain";


@implementation LocalReceiptValidator

- (NSError *)validateReceiptInfo:(RMAppReceipt *)receipt {
    if (receipt == nil) {
        NSError *error = [NSError errorWithDomain:ReceiptValidatorErrorDomain code:ReceiptValidatorReceiptIsNull userInfo:@{NSLocalizedDescriptionKey: @"recepit is null!"}];
        return error;
    }
    
    if (![receipt.bundleIdentifier isEqualToString:[[NSBundle mainBundle] bundleIdentifier]]) {
        NSError *error = [NSError errorWithDomain:ReceiptValidatorErrorDomain code:ReceiptValidatorBundleIdentifierNotEqual userInfo:@{NSLocalizedDescriptionKey: @"bundle identifier not equal!"}];
        return error;
    }
    
    if (![receipt.appVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]) {
        NSError *error = [NSError errorWithDomain:ReceiptValidatorErrorDomain code:ReceiptValidatorBundleVersionNotEqual userInfo:@{NSLocalizedDescriptionKey: @"recepit bundle version is not equal!"}];
        return error;
    }
    
    if (![receipt verifyReceiptHash]) {
        NSError *error = [NSError errorWithDomain:ReceiptValidatorErrorDomain code:ReceiptValidatorHashNotEqual userInfo:@{NSLocalizedDescriptionKey: @"recepit hash is not equal!"}];
        return error;
    }
    
    return nil;
}

- (void)validateTransaction:(SKPaymentTransaction *)transaction withReceipt:(RMAppReceipt *)receipt complete:(void (^)(NSError *error))complete {
    NSError *error = [self validateReceiptInfo:receipt];
    if (error) {
        complete(error);
        return;
    }
    
    if (![receipt containsInAppPurchaseOfProductIdentifier:transaction.payment.productIdentifier]) {
        NSError *error = [NSError errorWithDomain:ReceiptValidatorErrorDomain code:ReceiptValidatorProductIsNotInReceipt userInfo:@{NSLocalizedDescriptionKey: @"product is not in receipt!"}];
        complete(error);
        return;
    }
    
    complete(nil);
}

- (void)validateAllProductInReceipt:(RMAppReceipt *)receipt complete:(void (^)(NSSet<NSString *> *, NSError *))complete {
    NSError *error = [self validateReceiptInfo:receipt];
    if (error) {
        complete(nil, error);
        return;
    }
    
    NSMutableSet *set = [NSMutableSet set];
    NSMutableDictionary *productExpireDateDic = [NSMutableDictionary dictionary];
    // 找出所有商品
    // 含有过期日期的为自动订阅的商品. 没有过期日期的可以时消耗类、非消耗类 和 非自动续订的订阅类
    [receipt.inAppPurchases enumerateObjectsUsingBlock:^(RMAppReceiptIAP  * _Nonnull inAPPReceipt, NSUInteger idx, BOOL * _Nonnull stop) {
        if (inAPPReceipt.subscriptionExpirationDate == nil) {
            [set addObject:inAPPReceipt.productIdentifier];
        } else {
            // 找到同类商品中时间最新的一个
            NSDate *findDate = productExpireDateDic[inAPPReceipt.productIdentifier];
            if (findDate == nil) {
                productExpireDateDic[inAPPReceipt.productIdentifier] = inAPPReceipt.subscriptionExpirationDate;
            } else {
                NSDate *newDate = inAPPReceipt.subscriptionExpirationDate;
                if (newDate.timeIntervalSince1970 > findDate.timeIntervalSince1970) {
                    productExpireDateDic[inAPPReceipt.productIdentifier] = newDate;
                }
            }
        }
    }];
    
    // 遍历每类商品的最新一个的过期日期是否过期
    [productExpireDateDic enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSDate *  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.timeIntervalSince1970 > [NSDate date].timeIntervalSince1970) {
            LRVLog(@"验证自动订阅类: %@, 过期日期: %@", key, obj);
            [set addObject:key];
        }
    }];
    
    complete(set, nil);
}


@end
