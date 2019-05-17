//
//  IAP.m
//  IAP
//
//  Created by shupeng on 2019/5/13.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "IAP.h"
#import <BlocksKit/A2DynamicDelegate.h>
#import <BlocksKit/BlocksKit.h>
#import <SystemServices/SystemServices.h>

#ifdef DEBUG
#define IAPLog(...) NSLog(@"IAP: %@", [NSString stringWithFormat:__VA_ARGS__]);
#else
#define IAPLog(...)
#endif

NSString * const IAPErrorDomain = @"IAPErrorDomain";

@interface IAP ()
@property(nonatomic, assign) NSInteger refreshReceiptRetry; // 最大刷新票据次数
@end

@implementation IAP

- (instancetype)initWithValidator:(id<ReceiptValidatorProtocol>)validator delegate:(id<IAPResultDelegate>)delegate
{
    self = [super init];
    if (self) {
        _validator = validator;
        _delegate = delegate;
        self.refreshReceiptRetry = 3;
        
        [self setup];
    }
    return self;
}

+ (instancetype)shared {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

- (void)setup {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        self.refreshReceiptRetry = 3;
    }];
}

- (void)destroy {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)getProductsInfo:(NSSet *)productIdentifiers success:(void (^)(NSArray<SKProduct *> *products, NSSet<NSString *> *invalidProductIdentifiers))success failed:(void (^)(NSError *error))failed {
    
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    A2DynamicDelegate <SKProductsRequestDelegate> *dynamicDelegate = [request bk_dynamicDelegate];
    [dynamicDelegate implementMethod:@selector(productsRequest:didReceiveResponse:) withBlock:^(SKProductsRequest *request, SKProductsResponse *response) {
        
        NSString *validIdentifiers = [response.products bk_reduce:@"" withBlock:^NSString *(NSString *sum, SKProduct *obj) {
            return [sum stringByAppendingFormat:@"%@ ", obj.productIdentifier];
        }];
        IAPLog(@"fetched valid product identifiers: %@", validIdentifiers);
        IAPLog(@"[IAP] fetched invalid product identifiers: %@", [response.invalidProductIdentifiers componentsJoinedByString:@" "]);
        
        _products = response.products;
        if (success) {
            success(response.products, [NSSet setWithArray:response.invalidProductIdentifiers]);
        }
    }];
    
    [dynamicDelegate implementMethod:@selector(requestDidFinish:) withBlock:^(SKRequest *request) {
        IAPLog(@"fetch product request has finished");
    }];
    
    [dynamicDelegate implementMethod:@selector(request:didFailWithError:) withBlock:^(SKRequest *request, NSError *error) {
        IAPLog(@"fetch product request occours an error: %@", [error localizedDescription]);
        if (failed) {
            failed(error);
        }
    }];
    
    request.delegate = dynamicDelegate;
    [request start];
}

- (SKProduct *)productForIdentifier:(NSString *)productIdentifier {
    SKProduct *product = [self.products bk_match:^BOOL(SKProduct *obj) {
        return [obj.productIdentifier isEqualToString:productIdentifier];
    }];
    return product;
}

- (NSString *)priceStringForProduct:(SKProduct *)product {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
    return formattedPrice;
}

- (NSError *)makePaymentWithProductIdentifier:(NSString *)productIdentifier {
    // 如果是越狱环境
    if (([SSJailbreakCheck jailbroken] != NOTJAIL) && !self.canMakePaymentInJail) {
        NSError *error = [NSError errorWithDomain:IAPErrorDomain code:IAPErrorJailbreakPayNotAllowed userInfo:@{NSLocalizedDescriptionKey: @"can not make payment with jailbreak!"}];
        
        return error;
    }
    
    // 系统是否支持支付
    if (![SKPaymentQueue canMakePayments]) {
        NSError *error = [NSError errorWithDomain:IAPErrorDomain code:IAPErrorCanNotPay userInfo:@{NSLocalizedDescriptionKey: @"can not make payment now!"}];
        return error;
    }
    
    SKProduct *product = [self.products bk_match:^BOOL(SKProduct *obj) {
        return [obj.productIdentifier isEqualToString:productIdentifier];
    }];
    
    if (product == nil) {
        NSError *error = [NSError errorWithDomain:IAPErrorDomain code:IAPErrorCanNotFindProduct userInfo:@{NSLocalizedDescriptionKey: @"can not find the product specified!"}];
        return error;
    }
    
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    return nil;
}

- (NSURL*)receiptURL
{
    return [NSBundle mainBundle].appStoreReceiptURL;
}

- (void)refreshReceipt {
    [self refreshReceipt:nil];
}


- (void)refreshReceipt:(void (^)(NSError *error))complete {
    SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
    A2DynamicDelegate <SKRequestDelegate> *dynamicDelegate = [request bk_dynamicDelegate];
    
    [dynamicDelegate implementMethod:@selector(requestDidFinish:) withBlock:^(SKRequest *request) {
        IAPLog(@"refresh receipt request has finished");
        if (complete) {
            complete(nil);
        }
    }];
    
    [dynamicDelegate implementMethod:@selector(request:didFailWithError:) withBlock:^(SKRequest *request, NSError *error) {
        IAPLog(@"refresh receipt request occours an error: %@", [error localizedDescription]);
        if (complete) {
            complete(error);
        }
    }];
    
    request.delegate = dynamicDelegate;
    [request start];
}

- (void)restoreAllPurchasedProductExceptConsumable {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)checkReceiptForAllPurchasedProductExceptConsumable {
//    dispatch_async(dispatch_get_main_queue(), ^{
        RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
        if (receipt == nil) {
            IAPLog(@"APP进行check有效性操作. 但是没有发现receipt, 此处不会强制更新receipt");
            NSError *error = [NSError errorWithDomain:IAPErrorDomain code:IAPErrorCanNotFindReceipt userInfo:@{NSLocalizedDescriptionKey: @"can not find receipt"}];
            [self.delegate checkedValidProductIdentifiers:nil error:error];
        } else {
            IAPLog(@"APP进行check有效性操作. 正在进行receipt校验...");
            [self.validator validateAllProductInReceipt:receipt complete:^(NSSet<NSString *> *validProductIdentifiers, NSError *error) {
                IAPLog(@"check操作已完成, 已校验receipt, 并获取有效商品:%@, 错误:%@", validProductIdentifiers, error);
                [self.delegate checkedValidProductIdentifiers:validProductIdentifiers error:error];
            }];
        }
//    });
}

#pragma mark - request delegate
- (void)requestDidFinish:(SKRequest *)request {
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
}

#pragma mark - product request delegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
}

#pragma mark - transaction delegate
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    [transactions bk_each:^(SKPaymentTransaction *transaction) {
        switch (transaction.transactionState) {
                
            case SKPaymentTransactionStatePurchasing:
                // Transaction is being added to the server queue.
                IAPLog(@"正在购买... %@ %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                
                break;
                
                
            case SKPaymentTransactionStatePurchased:
                // Transaction is in queue, user has been charged.  Client should complete the transaction.
            {
                IAPLog(@"购买成功! %@ %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
                if (receipt == nil) {
                    IAPLog(@"系统返回购买成功, 但是没有找到receipt, 此处需要强制更新receipt!");
                    NSError *error = [NSError errorWithDomain:IAPErrorDomain code:IAPErrorCanNotFindReceipt userInfo:@{NSLocalizedDescriptionKey: @"can not find receipt"}];
                    [self.delegate paidFailedWithProductIdentifier:transaction.payment.productIdentifier transaction:transaction error:error];
                    [self refreshReceipt];
                } else {
                    IAPLog(@"开始校验receipt...");
                    [self.validator validateTransaction:transaction withReceipt:receipt complete:^(NSError *error) {
                        if (error == nil) {
                            IAPLog(@"校验成功! %@ %@", transaction.payment.productIdentifier, transaction.transactionIdentifier) ;
                            [self.delegate paidSuccessWithProductIdentifier:transaction.payment.productIdentifier transaction:transaction];
                            
                            // 只有确认发货才结束交易. 否则永远不要结束交易.
                            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

                        } else {
                            IAPLog(@"校验失败! %@ %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                            [self.delegate paidFailedWithProductIdentifier:transaction.payment.productIdentifier transaction:transaction error:error];
                            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                        }
                    }];
                }
            }
                break;
                
            case SKPaymentTransactionStateFailed:
                // Transaction was cancelled or failed before being added to the server queue.
                IAPLog(@"购买失败:%@ %@ %@", [transaction.error localizedDescription], transaction.payment.productIdentifier, transaction.transactionIdentifier);
                
                [self.delegate paidFailedWithProductIdentifier:transaction.payment.productIdentifier transaction:transaction error:transaction.error];
                // 购买失败直接结束事务.
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
                
            case SKPaymentTransactionStateRestored:
                // Transaction was restored from user's purchase history.  Client should complete the transaction.
                IAPLog(@"购买被恢复! %@ %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                
                // 恢复直接结束事务.
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
                
            case SKPaymentTransactionStateDeferred:
                // The transaction is in the queue, but its final status is pending external action.
                IAPLog(@"购买已被延迟! %@ %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                break;
        }
    }];
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    NSArray *descriptionArray = [transactions bk_map:^id(SKPaymentTransaction *transaction) {
        return [NSString stringWithFormat:@"id: %@  product id: %@", transaction.payment.productIdentifier, transaction.transactionIdentifier];
    }];
    IAPLog(@"交易被结束 %@", [descriptionArray componentsJoinedByString:@"\n"])
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
    IAPLog(@"用户进行恢复操作, 已完成!");
    if (receipt == nil) {
        IAPLog(@"用户进行恢复操作, 但是没有找到recepit, 此处强制更新receipt");
        [self refreshReceipt:^(NSError *error) {
            if (error) {
                IAPLog(@"强制更新receipt失败, %@", [error localizedDescription]);
                
                NSError *error = [NSError errorWithDomain:IAPErrorDomain code:IAPErrorCanNotFindReceipt userInfo:@{NSLocalizedDescriptionKey: @"can not find receipt"}];
                [self.delegate restoredValidProductIdentifiers:nil error:error];
            } else {
                RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
                IAPLog(@"强制更新receipt完成, 下面进行receipt校验...");
                [self.validator validateAllProductInReceipt:receipt complete:^(NSSet<NSString *> *validProductIdentifiers, NSError *error) {
                    IAPLog(@"恢复操作已完成, 已校验receipt, 并获取有效商品:%@, 错误:%@", validProductIdentifiers, error);
                    [self.delegate restoredValidProductIdentifiers:validProductIdentifiers error:error];
                }];
            }
        }];
    } else {
        IAPLog(@"获取到所有恢复的商品, 下面进行receipt校验...");
        [self.validator validateAllProductInReceipt:receipt complete:^(NSSet<NSString *> *validProductIdentifiers, NSError *error) {
            IAPLog(@"恢复操作已完成, 已校验receipt, 并获取有效商品:%@, 错误:%@", validProductIdentifiers, error);
            [self.delegate restoredValidProductIdentifiers:validProductIdentifiers error:error];
        }];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads {
    
}

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product {
    return true;
}

@end
