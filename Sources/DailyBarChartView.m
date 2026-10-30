// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "DailyBarChartView.h"

@implementation DailyBarChartView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _barColor = [UIColor systemBlueColor];
        _values = @[];
    }
    return self;
}

- (void)setValues:(NSArray<NSNumber *> *)values {
    _values = [values copy];
    [self setNeedsDisplay];
}

- (void)setBarColor:(UIColor *)barColor {
    _barColor = barColor;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    NSUInteger count = self.values.count;
    if (count == 0) return;

    double maxValue = 0;
    for (NSNumber *number in self.values) {
        if (number.doubleValue > maxValue) maxValue = number.doubleValue;
    }
    if (maxValue <= 0) maxValue = 1;

    CGFloat topInset = 6;
    CGFloat bottomInset = 18;
    CGFloat plotWidth = CGRectGetWidth(rect);
    CGFloat plotHeight = CGRectGetHeight(rect) - topInset - bottomInset;

    // 横向网格线
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor separatorColor] setStroke];
    CGContextSetLineWidth(context, 1.0 / [UIScreen mainScreen].scale);
    NSInteger gridLines = 4;
    for (NSInteger i = 0; i < gridLines; i++) {
        CGFloat y = topInset + plotHeight * (CGFloat)i / (CGFloat)(gridLines - 1);
        CGContextMoveToPoint(context, 0, y);
        CGContextAddLineToPoint(context, plotWidth, y);
    }
    CGContextStrokePath(context);

    // 柱子
    CGFloat slotWidth = plotWidth / (CGFloat)count;
    CGFloat barWidth = MAX(2.0, slotWidth * 0.6);
    for (NSUInteger i = 0; i < count; i++) {
        double value = self.values[i].doubleValue;
        CGFloat barHeight = (CGFloat)(value / maxValue) * plotHeight;
        CGFloat x = slotWidth * (CGFloat)i + (slotWidth - barWidth) / 2.0;
        CGFloat y = topInset + plotHeight - barHeight;
        CGRect barRect = CGRectMake(x, y, barWidth, MAX(barHeight, value > 0 ? 1 : 0));
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:barRect
                                                         cornerRadius:MIN(barWidth / 2.0, 3.0)];
        [self.barColor setFill];
        [path fill];
    }

    // x 轴刻度：1 号起每 5 天，加上最后一天
    NSMutableSet<NSNumber *> *labelIndices = [NSMutableSet set];
    [labelIndices addObject:@0];
    for (NSInteger i = 4; i < (NSInteger)count; i += 5) {
        [labelIndices addObject:@(i)];
    }
    [labelIndices addObject:@(count - 1)];

    NSDictionary *attributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:10],
        NSForegroundColorAttributeName: [UIColor secondaryLabelColor]
    };
    NSArray<NSNumber *> *sortedIndices = [labelIndices.allObjects sortedArrayUsingSelector:@selector(compare:)];
    for (NSNumber *indexNumber in sortedIndices) {
        NSInteger index = indexNumber.integerValue;
        NSString *text = [NSString stringWithFormat:@"%ld", (long)(index + 1)];
        CGSize size = [text sizeWithAttributes:attributes];
        CGFloat x = slotWidth * index + slotWidth / 2.0 - size.width / 2.0;
        CGFloat y = topInset + plotHeight + 3;
        [text drawAtPoint:CGPointMake(x, y) withAttributes:attributes];
    }
}

@end
