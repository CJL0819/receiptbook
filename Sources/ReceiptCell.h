// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import <UIKit/UIKit.h>

@class Receipt;
@class ReceiptStore;

@interface ReceiptCell : UITableViewCell
- (void)configureWithReceipt:(Receipt *)receipt store:(ReceiptStore *)store;
@end
