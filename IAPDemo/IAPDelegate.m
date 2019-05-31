//
//  IAPDelegate.m
//  IAPDemo
//
//  Created by shupeng on 2019/5/15.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "IAPDelegate.h"
#import <IAP/IAP.h>
#import <IAP/LocalReceiptValidator.h>
#import <QMUIKit/QMUIKit.h>
#import <UICKeyChainStore/UICKeyChainStore.h>

@interface IAPDelegate () <IAPResultDelegate>
@property(nonatomic, strong) IAP *iap;
@property(nonatomic, strong) NSTimer *timeout;
@end

@implementation IAPDelegate

+ (instancetype)shared {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.iap = [[IAP alloc] initWithValidator:[[LocalReceiptValidator alloc] init] delegate:self];
        [self fetchAllProducts];
        [self.iap checkReceiptForAllPurchasedProductExceptConsumable];
    }
    return self;
}

- (void)fetchAllProducts {
    [self.iap getProductsInfo:[NSSet setWithArray:@[@"com.shupeng.IAPDemo_yongjiuxing108", @"com.shupeng.IAPDemo_vip",@"com.shupeng.IAPDemo_svip"]] success:nil failed:nil];
}

- (void)buy:(NSString *)productIdentifier {
    NSError *error = [self.iap makePaymentWithProductIdentifier:productIdentifier];
    if (error) {
        if (error.code == IAPErrorCanNotFindProduct) {
            [QMUITips showError:@"未找到商品, 请稍后重试"];
            [self fetchAllProducts];
        } else if (error.code == IAPErrorCanNotPay) {
            [QMUITips showError:@"当前设备不允许购买"];
            [self fetchAllProducts];
        } else if (error.code == IAPErrorJailbreakPayNotAllowed) {
            [QMUITips showError:@"越狱设备不允许购买"];
            [self fetchAllProducts];
        } else {
            [QMUITips showError:[error localizedDescription]];
        }
    } else {
        [QMUITips showLoading:@"正在购买" inView:DefaultTipsParentView];
        self.timeout = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(timeoutFired:) userInfo:nil repeats:false];
    }
}

- (void)timerFIred:(id)timer {
    [QMUITips hideAllTipsInView:DefaultTipsParentView];
}

- (void)restore {
    [QMUITips showLoading:@"正在恢复购买" inView:DefaultTipsParentView];
    [self.iap restoreAllPurchasedProductExceptConsumable];
}

- (void)check {
    [self.iap checkReceiptForAllPurchasedProductExceptConsumable];
}

- (IAPProductType)typeForProduct:(NSString *)productIdentifier {
    if ([productIdentifier isEqualToString:@"com.shupeng.IAPDemo_yongjiuxing108"]) {
        return IAPProductTypeNonConsumable;
    } else {
        return IAPProductTypeAutoRenewSubscription;
    }
}

- (void)paidSuccessWithProductIdentifier:(NSString *)productIdentifier transaction:(SKPaymentTransaction *)transaction {
    [self.timeout invalidate];
    self.timeout = nil;
    
    [QMUITips hideAllTipsInView:DefaultTipsParentView];
    if ([self typeForProduct:productIdentifier] == IAPProductTypeAutoRenewSubscription ) {
        SKProduct *product = [self.iap productForIdentifier:productIdentifier];
        [QMUITips showSucceed:[NSString stringWithFormat:@"您已成功购买/续订%@", product.localizedTitle]];
    } else {
        [QMUITips showSucceed:[NSString stringWithFormat:@"购买成功! %@", productIdentifier]];

    }
    
    [self addProduct:productIdentifier];

    [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateSuccess object:nil userInfo:@{@"obj": productIdentifier}];
}

- (void)paidFailedWithProductIdentifier:(NSString *)productIdentifier transaction:(SKPaymentTransaction *)transaction error:(NSError *)error {
    [self.timeout invalidate];
    self.timeout = nil;
    
    [QMUITips hideAllTipsInView:DefaultTipsParentView];
    // 真实环境下, 不需要显示toast
    [QMUITips showError:[NSString stringWithFormat:@"购买失败! %@", productIdentifier]];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateFailed object:nil userInfo:@{@"obj": productIdentifier}];
}

- (void)restoredValidProductIdentifiers:(NSSet<NSString *> *)productIdentifiers error:(NSError *)error {
    [self.timeout invalidate];
    self.timeout = nil;
    
    [QMUITips hideAllTipsInView:DefaultTipsParentView];

    // 恢复 或者 验证失败
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateRestored object:nil userInfo:@{@"error": error}];
        [QMUITips showError:[NSString stringWithFormat:@"恢复失败 :%@", [error localizedDescription]]];
    }
    // 恢复并且验证成功
    else {
        [QMUITips showSucceed:[NSString stringWithFormat:@"恢复所有有效商品! %@", [[productIdentifiers allObjects] componentsJoinedByString:@"-"]]];

        [self saveAllProducts:productIdentifiers];
        [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateRestored object:nil userInfo:@{@"obj": productIdentifiers}];
    }
}

- (void)checkedValidProductIdentifiers:(NSSet<NSString *> *)productIdentifiers error:(NSError *)error {
    [QMUITips hideAllTipsInView:DefaultTipsParentView];
    // 真实环境下, 不需要显示toast

    // 验证失败
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateChecked object:nil userInfo:@{@"error": error}];
        [QMUITips showError:[NSString stringWithFormat:@"验证失败 %@", [[productIdentifiers allObjects] componentsJoinedByString:@"-"]]];
        
    }
    // 恢复并且验证成功
    else {
        [QMUITips showSucceed:[NSString stringWithFormat:@"已验证所有有效商品! %@", [[productIdentifiers allObjects] componentsJoinedByString:@"-"]]];
        [self saveAllProducts:productIdentifiers];
        [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateChecked object:nil userInfo:@{@"obj": productIdentifiers}];
    }
}

- (NSSet *)allProductsInKeychain {
    return [NSSet setWithArray:[[[UICKeyChainStore keyChainStoreWithService:KeyChainIAPService] stringForKey:KeyChainAllProductKey] componentsSeparatedByString:@"----"]];
}

- (void)saveAllProducts:(NSSet *)productIdentifiers {
    [[UICKeyChainStore keyChainStoreWithService:KeyChainIAPService] setString:[[productIdentifiers allObjects] componentsJoinedByString:@"----"] forKey:KeyChainAllProductKey];
}

- (void)addProduct:(NSString *)product {
    NSMutableSet *set = [NSMutableSet setWithSet:[self allProductsInKeychain]];
    [set addObject:product];
    [self saveAllProducts:set];
}
@end
