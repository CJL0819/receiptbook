// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import <UIKit/UIKit.h>
#import "Receipt.h"

NS_ASSUME_NONNULL_BEGIN

/// 统计页「分类」行：图标 + 名称 + 金额，底部一条占比进度条。
@interface StatsCategoryCell : UITableViewCell
- (void)configureWithType:(ReceiptType)type count:(NSInteger)count total:(double)total fraction:(double)fraction;
@end

NS_ASSUME_NONNULL_END
