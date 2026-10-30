// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "StatsCategoryCell.h"

@interface StatsCategoryCell ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@end

@implementation StatsCategoryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.iconView = [[UIImageView alloc] init];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        self.iconView.translatesAutoresizingMaskIntoConstraints = NO;

        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;

        self.amountLabel = [[UILabel alloc] init];
        self.amountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        self.amountLabel.textColor = [UIColor secondaryLabelColor];
        self.amountLabel.translatesAutoresizingMaskIntoConstraints = NO;

        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.progressView.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:self.iconView];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.amountLabel];
        [self.contentView addSubview:self.progressView];

        [NSLayoutConstraint activateConstraints:@[
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [self.iconView.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],
            [self.iconView.widthAnchor constraintEqualToConstant:26],
            [self.iconView.heightAnchor constraintEqualToConstant:26],

            [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:12],
            [self.nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10],
            [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.amountLabel.leadingAnchor constant:-8],

            [self.amountLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [self.amountLabel.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],

            [self.progressView.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:12],
            [self.progressView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [self.progressView.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:8],
            [self.progressView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
            [self.progressView.heightAnchor constraintEqualToConstant:4],
        ]];
    }
    return self;
}

- (void)configureWithType:(ReceiptType)type count:(NSInteger)count total:(double)total fraction:(double)fraction {
    self.iconView.image = [UIImage systemImageNamed:ReceiptTypeSymbolName(type)];
    self.iconView.tintColor = ReceiptTypeTintColor(type);
    self.nameLabel.text = ReceiptTypeDisplayName(type);
    self.amountLabel.text = [NSString stringWithFormat:@"%ld 笔 · ¥%.2f", (long)count, total];
    self.progressView.progressTintColor = ReceiptTypeTintColor(type);
    self.progressView.trackTintColor = [UIColor systemGray5Color];
    self.progressView.progress = (float)fraction;
}

@end
