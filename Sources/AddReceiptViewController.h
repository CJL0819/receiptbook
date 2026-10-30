// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import <UIKit/UIKit.h>

@interface AddReceiptViewController : UIViewController
@property (nonatomic, copy) void (^onSave)(void);
@end
