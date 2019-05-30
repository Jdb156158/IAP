//
//  IAPDelegate.h
//  IAPDemo
//
//  Created by shupeng on 2019/5/15.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IAP/IAP.h>

NS_ASSUME_NONNULL_BEGIN

#define kIAPDelegateSuccess     @"kIAPDelegateSuccess"
#define kIAPDelegateFailed      @"kIAPDelegateFailed"
#define kIAPDelegateRestored    @"kIAPDelegateRestored"
#define kIAPDelegateChecked     @"kIAPDelegateChecked"

#define kObjKey                 @"obj"
#define kErrorKey               @"error"

#define KeyChainIAPService      @"IAPService"
#define KeyChainAllProductKey   @"KeyChainAllProductKey"

@interface IAPDelegate : NSObject <IAPResultDelegate>
+ (instancetype)shared;

// 购买
- (void)buy:(NSString *)productIdentifier;

// 恢复
- (void)restore;

// check
- (void)check;

// keychain的所有商品
- (NSSet *)allProductsInKeychain;

//- (BOOL)hasRemoveAD;

//- (BOOL)canRemoveAD;

- (BOOL)hasSubscribe;
//- (BOOL)hasSaveProduct;
@end

NS_ASSUME_NONNULL_END
