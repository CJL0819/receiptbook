// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "AddReceiptViewController.h"
#import <VisionKit/VisionKit.h>
#import "ReceiptStore.h"
#import "Receipt.h"
#import "ReceiptOCR.h"

@interface AddReceiptViewController () <VNDocumentCameraViewControllerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UIButton *scanButton;
@property (nonatomic, strong) UILabel *scanStatusLabel;
@property (nonatomic, strong) UIStackView *previewStack;
@property (nonatomic, strong) UISegmentedControl *typeControl;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UITextField *amountField;
@property (nonatomic, strong) UITextField *merchantField;
@property (nonatomic, strong) UITextField *noteField;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) NSMutableArray<UIImage *> *scannedImages;
@end

@implementation AddReceiptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"添加票据";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.scannedImages = [NSMutableArray array];
    [self buildUI];
    [self resetForm];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)buildUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor],
    ]];

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 16;
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentStack];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:16],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor constant:16],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor constant:-16],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-16],
        [self.contentStack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor constant:-32],
    ]];

    self.scanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *scanConfig = [UIButtonConfiguration filledButtonConfiguration];
    scanConfig.title = @"扫描票据";
    scanConfig.image = [UIImage systemImageNamed:@"camera.viewfinder"];
    scanConfig.imagePadding = 8;
    scanConfig.baseBackgroundColor = [UIColor systemBlueColor];
    self.scanButton.configuration = scanConfig;
    [self.scanButton addTarget:self action:@selector(scanTapped) forControlEvents:UIControlEventTouchUpInside];

    self.scanStatusLabel = [[UILabel alloc] init];
    self.scanStatusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.scanStatusLabel.textColor = [UIColor secondaryLabelColor];
    self.scanStatusLabel.numberOfLines = 0;

    self.previewStack = [[UIStackView alloc] init];
    self.previewStack.axis = UILayoutConstraintAxisHorizontal;
    self.previewStack.spacing = 8;
    self.previewStack.alignment = UIStackViewAlignmentLeading;

    NSArray *typeNames = @[
        ReceiptTypeDisplayName(ReceiptTypeInvoice),
        ReceiptTypeDisplayName(ReceiptTypeReceipt),
        ReceiptTypeDisplayName(ReceiptTypeFlight),
        ReceiptTypeDisplayName(ReceiptTypeToll),
        ReceiptTypeDisplayName(ReceiptTypeOther)
    ];
    self.typeControl = [[UISegmentedControl alloc] initWithItems:typeNames];

    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    self.datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    self.datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];

    self.amountField = [[UITextField alloc] init];
    self.merchantField = [[UITextField alloc] init];
    self.noteField = [[UITextField alloc] init];

    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *saveConfig = [UIButtonConfiguration filledButtonConfiguration];
    saveConfig.title = @"保存";
    saveConfig.baseBackgroundColor = [UIColor systemGreenColor];
    self.saveButton.configuration = saveConfig;
    [self.saveButton addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.contentStack addArrangedSubview:self.scanButton];
    [self.contentStack addArrangedSubview:self.scanStatusLabel];
    [self.contentStack addArrangedSubview:self.previewStack];
    [self.contentStack addArrangedSubview:[self sectionLabel:@"类型"]];
    [self.contentStack addArrangedSubview:self.typeControl];
    [self.contentStack addArrangedSubview:[self sectionLabel:@"日期"]];
    [self.contentStack addArrangedSubview:self.datePicker];
    [self.contentStack addArrangedSubview:[self fieldRowWithTitle:@"金额（元）" field:self.amountField placeholder:@"0.00" keyboard:UIKeyboardTypeDecimalPad]];
    [self.contentStack addArrangedSubview:[self fieldRowWithTitle:@"商家 / 抬头" field:self.merchantField placeholder:@"例如：全家便利店" keyboard:UIKeyboardTypeDefault]];
    [self.contentStack addArrangedSubview:[self fieldRowWithTitle:@"备注" field:self.noteField placeholder:@"可选" keyboard:UIKeyboardTypeDefault]];
    [self.contentStack addArrangedSubview:self.saveButton];
}

- (UILabel *)sectionLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.textColor = [UIColor secondaryLabelColor];
    return label;
}

- (UIStackView *)fieldRowWithTitle:(NSString *)title
                             field:(UITextField *)field
                       placeholder:(NSString *)placeholder
                          keyboard:(UIKeyboardType)keyboard {
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.textColor = [UIColor secondaryLabelColor];

    field.placeholder = placeholder;
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.keyboardType = keyboard;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.delegate = self;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[label, field]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 6;
    return stack;
}

- (void)resetForm {
    [self.scannedImages removeAllObjects];
    self.typeControl.selectedSegmentIndex = 0;
    self.datePicker.date = [NSDate date];
    self.amountField.text = @"";
    self.merchantField.text = @"";
    self.noteField.text = @"";
    [self refreshPreview];
}

- (void)refreshPreview {
    for (UIView *subview in self.previewStack.arrangedSubviews) {
        [self.previewStack removeArrangedSubview:subview];
        [subview removeFromSuperview];
    }
    if (self.scannedImages.count == 0) {
        self.scanStatusLabel.text = @"尚未扫描。点击上方按钮，用相机拍摄并裁剪票据。";
    } else {
        self.scanStatusLabel.text = [NSString stringWithFormat:@"已扫描 %lu 页", (unsigned long)self.scannedImages.count];
        for (UIImage *image in self.scannedImages) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            imageView.layer.cornerRadius = 6;
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [imageView.widthAnchor constraintEqualToConstant:90],
                [imageView.heightAnchor constraintEqualToConstant:120],
            ]];
            [self.previewStack addArrangedSubview:imageView];
        }
    }
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    CGRect fieldRect = [textField convertRect:textField.bounds toView:self.scrollView];
    fieldRect.origin.y -= 12;
    fieldRect.size.height += 24;
    [self.scrollView scrollRectToVisible:fieldRect animated:YES];
}

- (void)runOCROnScannedImages {
    NSArray<UIImage *> *images = [self.scannedImages copy];
    if (images.count == 0) return;
    self.scanStatusLabel.text = @"正在识别票据…";
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        ReceiptOCRResult *result = [ReceiptOCR analyzeImages:images];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf applyOCRResult:result];
        });
    });
}

- (void)applyOCRResult:(ReceiptOCRResult *)result {
    BOOL foundAny = NO;
    if (result.amount > 0 && self.amountField.text.length == 0) {
        self.amountField.text = [NSString stringWithFormat:@"%.2f", result.amount];
        foundAny = YES;
    }
    if (result.merchant.length > 0 && self.merchantField.text.length == 0) {
        self.merchantField.text = result.merchant;
        foundAny = YES;
    }
    if (result.date) {
        self.datePicker.date = result.date;
        foundAny = YES;
    }
    if (result.summary.length > 0 && self.noteField.text.length == 0) {
        self.noteField.text = result.summary;
        foundAny = YES;
    }
    self.scanStatusLabel.text = foundAny
        ? @"已识别，请核对下方信息后保存。"
        : @"未能自动识别金额/商家，请手动填写。";
}

- (void)scanTapped {
    [self dismissKeyboard];
    if (![VNDocumentCameraViewController isSupported]) {
        [self showAlert:@"当前设备不支持文稿扫描"];
        return;
    }
    VNDocumentCameraViewController *scanner = [[VNDocumentCameraViewController alloc] init];
    scanner.delegate = self;
    [self presentViewController:scanner animated:YES completion:nil];
}

- (void)saveTapped {
    [self dismissKeyboard];
    NSString *amountText = [self.amountField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSScanner *scanner = [NSScanner scannerWithString:amountText];
    scanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    double amount = 0;
    BOOL scanned = [scanner scanDouble:&amount];
    if (!scanned || ![scanner isAtEnd] || amount < 0) {
        [self showAlert:@"请输入正确的金额（仅数字）"];
        return;
    }

    ReceiptType type = (ReceiptType)self.typeControl.selectedSegmentIndex;
    NSError *error = nil;
    [[ReceiptStore sharedStore] addReceiptWithType:type
                                              date:self.datePicker.date
                                            amount:amount
                                          merchant:[self.merchantField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ?: @""
                                              note:[self.noteField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] ?: @""
                                            images:self.scannedImages
                                             error:&error];
    if (error) {
        [self showAlert:[NSString stringWithFormat:@"保存失败：%@", error.localizedDescription]];
        return;
    }
    if (self.onSave) self.onSave();
    [self resetForm];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已保存"
                                                                   message:@"票据已加入收纳。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        (void)action;
        if (weakSelf.navigationController.viewControllers.count > 1) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - VNDocumentCameraViewControllerDelegate

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller
                   didFinishWithScan:(VNDocumentCameraScan *)scan {
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:scan.pageCount];
    for (NSUInteger i = 0; i < scan.pageCount; i++) {
        [images addObject:[scan imageOfPageAtIndex:i]];
    }
    [controller dismissViewControllerAnimated:YES completion:^{
        self.scannedImages = images;
        [self refreshPreview];
        [self runOCROnScannedImages];
    }];
}

- (void)documentCameraViewControllerDidCancel:(VNDocumentCameraViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller
                   didFailWithError:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:^{
        [self showAlert:[NSString stringWithFormat:@"扫描失败：%@", error.localizedDescription]];
    }];
}

@end
