//
//  KeychainStorage.h
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransactionStorageProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface KeychainStorage : NSObject <TransactionStorageProtocol>

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
