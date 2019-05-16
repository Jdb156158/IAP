//
//  LocalValidator.m
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "LocalValidator.h"
#import <GoogleUtilities/GULAppEnvironmentUtil.h>
#import "ProductConsumableValidator.h"

NSString * const LocalValidatorErrorDomain = @"LocalValidatorErrorDomain";


@interface LocalValidator ()
@property(nonatomic, strong) NSString *password;
@end

@implementation LocalValidator
- (id)initWithPassword:(NSString *)password {
    self = [super init];
    if (self) {
        self.password = password;
    }
    return self;
}

- (void)validateTransaction:(SKPaymentTransaction *)transaction complete:(void (^)(BOOL isTrue))complete failed:(void (^)(NSError * _Nonnull))failed withProductValidator:(id<ProductValidator>)validator {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    
    // 获取receipt票据失败
    if(receipt == nil) {
        if (failed) {
            NSError *error = [NSError errorWithDomain:LocalValidatorErrorDomain code:LocalValidatorErrorNoReceipt userInfo:@{NSLocalizedDescriptionKey: @"receipt not found"}];
            failed(error);
        }
        return;
    }
    
    // 创建request data失败
    NSError *error;
    NSDictionary *requestContents = @{@"receipt-data": [receipt base64EncodedStringWithOptions:0], @"password": self.password, @"exclude-old-transactions": @(true)};
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents options:0 error:&error];
    if (requestData == nil) {
        if (failed) {
            NSError *error = [NSError errorWithDomain:LocalValidatorErrorDomain code:LocalValidatorErrorRequestDataError userInfo:@{NSLocalizedDescriptionKey: @"create receipt request data error!"}];
            failed(error);
        }
        return;
    }
    
    NSURL *storeURL;
    if ([GULAppEnvironmentUtil isFromAppStore]) {
        storeURL = [NSURL URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
    } else {
        storeURL = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
    }
    
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:storeRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // 网络请求失败
        if (error) {
            if (failed) {
                failed(error);
            }
            return;
        }
        // 请求成功
        else {
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (jsonResponse) {
                if ([jsonResponse[@"status"] integerValue] == 0) {
                    BOOL isTrue = [validator validateTransaction:transaction receiptJson:jsonResponse];
                    if (complete) {
                        complete(isTrue);
                    }
                } else {
                    if (complete) {
                        complete(false);
                    }
                }
            } else {
                if (failed) {
                    NSError *error = [NSError errorWithDomain:LocalValidatorErrorDomain code:LocalValidatorErrorDecodeJsonError userInfo:@{NSLocalizedDescriptionKey: @"decode receipt json error!"}];
                    failed(error);
                }
            }
        }
    }] resume];
}

- (void)validateConsumableTransaction:(SKPaymentTransaction *)transaction complete:(void (^)(BOOL isTrue))complete failed:(void (^)(NSError * _Nonnull))failed {
//    [self validateTransaction:transaction complete:complete failed:failed withProductValidator:[ProductConsumableValidator sharedInstance]];
    complete(true);
}

- (void)validateNonConsumableTransaction:(SKPaymentTransaction *)transaction complete:(void (^)(BOOL isTrue))complete failed:(void (^)(NSError * _Nonnull))failed {
    [self validateTransaction:transaction complete:complete failed:failed withProductValidator:[ProductConsumableValidator sharedInstance]];
}

- (void)validateAutoRenewSubscriptionTransaction:(SKPaymentTransaction *)transaction complete:(void (^)(BOOL isTrue))complete failed:(void (^)(NSError * _Nonnull))failed {
    [self validateTransaction:transaction complete:complete failed:failed withProductValidator:[ProductConsumableValidator sharedInstance]];
}

- (void)validateNonAutoRenewSubscriptionTransaction:(SKPaymentTransaction *)transaction complete:(void (^)(BOOL isTrue))complete failed:(void (^)(NSError * _Nonnull))failed {
    [self validateTransaction:transaction complete:complete failed:failed withProductValidator:[ProductConsumableValidator sharedInstance]];
}

@end
