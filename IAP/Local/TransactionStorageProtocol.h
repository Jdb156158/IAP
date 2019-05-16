//
//  TransactionStorageProtocol.h
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TransactionPersistanceProtocol <NSSecureCoding>

@property(nonatomic, strong, readonly) NSString *transactionIdentifier;

- (id)initWithSKPaymentTrasaction:(SKPaymentTransaction *)transaction;

- (BOOL)isEqual:(id<TransactionPersistanceProtocol>)object;
@end


/**
 事务的持久化 目的
 1. 实现获取、存储已购买的事务
 2. 实现获取、存储已发货的事务
 3. 判断事务是否已经发货
 */
@protocol TransactionStorageProtocol <NSObject>

- (void)addTransaction:(SKPaymentTransaction *)transaction;

- (void)removeTransaction:(NSString *)transactionIdentifier;

- (NSArray<id<TransactionPersistanceProtocol>> *)allTransactions;

- (void)deleiverTransaction:(SKPaymentTransaction *)transaction;

- (void)removeDeleiveredFinishTransaction:(NSString *)transactionIdentifier;

- (NSArray<id<TransactionPersistanceProtocol>> *)allDeleiveredTransactions;

- (BOOL)transactionHasBeenDeleivered:(NSString *)transactionIdentifier;
@end

NS_ASSUME_NONNULL_END
