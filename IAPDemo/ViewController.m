//
//  ViewController.m
//  IAPDemo
//
//  Created by shupeng on 2019/5/14.
//  Copyright © 2019 shupeng. All rights reserved.
//

#import "ViewController.h"
#import <QMUIKit/QMUIKit.h>
#import "IAPDelegate.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UILabel *allProductLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kIAPDelegateSuccess object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self updateProducts];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kIAPDelegateFailed object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self updateProducts];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kIAPDelegateRestored object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSError *error = [note userInfo][kErrorKey];
        NSSet *set = [note userInfo][kObjKey];
        
        if (error == nil) {
            [self updateProducts];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kIAPDelegateChecked object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSError *error = [note userInfo][kErrorKey];
        NSSet *set = [note userInfo][kObjKey];
        
        if (error == nil) {
            [self updateProducts];
        }
    }];
    
    [self updateProducts];
}

- (IBAction)buynonconsumable:(id)sender {
    [[IAPDelegate shared] buy:@"com.shupeng.IAPDemo_yongjiuxing108"];
}
- (IBAction)buyweeksubscribtion:(id)sender {
    [[IAPDelegate shared] buy:@"com.shupeng.IAPDemo_vip"];
}
- (IBAction)buymonthsubscription:(id)sender {
    [[IAPDelegate shared] buy:@"com.shupeng.IAPDemo_svip"];
}

- (IBAction)restore:(id)sender {
    [[IAPDelegate shared] restore];
}

- (void)updateProducts {
    self.allProductLabel.text = [[[[IAPDelegate shared] allProductsInKeychain] allObjects] componentsJoinedByString:@"\n"];
}
@end
