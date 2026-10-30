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

    CGFloat topInset = 18;   // 留出最大金额刻度
    CGFloat bottomInset = 18; // 日期刻度
    CGFloat plotWidth = CGRectGetWidth(rect);
    CGFloat plotHeight = CGRectGetHeight(rect) - topInset - bottomInset;
    CGFloat baselineY = topInset + plotHeight;

    CGContextRef context = UIGraphicsGetCurrentContext();

    // 三条浅色横向网格线
    [[UIColor separatorColor] setStroke];
    CGContextSetLineWidth(context, 1.0 / [UIScreen mainScreen].scale);
    for (NSInteger i = 0; i < 3; i++) {
        CGFloat y = topInset + plotHeight * (CGFloat)i / 2.0;
        CGContextMoveToPoint(context, 0, y);
        CGContextAddLineToPoint(context, plotWidth, y);
    }
    CGContextStrokePath(context);

    // 基线
    [[UIColor systemGray3Color] setStroke];
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, 0, baselineY);
    CGContextAddLineToPoint(context, plotWidth, baselineY);
    CGContextStrokePath(context);

    // 柱子（只圆顶部两角）
    CGFloat slotWidth = plotWidth / (CGFloat)count;
    CGFloat barWidth = MAX(3.0, slotWidth * 0.7);
    for (NSUInteger i = 0; i < count; i++) {
        double value = self.values[i].doubleValue;
        CGFloat barHeight = (CGFloat)(value / maxValue) * plotHeight;
        CGFloat x = slotWidth * (CGFloat)i + (slotWidth - barWidth) / 2.0;
        CGFloat y = baselineY - barHeight;
        CGFloat h = MAX(barHeight, value > 0 ? 2 : 0);
        UIBezierPath *path = [self barPathAtX:x y:y width:barWidth height:h];
        [self.barColor setFill];
        [path fill];
    }

    // 最大金额刻度（左上角）
    NSDictionary *maxAttrs = @{
        NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [UIColor secondaryLabelColor]
    };
    NSString *maxText = [NSString stringWithFormat:@"¥%.2f", maxValue];
    [maxText drawAtPoint:CGPointMake(0, 0) withAttributes:maxAttrs];

    // 日期刻度：1 号起每 5 天，加最后一天
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
        CGFloat y = baselineY + 4;
        [text drawAtPoint:CGPointMake(x, y) withAttributes:attributes];
    }
}

- (UIBezierPath *)barPathAtX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height {
    CGFloat radius = MIN(width / 2.0, 4.0);
    if (height <= radius * 2) {
        return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, width, height)
                                          cornerRadius:MIN(width / 2.0, height / 2.0)];
    }
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(x, y + height)];
    [path addLineToPoint:CGPointMake(x, y + radius)];
    [path addArcWithCenter:CGPointMake(x + radius, y + radius)
                    radius:radius
                startAngle:M_PI
                  endAngle:M_PI * 1.5
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(x + width - radius, y)];
    [path addArcWithCenter:CGPointMake(x + width - radius, y + radius)
                    radius:radius
                startAngle:M_PI * 1.5
                  endAngle:0
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(x + width, y + height)];
    [path closePath];
    return path;
}

@end
