//
//  LocalIAPResultHandler.m
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "LocalIAPResultHandler.h"
#import "KeychainStorage.h"
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "LocalValidator.h"

@interface LocalIAPResultHandler ()
@property(nonatomic, strong) LocalValidator *localValidator;
@end

@implementation LocalIAPResultHandler

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LocalIAPResultHandler *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.localValidator = [[LocalValidator alloc] initWithPassword:@"190a71be20ff43e49b1beda92b0f91f0"];
    }
    return self;
}

- (void)handleSuccessTransaction:(SKPaymentTransaction *)transaction completion:(void (^)(void))completion {
    // 1. 存储票据
    NSLog(@"存储事务: %@, %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
    [[KeychainStorage sharedInstance] addTransaction:transaction];
    
    /*#import "IAP.h"
     * 2. 验证票据
     * 此处的购买后处理流程只针对本地, 本地处理的消耗类商品, 不需要验证.
     * 因为不需要支持跨设备. 即使被Hack, 也不会被同步到其他设备.
     * 如果需要支持跨设备. 购买后的流程一般交给服务器去验证receipt.
     */
    
    ProductType type = [self.productDelegate typeForProductIdentifier:transaction.payment.productIdentifier];

    switch (type) {
            // 消耗类
        case ProductTypeConsumable:
        {
            [self.localValidator validateConsumableTransaction:transaction complete:^(BOOL isTrue) {
                if (isTrue) {
                    // 要对同一个id的transaction加锁. 防止重复发货.
                    @synchronized (self) {
                        // 3 检测是否已发货
                        NSLog(@"检测是否发货: %@, %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                        // 未发货
                        if (![[KeychainStorage sharedInstance] transactionHasBeenDeleivered:transaction.transactionIdentifier]) {
                            NSLog(@"未发货: %@, %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                            // 4. 发货
                            if ([self.delegate respondsToSelector:@selector(deleiverConsumableProduct:fromTransaction:)]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.delegate deleiverConsumableProduct:transaction.payment.productIdentifier fromTransaction:transaction];
                                });
                                NSLog(@"发货完成: %@, %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                                
                                // 5. 存储
                                [[KeychainStorage sharedInstance] deleiverTransaction:transaction];
                                NSLog(@"标记已发货: %@, %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                                
                                // 6. 结束事务. 只有确保完成验证才能结束此次事务, 否则, 不要结束, 等待下个时机重新验证.
                                completion();
                                NSLog(@"未发货过的结束事务: %@, %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                            }
                            
                        }
                        // 已发货
                        else {
                            // 什么都不做
                            
                            completion();
                            NSLog(@"已发货过的结束事务: %@, %@", transaction.payment.productIdentifier, transaction.transactionIdentifier);
                        };
                    }
                }

            } failed:^(NSError * _Nonnull error) {
                
            }];
        }
            break;
            
            // 非消耗类
        case ProductTypeNonConsumable:
        {
            [self.localValidator validateNonConsumableTransaction:transaction complete:^(BOOL isTrue) {
                // 如果是非消耗类, 直接激活商品 或者 取消激活商品
                // 3. 激活 或者 取消激活
                if (isTrue) {
                    if ([self.delegate respondsToSelector:@selector(activeNonConsumableProduct:fromTransaction:)]) {
                        [self.delegate activeNonConsumableProduct:transaction.payment.productIdentifier fromTransaction:transaction];
                    }
                } else {
                    if ([self.delegate respondsToSelector:@selector(deactiveNonConsumableProduct:fromTransaction:)]) {
                        [self.delegate deactiveNonConsumableProduct:transaction.payment.productIdentifier fromTransaction:transaction];
                    }
                }
                // 4. 结束事务. 只有确保完成验证才能结束此次事务, 否则, 不要结束, 等待下个时机重新验证.
                completion();
            } failed:^(NSError * _Nonnull error) {
                
            }];
        }
            break;
            
            // 自动续订
            case ProductTypeAutoRenewSubscription:
        {
            [self.localValidator validateAutoRenewSubscriptionTransaction:transaction complete:^(BOOL isTrue) {
                // 如果是自动续订的订阅类, 直接激活订阅 或者 取消激活订阅
                // 3. 激活 或者 取消激活
                if (isTrue) {
                    if ([self.delegate respondsToSelector:@selector(activeAutoRenewSubScriptionProduct:fromTransaction:)]) {
                        [self.delegate activeAutoRenewSubScriptionProduct:transaction.payment.productIdentifier fromTransaction:transaction];
                    }
                } else {
                    if ([self.delegate respondsToSelector:@selector(deactiveAutoRenewSubScriptionProduct:fromTransaction:)]) {
                        [self.delegate deactiveAutoRenewSubScriptionProduct:transaction.payment.productIdentifier fromTransaction:transaction];
                    }
                }
                // 4. 结束事务. 只有确保完成验证才能结束此次事务, 否则, 不要结束, 等待下个时机重新验证.
                completion();
            } failed:^(NSError * _Nonnull error) {
                
            }];
        }
            break;
            
            // 非自动续订
            case ProductTypeNonAutoRenewSubscription:
        {
            [self.localValidator validateNonAutoRenewSubscriptionTransaction:transaction complete:^(BOOL isTrue) {
                // 如果是非自动续订的订阅类, 直接激活订阅 或者 取消激活订阅
                // 3. 激活 或者 取消激活
                if (isTrue) {
                    if ([self.delegate respondsToSelector:@selector(activeNonAutoRenewSubScriptionProduct:fromTransaction:)]) {
                        [self.delegate activeNonAutoRenewSubScriptionProduct:transaction.payment.productIdentifier fromTransaction:transaction];
                    }
                } else {
                    if ([self.delegate respondsToSelector:@selector(deactiveNonAutoRenewSubScriptionProduct:fromTransaction:)]) {
                        [self.delegate deactiveNonAutoRenewSubScriptionProduct:transaction.payment.productIdentifier fromTransaction:transaction];
                    }
                }
                // 4. 结束事务. 只有确保完成验证才能结束此次事务, 否则, 不要结束, 等待下个时机重新验证.
                completion();
            } failed:^(NSError * _Nonnull error) {
                
            }];
        }
        default:
            break;
    }
}

- (void)handleFailedTransaction:(SKPaymentTransaction *)transaction error:(NSError *)error {
    
}
@end
