// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import <UIKit/UIKit.h>
#import "Receipt.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReceiptListViewController : UITableViewController
- (instancetype)initWithType:(ReceiptType)type;
- (instancetype)initWithDay:(NSDate *)day;
@end

NS_ASSUME_NONNULL_END
