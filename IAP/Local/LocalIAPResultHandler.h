//
//  LocalIAPResultHandler.h
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAP.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ProductType) {
    ProductTypeUnknown = 1,
    ProductTypeConsumable,
    ProductTypeNonConsumable,
    ProductTypeAutoRenewSubscription,
    ProductTypeNonAutoRenewSubscription
};

@protocol ProductTypeDelegate <NSObject>

- (ProductType)typeForProductIdentifier:(NSString *)productIdentifier;
@end

@protocol DeleiverDelegate <NSObject>
@optional
- (void)deleiverConsumableProduct:(NSString *)productIdentifier fromTransaction:(SKPaymentTransaction *)transaction;
- (void)activeNonConsumableProduct:(NSString *)productIdentifier fromTransaction:(SKPaymentTransaction *)transaction;
- (void)deactiveNonConsumableProduct:(NSString *)productIdentifier fromTransaction:(SKPaymentTransaction *)transaction;
- (void)activeAutoRenewSubScriptionProduct:(NSString *)productIdentifier fromTransaction:(SKPaymentTransaction *)transaction;
- (void)deactiveAutoRenewSubScriptionProduct:(NSString *)productIdentifier fromTransaction:(SKPaymentTransaction *)transaction;
- (void)activeNonAutoRenewSubScriptionProduct:(NSString *)productIdentifier fromTransaction:(SKPaymentTransaction *)transaction;
- (void)deactiveNonAutoRenewSubScriptionProduct:(NSString *)productIdentifier fromTransaction:(SKPaymentTransaction *)transaction;
@end

@interface LocalIAPResultHandler : NSObject <IAPResultDelegate>
+ (instancetype)sharedInstance;
@property(nonatomic, weak) id<DeleiverDelegate> delegate;
@property(nonatomic, weak) id<ProductTypeDelegate> productDelegate;

@end

NS_ASSUME_NONNULL_END
