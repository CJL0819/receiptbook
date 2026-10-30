// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "ReceiptListViewController.h"
#import "ReceiptStore.h"
#import "Receipt.h"
#import "ReceiptCell.h"
#import "AddReceiptViewController.h"
#import "ReceiptDetailViewController.h"

@interface ReceiptListViewController ()
@property (nonatomic, assign) BOOL filtersByType;
@property (nonatomic, assign) ReceiptType filterType;
@property (nonatomic, strong) NSDate *filterDay;
@end

@implementation ReceiptListViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    return self;
}

- (instancetype)initWithType:(ReceiptType)type {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _filtersByType = YES;
        _filterType = type;
    }
    return self;
}

- (instancetype)initWithDay:(NSDate *)day {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _filtersByType = NO;
        _filterDay = day;
    }
    return self;
}

- (NSArray<Receipt *> *)visibleReceipts {
    if (self.filtersByType) return [[ReceiptStore sharedStore] receiptsOfType:self.filterType];
    if (self.filterDay) return [[ReceiptStore sharedStore] receiptsOnDay:self.filterDay];
    return [ReceiptStore sharedStore].receipts;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.filtersByType) {
        self.title = ReceiptTypeDisplayName(self.filterType);
    } else if (self.filterDay) {
        self.title = [self dayTitleForDate:self.filterDay];
    } else {
        self.title = @"收据";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                 target:self
                                 action:@selector(addTapped)];
    }

    [self.tableView registerClass:[ReceiptCell class] forCellReuseIdentifier:@"ReceiptCell"];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 88;
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.tableHeaderView = [self buildSummaryHeader];
    [self.tableView reloadData];
    [self updateEmptyState];
}

- (void)addTapped {
    AddReceiptViewController *add = [[AddReceiptViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    add.onSave = ^{
        [weakSelf.tableView reloadData];
    };
    [self.navigationController pushViewController:add animated:YES];
}

- (void)updateEmptyState {
    if (self.visibleReceipts.count == 0) {
        UILabel *label = [[UILabel alloc] init];
        label.text = (self.filtersByType || self.filterDay)
            ? @"暂无记录"
            : @"还没有票据\n点右上角 + 或「扫描」页添加第一张";
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor secondaryLabelColor];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.tableView.backgroundView = label;
    } else {
        self.tableView.backgroundView = nil;
    }
}

- (UIView *)buildSummaryHeader {
    if (!self.filtersByType && !self.filterDay) return nil;
    NSArray<Receipt *> *receipts = self.visibleReceipts;
    if (receipts.count == 0) return nil;

    double total = 0;
    for (Receipt *receipt in receipts) total += receipt.amount;

    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 100)];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 14, width - 40, 16)];
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    title.textColor = [UIColor secondaryLabelColor];
    title.text = self.filtersByType
        ? [NSString stringWithFormat:@"%@支出", ReceiptTypeDisplayName(self.filterType)]
        : @"当日支出";

    UILabel *value = [[UILabel alloc] initWithFrame:CGRectMake(20, 30, width - 40, 38)];
    value.font = [UIFont monospacedDigitSystemFontOfSize:30 weight:UIFontWeightSemibold];
    value.textColor = [UIColor labelColor];
    value.text = [NSString stringWithFormat:@"¥%.2f", total];

    NSString *subtitleText;
    if (self.filtersByType) {
        double allTotal = [ReceiptStore sharedStore].totalAmount;
        double percent = allTotal > 0 ? total / allTotal * 100.0 : 0;
        subtitleText = [NSString stringWithFormat:@"%ld 笔 · 占总支出 %.0f%%", (long)receipts.count, percent];
    } else {
        subtitleText = [NSString stringWithFormat:@"%ld 笔", (long)receipts.count];
    }
    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, width - 40, 14)];
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    subtitle.textColor = [UIColor secondaryLabelColor];
    subtitle.text = subtitleText;

    [container addSubview:title];
    [container addSubview:value];
    [container addSubview:subtitle];
    return container;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.visibleReceipts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReceiptCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReceiptCell" forIndexPath:indexPath];
    Receipt *receipt = self.visibleReceipts[indexPath.row];
    [cell configureWithReceipt:receipt store:[ReceiptStore sharedStore]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Receipt *receipt = self.visibleReceipts[indexPath.row];
    ReceiptDetailViewController *detail = [[ReceiptDetailViewController alloc] initWithReceipt:receipt];
    [self.navigationController pushViewController:detail animated:YES];
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    Receipt *receipt = self.visibleReceipts[indexPath.row];
    [[ReceiptStore sharedStore] deleteReceipt:receipt];
    [self.tableView reloadData];
    [self updateEmptyState];
}

@end
