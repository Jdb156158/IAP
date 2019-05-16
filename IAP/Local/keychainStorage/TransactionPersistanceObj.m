//
//  TransactionPersistanceObj.m
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "TransactionPersistanceObj.h"

@implementation TransactionPersistanceObj

+ (BOOL)supportsSecureCoding {
    return true;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.transactionIdentifier = [decoder decodeObjectOfClass:[NSString class] forKey:@"transactionIdentifier"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.transactionIdentifier forKey:@"transactionIdentifier"];
}


- (id)initWithSKPaymentTrasaction:(SKPaymentTransaction *)transaction {
    if (self = [super init]) {
        self.transactionIdentifier = transaction.transactionIdentifier;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return [self.transactionIdentifier isEqual:[object transactionIdentifier]];
}
@end
