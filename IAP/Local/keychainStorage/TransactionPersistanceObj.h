//
//  TransactionPersistanceObj.h
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "TransactionStorageProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface TransactionPersistanceObj : NSObject <TransactionPersistanceProtocol>

@property(nonatomic, strong) NSString *transactionIdentifier;

@end

NS_ASSUME_NONNULL_END
