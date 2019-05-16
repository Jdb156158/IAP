//
//  KeychainStorage.m
//  IAP
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "KeychainStorage.h"
#import "TransactionPersistanceObj.h"
#import <UICKeyChainStore/UICKeyChainStore.h>
#import <BlocksKit/BlocksKit.h>

#define KeychainStorageService @"KeychainStorageService"
#define AllTransactionsKey @"AllTransactionsKey"
#define DeleiveredTransactionsKey @"DeleiveredTransactionsKey"

@interface KeychainStorage ()
@property(nonatomic, strong) NSMutableArray *allTransactions;
@property(nonatomic, strong) NSMutableArray *deleiveredTransactions;
@end

@implementation KeychainStorage

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static KeychainStorage *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSSet *set = [NSSet setWithArray:@[[NSArray class], [TransactionPersistanceObj class]]];
        
        NSData *allTransactionsData = [[UICKeyChainStore keyChainStoreWithService:KeychainStorageService] dataForKey:AllTransactionsKey];
        NSError *error;
        self.allTransactions = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchivedObjectOfClasses:set fromData:allTransactionsData error:&error]];
        
        NSData *deleiveredTransactionsData = [[UICKeyChainStore keyChainStoreWithService:KeychainStorageService] dataForKey:DeleiveredTransactionsKey];
        self.deleiveredTransactions = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchivedObjectOfClasses:set fromData:deleiveredTransactionsData error:&error]];
        NSLog(@"%@", [error localizedDescription]);
    }
    
    return self;
}

- (void)addTransaction:(SKPaymentTransaction *)transaction {
    TransactionPersistanceObj *obj = [[TransactionPersistanceObj alloc] initWithSKPaymentTrasaction:transaction];
    if (![self.allTransactions containsObject:obj]) {
        [self.allTransactions addObject:obj];
        [self saveAllTransactions];
    }
}

- (void)removeTransaction:(NSString *)transactionIdentifier {
    TransactionPersistanceObj *transaction = [self.allTransactions bk_match:^BOOL(TransactionPersistanceObj *obj) {
        return obj.transactionIdentifier = transactionIdentifier;
    }];
    
    if (transaction) {
        [self.allTransactions removeObject:transaction];
        [self saveAllTransactions];
    }
}

- (NSArray<id <TransactionPersistanceProtocol>> *)allTransactions {
    return _allTransactions;
}

- (void)deleiverTransaction:(SKPaymentTransaction *)transaction {
    TransactionPersistanceObj *obj = [[TransactionPersistanceObj alloc] initWithSKPaymentTrasaction:transaction];

    if (![self.deleiveredTransactions containsObject:obj]) {
        [self.deleiveredTransactions addObject:obj];
        [self saveDeleiveredTransactions];
    }
}

- (void)removeDeleiveredFinishTransaction:(NSString *)transactionIdentifier {
    TransactionPersistanceObj *transaction = [self.deleiveredTransactions bk_match:^BOOL(TransactionPersistanceObj *obj) {
        return obj.transactionIdentifier = transactionIdentifier;
    }];
    
    if (transaction) {
        [self.deleiveredTransactions removeObject:transaction];
        [self saveDeleiveredTransactions];
    }
}

- (NSArray<id <TransactionPersistanceProtocol>> *)allDeleiveredTransactions {
    return _deleiveredTransactions;
}

- (BOOL)transactionHasBeenDeleivered:(NSString *)transactionIdentifier {
    TransactionPersistanceObj *obj = [self.deleiveredTransactions bk_match:^BOOL(TransactionPersistanceObj *obj) {
        return [obj.transactionIdentifier isEqualToString:transactionIdentifier];
    }];
    return obj != nil;
}

- (void)saveAllTransactions {
    NSData *allTransactionsData = [NSKeyedArchiver archivedDataWithRootObject:self.allTransactions requiringSecureCoding:true error:nil];
    [[UICKeyChainStore keyChainStoreWithService:KeychainStorageService] setData:allTransactionsData forKey:AllTransactionsKey];
}

- (void)saveDeleiveredTransactions {
    NSError *error;
    NSData *deleiveredTransactionsData = [NSKeyedArchiver archivedDataWithRootObject:self.deleiveredTransactions requiringSecureCoding:true error:&error];
    [[UICKeyChainStore keyChainStoreWithService:KeychainStorageService] setData:deleiveredTransactionsData forKey:DeleiveredTransactionsKey];
}
@end
