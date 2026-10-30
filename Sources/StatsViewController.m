// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "StatsViewController.h"
#import "ReceiptStore.h"
#import "Receipt.h"

@interface StatsViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@end

@implementation StatsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"统计";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 12;
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentStack];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:16],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor constant:16],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor constant:-16],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-16],
        [self.contentStack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor constant:-32],
    ]];
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)refresh {
    for (UIView *subview in self.contentStack.arrangedSubviews) {
        [self.contentStack removeArrangedSubview:subview];
        [subview removeFromSuperview];
    }

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];

    double monthTotal = [[ReceiptStore sharedStore] totalAmountInMonthOf:now];
    double todayTotal = [[ReceiptStore sharedStore] totalAmountOnDay:now];
    double allTotal = [[ReceiptStore sharedStore] totalAmount];
    NSInteger dayOfMonth = [calendar component:NSCalendarUnitDay fromDate:now];
    double monthAverage = dayOfMonth > 0 ? monthTotal / (double)dayOfMonth : 0;

    [self.contentStack addArrangedSubview:[self metricCardWithTitle:@"本月支出" value:[self money:monthTotal]]];
    [self.contentStack addArrangedSubview:[self metricCardWithTitle:@"今日支出" value:[self money:todayTotal]]];
    [self.contentStack addArrangedSubview:[self metricCardWithTitle:@"累计支出" value:[self money:allTotal]]];
    [self.contentStack addArrangedSubview:[self metricCardWithTitle:@"本月日均" value:[self money:monthAverage]]];

    UILabel *section = [[UILabel alloc] init];
    section.text = @"按类型统计";
    section.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [self.contentStack addArrangedSubview:section];

    NSDictionary<NSNumber *, NSNumber *> *byType = [[ReceiptStore sharedStore] totalByType];
    if (byType.count == 0) {
        UILabel *empty = [[UILabel alloc] init];
        empty.text = @"还没有票据，去「扫描」页添加第一张吧。";
        empty.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        empty.textColor = [UIColor secondaryLabelColor];
        empty.numberOfLines = 0;
        [self.contentStack addArrangedSubview:empty];
    } else {
        ReceiptType types[] = {ReceiptTypeInvoice, ReceiptTypeReceipt, ReceiptTypeFlight, ReceiptTypeToll, ReceiptTypeOther};
        for (NSInteger i = 0; i < 5; i++) {
            NSNumber *key = @(types[i]);
            double total = [byType[key] doubleValue];
            if (total > 0) {
                [self.contentStack addArrangedSubview:[self typeRowWithType:types[i] total:total]];
            }
        }
    }
}

- (NSString *)money:(double)value {
    return [NSString stringWithFormat:@"¥%.2f", value];
}

- (UIView *)metricCardWithTitle:(NSString *)title value:(NSString *)value {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 12;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    titleLabel.textColor = [UIColor secondaryLabelColor];

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.text = value;
    valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:28 weight:UIFontWeightSemibold];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, valueLabel]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 4;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
    ]];
    return card;
}

- (UIView *)typeRowWithType:(ReceiptType)type total:(double)total {
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = ReceiptTypeDisplayName(type);
    nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

    UILabel *amountLabel = [[UILabel alloc] init];
    amountLabel.text = [self money:total];
    amountLabel.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightMedium];
    amountLabel.textAlignment = NSTextAlignmentRight;

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[nameLabel, amountLabel]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionEqualSpacing;
    return row;
}

@end
