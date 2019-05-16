//
//  TransactionValidator.h
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TransactionValidator <NSObject>

- (void)validateConsumableTransaction:(SKPaymentTransaction *)transaction complete:(void (^)(BOOL isTrue))complete failed:(void (^)(NSError *error))failed;

- (void)validateNonConsumableTransaction:(SKPaymentTransaction *)transaction complete:(void (^)(BOOL isTrue))complete failed:(void (^)(NSError *error))failed;

- (void)validateAutoRenewSubscriptionTransaction:(SKPaymentTransaction *)transaction complete:(void (^)(BOOL isTrue))complete failed:(void (^)(NSError *error))failed;

- (void)validateNonAutoRenewSubscriptionTransaction:(SKPaymentTransaction *)transaction complete:(void (^)(BOOL isTrue))complete failed:(void (^)(NSError *error))failed;
@end

NS_ASSUME_NONNULL_END
