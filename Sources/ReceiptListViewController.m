// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "ReceiptListViewController.h"
#import "ReceiptStore.h"
#import "Receipt.h"
#import "ReceiptCell.h"
#import "AddReceiptViewController.h"
#import "ReceiptDetailViewController.h"

@implementation ReceiptListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"收据";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                             target:self
                             action:@selector(addTapped)];
    [self.tableView registerClass:[ReceiptCell class] forCellReuseIdentifier:@"ReceiptCell"];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 88;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    if ([ReceiptStore sharedStore].receipts.count == 0) {
        UILabel *label = [[UILabel alloc] init];
        label.text = @"还没有票据\n点右上角 + 或「扫描」页添加第一张";
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor secondaryLabelColor];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.tableView.backgroundView = label;
    } else {
        self.tableView.backgroundView = nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [ReceiptStore sharedStore].receipts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReceiptCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReceiptCell" forIndexPath:indexPath];
    Receipt *receipt = [ReceiptStore sharedStore].receipts[indexPath.row];
    [cell configureWithReceipt:receipt store:[ReceiptStore sharedStore]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Receipt *receipt = [ReceiptStore sharedStore].receipts[indexPath.row];
    ReceiptDetailViewController *detail = [[ReceiptDetailViewController alloc] initWithReceipt:receipt];
    [self.navigationController pushViewController:detail animated:YES];
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    Receipt *receipt = [ReceiptStore sharedStore].receipts[indexPath.row];
    [[ReceiptStore sharedStore] deleteReceipt:receipt];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateEmptyState];
}

@end
