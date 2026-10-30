// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "ReceiptDetailViewController.h"
#import "ReceiptStore.h"
#import "Receipt.h"

@interface ReceiptDetailViewController ()
@property (nonatomic, strong) Receipt *receipt;
@end

@implementation ReceiptDetailViewController

- (instancetype)initWithReceipt:(Receipt *)receipt {
    self = [super init];
    if (self) {
        _receipt = receipt;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"票据详情";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                             target:self
                             action:@selector(deleteTapped)];
    [self buildUI];
}

- (void)buildUI {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-16],
        [stack.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-32],
    ]];

    NSArray<UIImage *> *images = [[ReceiptStore sharedStore] imagesForReceipt:self.receipt];
    if (images.count == 0) {
        UIImageView *placeholder = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"doc.text.image"]];
        placeholder.contentMode = UIViewContentModeScaleAspectFit;
        placeholder.tintColor = [UIColor secondaryLabelColor];
        placeholder.translatesAutoresizingMaskIntoConstraints = NO;
        [placeholder.heightAnchor constraintEqualToConstant:220].active = YES;
        [stack addArrangedSubview:placeholder];
    } else {
        for (UIImage *image in images) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.backgroundColor = [UIColor secondarySystemBackgroundColor];
            imageView.layer.cornerRadius = 8;
            imageView.clipsToBounds = YES;
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            [imageView.heightAnchor constraintEqualToConstant:260].active = YES;
            [stack addArrangedSubview:imageView];
        }
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;

    [stack addArrangedSubview:[self infoRowWithTitle:@"类型" value:ReceiptTypeDisplayName(self.receipt.type)]];
    [stack addArrangedSubview:[self infoRowWithTitle:@"日期" value:[formatter stringFromDate:self.receipt.date]]];
    [stack addArrangedSubview:[self infoRowWithTitle:@"金额" value:[NSString stringWithFormat:@"¥%.2f", self.receipt.amount]]];
    [stack addArrangedSubview:[self infoRowWithTitle:@"商家 / 抬头" value:self.receipt.merchant.length > 0 ? self.receipt.merchant : @"—"]];
    if (self.receipt.note.length > 0) {
        [stack addArrangedSubview:[self infoRowWithTitle:@"备注" value:self.receipt.note]];
    }
}

- (UIView *)infoRowWithTitle:(NSString *)title value:(NSString *)value {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    titleLabel.textColor = [UIColor secondaryLabelColor];

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.text = value;
    valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    valueLabel.numberOfLines = 0;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, valueLabel]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 2;
    return stack;
}

- (void)deleteTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除票据"
                                                                   message:@"删除后无法恢复。"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        (void)action;
        [[ReceiptStore sharedStore] deleteReceipt:weakSelf.receipt];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
