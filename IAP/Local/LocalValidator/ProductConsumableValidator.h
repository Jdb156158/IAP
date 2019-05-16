//
//  ProductConsumableValidator.h
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalValidator.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProductConsumableValidator : NSObject <ProductValidator>
+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
