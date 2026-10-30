// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 简单的每日支出柱状图，纯 Core Graphics 绘制。
@interface DailyBarChartView : UIView
@property (nonatomic, copy) NSArray<NSNumber *> *values; // 每日金额，index 0 = 当月 1 号
@property (nonatomic, strong) UIColor *barColor;
@end

NS_ASSUME_NONNULL_END
