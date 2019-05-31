//
//  IAP.h
//  IAP
//
//  Created by shupeng on 2019/5/13.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "RMAppReceipt.h"



/**
 商品类型
 */
typedef NS_ENUM(NSUInteger, IAPProductType) {
    IAPProductTypeConsumable __attribute__((deprecated)), // 消耗类 暂不支持
    IAPProductTypeNonConsumable, // 非消耗类
    IAPProductTypeAutoRenewSubscription, // 自动续订 订阅类
    IAPProductTypeNonAutoRenewSubscription __attribute__((deprecated)) // 非自动续订 订阅类 暂不支持
};

#pragma mark - IAP 代理
/**
 处理回调结果
 */
@protocol IAPResultDelegate <NSObject>

/**
 返回商品的类型

 @param productIdentifier productIdentifier description
 @return return value description
 */
- (IAPProductType)typeForProduct:(NSString *)productIdentifier;

/**
 告诉Receiver已经购买成功

 @param productIdentifier 商品ID
 @param transaction 你不需要对transaction进行任何处理
 */
- (void)paidSuccessWithProductIdentifier:(NSString *)productIdentifier transaction:(SKPaymentTransaction *)transaction;

/**
 告诉Receiver已经购买失败

 @param productIdentifier 商品ID
 @param transaction 你不需要对transaction进行任何处理
 @param error 失败原因
 */
- (void)paidFailedWithProductIdentifier:(NSString *)productIdentifier transaction:(SKPaymentTransaction *)transaction error:(NSError *)error;

/**
 恢复操作的回调

 @param productIdentifiers 仅恢复消耗类商品以外的所有商品, 自动续订类会进行日期校验. 非自动续订的订阅会原样返回, 需要业务层自己去校验
 @param error error description
 */
- (void)restoredValidProductIdentifiers:(NSSet<NSString *> *)productIdentifiers error:(NSError *)error;

/**
 check操作的回调
 
 @param productIdentifiers 仅恢复消耗类商品以外的所有商品, 自动续订类会进行日期校验. 非自动续订的订阅会原样返回, 需要业务层自己去校验
 @param error error description
 */
- (void)checkedValidProductIdentifiers:(NSSet<NSString *> *)productIdentifiers error:(NSError *)error;
@end



#pragma mark - 票据校验器协议
/**
 票据校验器
 */
@protocol ReceiptValidatorProtocol <NSObject>
/**
 校验某次购买的成功或者失败

 @param transaction 某次交易
 @param receipt 票据信息
 @param complete 如果失败, 返回error
 */
- (void)validateTransaction:(SKPaymentTransaction *)transaction withReceipt:(RMAppReceipt *)receipt complete:(void (^)(NSError *error))complete;

/**
 校验票据里的所有有效商品信息

 @param receipt receipt description
 @param complete 需返回所有有效商品, 不包含消耗类, 非续订的订阅类也会返回. 因为本地校验器无法知道非续订的订阅类是否过期. 业务方自己知道. 如果是服务器端的校验器, 那么可以针对此类商品进行校验.
 */
- (void)validateAllProductInReceipt:(RMAppReceipt *)receipt complete:(void (^)(NSSet<NSString *> *validProductIdentifiers, NSError *error))complete;

@end


#pragma mark - IAP

// IAP 错误类型
FOUNDATION_EXPORT NSString * const IAPErrorDomain;

NS_ERROR_ENUM(IAPErrorDomain)
{
    IAPErrorCanNotPay = 1,
    IAPErrorJailbreakPayNotAllowed,
    IAPErrorCanNotFindProduct,
    IAPErrorCanNotFindReceipt
};



/**
 IAP内购
 */
@interface IAP : NSObject <SKPaymentTransactionObserver>
/**
 初始化一个IAP manager

 @param validator 票据校验器
 @param delegate IAP处理后的回调
 @return IAP对象
 */
- (id)initWithValidator:(id<ReceiptValidatorProtocol>)validator delegate:(id<IAPResultDelegate>)delegate;


/**
 销毁
 */
- (void)destroy;

/**
 校验器
 */
@property(nonatomic, strong, readonly) id<ReceiptValidatorProtocol> validator;

/**
 IAP处理后的回调
 */
@property(nonatomic, strong, readonly) id<IAPResultDelegate> delegate;

/**
 是否允许在越狱状态下购买商品, 默认为false
 */
@property(nonatomic, assign) BOOL canMakePaymentInJail;


/**
 所有商品信息
 需要提前调用请求所有商品信息接口
 */
@property(nonatomic, strong, readonly) NSArray<SKProduct *> *products;


/**
 获取商品信息

 @param productIdentifier productIdentifier description
 @return return value description
 */
- (SKProduct *)productForIdentifier:(NSString *)productIdentifier;


/**
 获取一个商品的本地化价格字符串

 @param product product description
 @return return value description
 */
- (NSString *)priceStringForProduct:(SKProduct *)product;

/**
 获取商品信息
 应用启动时, 需要主动调用获取商品接口, 提前获取商品信息. IAP会进行缓存
 如需刷新缓存, 重新请求该接口

 @param productIdentifiers 需要购买的所有商品ID
 @param success success description
 @param failed failed description
 */
- (void)getProductsInfo:(NSSet *)productIdentifiers success:(void (^)(NSArray<SKProduct *> *products, NSSet<NSString *> *invalidProductIdentifiers))success failed:(void (^)(NSError *error))failed;

/**
 创建购买请求

 @param productIdentifier 商品ID
 @return 如果创建失败, 会返回错误信息
 */
- (NSError *)makePaymentWithProductIdentifier:(NSString *)productIdentifier;

/**
 刷新票据
 此操作会导致系统唤起用户登录APPID, 最好永远不要使用
 当用户点击恢复按钮时, 会自动触发获取receipt
 只有商品购买成功, 但是校验时失败, 此时需要刷新receipt
 */
- (void)refreshReceipt;

/**
 恢复所有商品
 */
- (void)restoreAllPurchasedProductExceptConsumable;

/**
 通过票据, 检查所有的商品有效信息.
 */
- (void)checkReceiptForAllPurchasedProductExceptConsumable;
@end
