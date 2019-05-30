//
//  IAPDelegate.m
//  IAPDemo
//
//  Created by shupeng on 2019/5/15.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "IAPDelegate.h"
#import <IAP/LocalReceiptValidator.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "LoadingUtil.h"
#import <BlocksKit/BlocksKit.h>
#import "HudManager.h"

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
        [self check];
    }
    return self;
}

- (void)fetchAllProducts {
    [self.iap getProductsInfo:[NSSet setWithArray:@[SUBSCIBE_PRODUCT_ID_YEAR, SUBSCIBE_PRODUCT_ID_HALF_YEAR, SUBSCIBE_PRODUCT_ID_QUARTER, SUBSCIBE_PRODUCT_ID_MONTH]] success:nil failed:nil];
}

- (void)buy:(NSString *)productIdentifier {
    NSError *error = [self.iap makePaymentWithProductIdentifier:productIdentifier];
    if (error) {
        if (error.code == IAPErrorCanNotFindProduct) {

            [HudManager showWord:@"未找到商品, 请稍后重试"];
            [self fetchAllProducts];
        } else if (error.code == IAPErrorCanNotPay) {
            
            [HudManager showWord:@"当前设备不允许购买"];
            [self fetchAllProducts];
        } else if (error.code == IAPErrorJailbreakPayNotAllowed) {
            [HudManager showWord:@"越狱设备不允许购买"];
            [self fetchAllProducts];
        } else {
            [HudManager showWord:[error localizedDescription]];
        }
    } else {
        [LoadingUtil showGenerLoading:KWINDOW animated:YES msg:@"Loading..."];
        self.timeout = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(timeoutFired:) userInfo:nil repeats:false];
    }
}

- (void)timeoutFired:(id)timer {
    [LoadingUtil hide:KWINDOW animated:true];
}

- (void)restore {
    [LoadingUtil showGenerLoading:KWINDOW animated:YES msg:@"Loading..."];
    [self.iap restoreAllPurchasedProductExceptConsumable];
}

- (void)check {
    [self.iap checkReceiptForAllPurchasedProductExceptConsumable];
}

- (IAPProductType)typeForProduct:(NSString *)productIdentifier {
    return IAPProductTypeAutoRenewSubscription;
}

- (void)paidSuccessWithProductIdentifier:(NSString *)productIdentifier transaction:(SKPaymentTransaction *)transaction {
    [self hideLoadingIfNeeded];
    
    SKProduct *product = [self.iap productForIdentifier:productIdentifier];
    if ([self typeForProduct:productIdentifier] == IAPProductTypeAutoRenewSubscription ) {
        // 此时， 系统立即通知续订成功。 但是还没初始化所有商品。
        //        [HudManager showWord:[NSString stringWithFormat:@"您已成功购买/续订 %@", product.localizedTitle]];
        [HudManager showWord:[NSString stringWithFormat:@"您已成功购买"]];
    } else {
        [HudManager showWord:[NSString stringWithFormat:@"购买成功! %@", product.localizedTitle]];
    }
    
    [self addProduct:productIdentifier];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateSuccess object:nil userInfo:@{@"obj": productIdentifier}];
}

- (void)paidFailedWithProductIdentifier:(NSString *)productIdentifier transaction:(SKPaymentTransaction *)transaction error:(NSError *)error {
    [self hideLoadingIfNeeded];
    
    // 真实环境下, 不需要显示toast
    //    [QMUITips showError:[NSString stringWithFormat:@"购买失败! %@", productIdentifier]];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateFailed object:nil userInfo:@{@"obj": productIdentifier}];
}

- (void)restoredValidProductIdentifiers:(NSSet<NSString *> *)productIdentifiers error:(NSError *)error {
    [self hideLoadingIfNeeded];
    
    if (error) {
        if (error.code == IAPErrorCanNotFindReceipt) {
            [HudManager showWord:@"恢复失败, 请稍后重试"];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateRestored object:nil userInfo:@{@"error": error}];
    }
    // 成功过后要对所有商品进行保存， 无论是否为空
    else {
        if (productIdentifiers.count > 0) {
            [HudManager showWord:@"恢复成功!"];
        } else {
            [HudManager showWord:@"没有可恢复的商品"];
        }
        
        [self saveAllProducts:productIdentifiers];
        [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateRestored object:nil userInfo:@{@"obj": productIdentifiers}];
    }
}

- (void)checkedValidProductIdentifiers:(NSSet<NSString *> *)productIdentifiers error:(NSError *)error {
    [LoadingUtil hide:KWINDOW animated:true];
    
    // 真实环境下, 不需要显示toast
    //    [QMUITips showSucceed:[NSString stringWithFormat:@"已验证所有有效商品! %@", [[productIdentifiers allObjects] componentsJoinedByString:@"-"]]];
    
    
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateChecked object:nil userInfo:@{@"error": error}];
    }
    // 成功过后要对所有商品进行保存， 无论是否为空
    else {
        [self saveAllProducts:productIdentifiers];
        [[NSNotificationCenter defaultCenter] postNotificationName:kIAPDelegateChecked object:nil userInfo:@{@"obj": productIdentifiers}];
    }
}

- (void)hideLoadingIfNeeded {
    [self.timeout invalidate];
    self.timeout = nil;
    
    [LoadingUtil hide:KWINDOW animated:true];
}

- (NSSet *)allProductsInKeychain {
    NSString *allProducts = [[UICKeyChainStore keyChainStoreWithService:KeyChainIAPService] stringForKey:KeyChainAllProductKey];
    if (allProducts.length > 0) {
        NSArray *array = [allProducts componentsSeparatedByString:@"----"];
        NSSet *set = [NSSet setWithArray:array];
        return set;
    } else {
        return [NSSet set];
    }
}

- (void)saveAllProducts:(NSSet *)productIdentifiers {
    [[UICKeyChainStore keyChainStoreWithService:KeyChainIAPService] setString:[[productIdentifiers allObjects] componentsJoinedByString:@"----"] forKey:KeyChainAllProductKey];
    
    if ([productIdentifiers containsObject:SUBSCIBE_PRODUCT_ID_YEAR]
        || [productIdentifiers containsObject:SUBSCIBE_PRODUCT_ID_HALF_YEAR]
        || [productIdentifiers containsObject:SUBSCIBE_PRODUCT_ID_QUARTER]
        || [productIdentifiers containsObject:SUBSCIBE_PRODUCT_ID_MONTH]) {
        [USERDEFAULTS setBool:true forKey:SUBSCIBE_SUCCESS];
    } else {
        [USERDEFAULTS setBool:false forKey:SUBSCIBE_SUCCESS];
    }
    
    [USERDEFAULTS synchronize];
}

- (void)addProduct:(NSString *)product {
    NSMutableSet *set = [NSMutableSet setWithSet:[self allProductsInKeychain]];
    [set addObject:product];
    [self saveAllProducts:set];
}

//- (BOOL)canRemoveAD {
//    NSString *oneSubProduct = [self.allProductsInKeychain bk_match:^BOOL(NSString * obj) {
//        return [self typeForProduct:obj] == IAPProductTypeAutoRenewSubscription;
//    }];
//
//    BOOL hasRemoveADProduct = [self.allProductsInKeychain containsObject:@"com.vavapps.decibel.removead"];
//    return oneSubProduct != nil || hasRemoveADProduct;

//    return [self hasSubscribe] || [self hasRemoveAD];
//}

- (BOOL)hasSubscribe {
//    NSString *oneSubProduct = [self.allProductsInKeychain bk_match:^BOOL(NSString * obj) {
//        return [self typeForProduct:obj] == IAPProductTypeAutoRenewSubscription;
//    }];
//
//    return oneSubProduct != nil;

    return [[NSUserDefaults standardUserDefaults] boolForKey:SUBSCIBE_SUCCESS];
}

//- (BOOL)hasRemoveAD {
//    return [[NSUserDefaults standardUserDefaults] boolForKey:@"clear_ad_success"];
//}

//- (BOOL)hasSaveProduct {
//    return [USERDEFAULTS boolForKey:CAN_CLEAR_WATER_MARK];
//}
@end
