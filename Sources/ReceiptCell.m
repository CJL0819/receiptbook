// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "ReceiptCell.h"
#import "Receipt.h"
#import "ReceiptStore.h"

@interface ReceiptCell ()
@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *amountLabel;
@end

@implementation ReceiptCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.thumbnailView = [[UIImageView alloc] init];
        self.thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbnailView.clipsToBounds = YES;
        self.thumbnailView.layer.cornerRadius = 6;
        self.thumbnailView.backgroundColor = [UIColor secondarySystemBackgroundColor];
        self.thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.titleLabel.numberOfLines = 1;

        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        self.subtitleLabel.textColor = [UIColor secondaryLabelColor];
        self.subtitleLabel.numberOfLines = 1;

        self.amountLabel = [[UILabel alloc] init];
        self.amountLabel.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightMedium];
        self.amountLabel.textAlignment = NSTextAlignmentRight;
        [self.amountLabel setContentHuggingPriority:UILayoutPriorityRequired
                                           forAxis:UILayoutConstraintAxisHorizontal];
        self.amountLabel.translatesAutoresizingMaskIntoConstraints = NO;

        UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.titleLabel, self.subtitleLabel]];
        textStack.axis = UILayoutConstraintAxisVertical;
        textStack.spacing = 2;
        textStack.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:self.thumbnailView];
        [self.contentView addSubview:textStack];
        [self.contentView addSubview:self.amountLabel];

        [NSLayoutConstraint activateConstraints:@[
            [self.thumbnailView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [self.thumbnailView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
            [self.thumbnailView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8],
            [self.thumbnailView.widthAnchor constraintEqualToConstant:56],
            [self.thumbnailView.heightAnchor constraintEqualToConstant:72],

            [textStack.leadingAnchor constraintEqualToAnchor:self.thumbnailView.trailingAnchor constant:12],
            [textStack.centerYAnchor constraintEqualToAnchor:self.thumbnailView.centerYAnchor],
            [textStack.trailingAnchor constraintLessThanOrEqualToAnchor:self.amountLabel.leadingAnchor constant:-8],

            [self.amountLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [self.amountLabel.centerYAnchor constraintEqualToAnchor:self.thumbnailView.centerYAnchor],
        ]];
    }
    return self;
}

- (void)configureWithReceipt:(Receipt *)receipt store:(ReceiptStore *)store {
    self.titleLabel.text = receipt.merchant.length > 0
        ? [NSString stringWithFormat:@"%@ · %@", ReceiptTypeDisplayName(receipt.type), receipt.merchant]
        : ReceiptTypeDisplayName(receipt.type);

    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"M月d日 HH:mm";
    });
    self.subtitleLabel.text = [formatter stringFromDate:receipt.date];
    self.amountLabel.text = [NSString stringWithFormat:@"¥%.2f", receipt.amount];

    UIImage *image = [store imageForReceipt:receipt page:0];
    self.thumbnailView.image = image ?: [UIImage systemImageNamed:@"doc.text.image"];
}

@end
