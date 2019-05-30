//
//  IAP.m
//  IAP
//
//  Created by shupeng on 2019/5/20.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "IAP.h"

@implementation IAP
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static IAP *instance = nil;
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
        [self addSKPaymentQueueObserver];
    }
    return self;
}

- (void)addSKPaymentQueueObserver {
    
}
@end
