//
//  IAP.h
//  IAP
//
//  Created by shupeng on 2019/5/20.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, IAPProductType) {
    IAPProductTypeConsumable __attribute__((deprecated)), // 消耗类 暂不支持
    IAPProductTypeNonConsumable, // 非消耗类
    IAPProductTypeAutoRenewSubscription, // 自动续订 订阅类
    IAPProductTypeNonAutoRenewSubscription __attribute__((deprecated)) // 非自动续订 订阅类 暂不支持
};

typedef void (^IAPSuccessPaymentCallback)(void);
typedef void (^IAPRestorePaymentCallback)(void);
typedef void (^IAPCheckPaymentCallback)(void);

@protocol IAPDelegate <NSObject>

#pragma mark - 输入
// 获取所有的商品
- (NSSet *)allProductIdentifiers;

- (IAPProductType)typeForProduct:(NSString *)productIdentifier;

- (void)addProductIdentifier:(NSString *)productIdentifier forSuccessPaymentCallback:(void (^)(void))callback;

- (void)addProductIdentifiers:(NSSet *)productIdentifiers forSuccessPaymentCallback:(void (^)(void))callback;

- (void)addProductIdentifier:(NSString *)productIdentifier forRestorePaymentCallback:(void (^)(void))callback;

- (void)addProductIdentifiers:(NSSet *)productIdentifiers forRestorePaymentCallback:(void (^)(void))callback;


#pragma mark - 回调
@end

@protocol IAPPersistence <NSObject>

- (void)persistenceTransaction:(NSString *)transactionID withReceipt:(NSString *)receipt;

@end

@interface IAP2 : NSObject


@end
