// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "StatsViewController.h"
#import "ReceiptStore.h"
#import "Receipt.h"
#import "ReceiptListViewController.h"
#import "StatsCategoryCell.h"
#import "DailyBarChartView.h"

@interface StatsViewController ()
@property (nonatomic, strong) UIScrollView *chartScrollView;
@property (nonatomic, assign) BOOL hasScrolledChart;
@end

@implementation StatsViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"统计";
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 56;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.hasScrolledChart = NO;
    self.tableView.tableHeaderView = [self buildHeaderView];
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.hasScrolledChart || !self.chartScrollView) return;
    CGFloat offsetX = MAX(0, self.chartScrollView.contentSize.width - self.chartScrollView.bounds.size.width);
    [self.chartScrollView setContentOffset:CGPointMake(offsetX, 0) animated:NO];
    self.hasScrolledChart = YES;
}

#pragma mark - Header

- (UIView *)buildHeaderView {
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 498)];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    ReceiptStore *store = [ReceiptStore sharedStore];

    double monthTotal = [store totalAmountInMonthOf:now];
    double todayTotal = [store totalAmountOnDay:now];
    double allTotal = store.totalAmount;
    NSInteger dayOfMonth = [calendar component:NSCalendarUnitDay fromDate:now];
    double monthAverage = dayOfMonth > 0 ? monthTotal / (double)dayOfMonth : 0;
    NSInteger monthCount = [store receiptCountInMonthOf:now];
    NSArray<NSNumber *> *dailyTotals = [store dailyTotalsInMonthOf:now];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:container.bottomAnchor constant:-16],
    ]];

    UIView *hero = [self heroCardWithMonthTotal:monthTotal count:monthCount average:monthAverage];
    [stack addArrangedSubview:hero];
    [hero.heightAnchor constraintEqualToConstant:88].active = YES;

    UIStackView *row1 = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self metricCardWithTitle:@"今日支出" value:[self money:todayTotal]],
        [self metricCardWithTitle:@"累计支出" value:[self money:allTotal]]
    ]];
    row1.axis = UILayoutConstraintAxisHorizontal;
    row1.spacing = 12;
    row1.distribution = UIStackViewDistributionFillEqually;
    [stack addArrangedSubview:row1];
    for (UIView *card in row1.arrangedSubviews) {
        [card.heightAnchor constraintEqualToConstant:76].active = YES;
    }

    UIStackView *row2 = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self metricCardWithTitle:@"本月日均" value:[self money:monthAverage]],
        [self metricCardWithTitle:@"本月笔数" value:[NSString stringWithFormat:@"%ld", (long)monthCount]]
    ]];
    row2.axis = UILayoutConstraintAxisHorizontal;
    row2.spacing = 12;
    row2.distribution = UIStackViewDistributionFillEqually;
    [stack addArrangedSubview:row2];
    for (UIView *card in row2.arrangedSubviews) {
        [card.heightAnchor constraintEqualToConstant:76].active = YES;
    }

    UIView *chartCard = [self cardView];
    CGFloat cardWidth = width - 32;
    CGFloat cardHeight = 190;

    UILabel *chartTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, cardWidth - 32, 15)];
    chartTitle.text = @"每日支出";
    chartTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    chartTitle.textColor = [UIColor secondaryLabelColor];

    CGFloat scrollX = 16;
    CGFloat scrollY = 34;
    CGFloat scrollWidth = cardWidth - 32;
    CGFloat hintHeight = 12;
    CGFloat scrollHeight = cardHeight - scrollY - 6 - hintHeight - 8;

    UIScrollView *chartScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(scrollX, scrollY, scrollWidth, scrollHeight)];
    chartScroll.showsHorizontalScrollIndicator = NO;

    CGFloat chartContentWidth = MAX(scrollWidth, dailyTotals.count * 14.0);
    DailyBarChartView *chart = [[DailyBarChartView alloc] initWithFrame:CGRectMake(0, 0, chartContentWidth, scrollHeight)];
    chart.values = dailyTotals;
    [chartScroll addSubview:chart];
    chartScroll.contentSize = CGSizeMake(chartContentWidth, scrollHeight);
    chartScroll.contentOffset = CGPointMake(chartContentWidth - scrollWidth, 0);
    self.chartScrollView = chartScroll;

    __weak typeof(self) weakSelf = self;
    chart.onTapDay = ^(NSInteger day) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *comps = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:[NSDate date]];
        comps.day = day;
        NSDate *date = [calendar dateFromComponents:comps];
        ReceiptListViewController *list = [[ReceiptListViewController alloc] initWithDay:date];
        [weakSelf.navigationController pushViewController:list animated:YES];
    };

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(16, cardHeight - 8 - hintHeight, cardWidth - 32, hintHeight)];
    hint.text = @"左右滑动查看整月 · 点柱子看当天";
    hint.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    hint.textColor = [UIColor tertiaryLabelColor];
    hint.textAlignment = NSTextAlignmentCenter;

    [chartCard addSubview:chartTitle];
    [chartCard addSubview:chartScroll];
    [chartCard addSubview:hint];
    [stack addArrangedSubview:chartCard];
    [chartCard.heightAnchor constraintEqualToConstant:cardHeight].active = YES;

    return container;
}

- (UIView *)cardView {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 12;
    return card;
}

- (UILabel *)labelWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = color;
    return label;
}

- (UIView *)heroCardWithMonthTotal:(double)monthTotal count:(NSInteger)count average:(double)average {
    UIView *card = [self cardView];
    UILabel *title = [self labelWithText:@"本月支出"
                                   font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                  color:[UIColor secondaryLabelColor]];
    UILabel *value = [self labelWithText:[self money:monthTotal]
                                   font:[UIFont monospacedDigitSystemFontOfSize:34 weight:UIFontWeightSemibold]
                                  color:[UIColor labelColor]];
    UILabel *subtitle = [self labelWithText:[NSString stringWithFormat:@"共 %ld 笔 · 日均 %@", (long)count, [self money:average]]
                                      font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]
                                     color:[UIColor secondaryLabelColor]];
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, value, subtitle]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 2;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [stack.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
    ]];
    return card;
}

- (UIView *)metricCardWithTitle:(NSString *)title value:(NSString *)value {
    UIView *card = [self cardView];
    UILabel *titleLabel = [self labelWithText:title
                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                       color:[UIColor secondaryLabelColor]];
    UILabel *valueLabel = [self labelWithText:value
                                        font:[UIFont monospacedDigitSystemFontOfSize:20 weight:UIFontWeightSemibold]
                                       color:[UIColor labelColor]];
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, valueLabel]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 2;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [stack.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
    ]];
    return card;
}

- (NSString *)money:(double)value {
    return [NSString stringWithFormat:@"¥%.2f", value];
}

#pragma mark - Data

- (NSArray<NSNumber *> *)visibleTypes {
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    ReceiptType types[] = {ReceiptTypeInvoice, ReceiptTypeReceipt, ReceiptTypeFlight, ReceiptTypeToll, ReceiptTypeOther};
    NSDictionary<NSNumber *, NSNumber *> *byType = [[ReceiptStore sharedStore] totalByType];
    for (NSInteger i = 0; i < 5; i++) {
        if ([byType[@(types[i])] doubleValue] > 0) {
            [result addObject:@(types[i])];
        }
    }
    return result;
}

- (NSArray<NSDate *> *)visibleDays {
    return [[ReceiptStore sharedStore] distinctDaysWithReceipts];
}

- (NSString *)dayTitleForDate:(NSDate *)date {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
        formatter.dateFormat = @"M月d日";
    });
    return [formatter stringFromDate:date];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([ReceiptStore sharedStore].receipts.count == 0) return 1;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([ReceiptStore sharedStore].receipts.count == 0) return 1;
    if (section == 0) return [self visibleTypes].count;
    return [self visibleDays].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([ReceiptStore sharedStore].receipts.count == 0) return nil;
    return section == 0 ? @"分类" : @"按日期";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([ReceiptStore sharedStore].receipts.count == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = @"还没有票据，去「扫描」页添加第一张吧。";
        cell.textLabel.textColor = [UIColor secondaryLabelColor];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    if (indexPath.section == 0) {
        return [self categoryCellForIndex:indexPath.row];
    }
    return [self dayCellForIndex:indexPath.row];
}

- (UITableViewCell *)categoryCellForIndex:(NSInteger)index {
    ReceiptType type = (ReceiptType)[[self visibleTypes][index] integerValue];
    NSArray<Receipt *> *receipts = [[ReceiptStore sharedStore] receiptsOfType:type];
    double total = 0;
    for (Receipt *receipt in receipts) total += receipt.amount;
    double allTotal = [ReceiptStore sharedStore].totalAmount;
    double fraction = allTotal > 0 ? total / allTotal : 0;

    StatsCategoryCell *cell = [[StatsCategoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell configureWithType:type count:receipts.count total:total fraction:fraction];
    return cell;
}

- (UITableViewCell *)dayCellForIndex:(NSInteger)index {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    NSDate *day = [self visibleDays][index];
    cell.textLabel.text = [self dayTitleForDate:day];
    NSArray<Receipt *> *receipts = [[ReceiptStore sharedStore] receiptsOnDay:day];
    double total = 0;
    for (Receipt *receipt in receipts) total += receipt.amount;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld 笔 · %@", (long)receipts.count, [self money:total]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([ReceiptStore sharedStore].receipts.count == 0) return;
    if (indexPath.section == 0) {
        ReceiptType type = (ReceiptType)[[self visibleTypes][indexPath.row] integerValue];
        ReceiptListViewController *list = [[ReceiptListViewController alloc] initWithType:type];
        [self.navigationController pushViewController:list animated:YES];
    } else {
        NSDate *day = [self visibleDays][indexPath.row];
        ReceiptListViewController *list = [[ReceiptListViewController alloc] initWithDay:day];
        [self.navigationController pushViewController:list animated:YES];
    }
}

@end
