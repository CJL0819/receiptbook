// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Receipt.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReceiptStore : NSObject

@property (nonatomic, strong, readonly) NSArray<Receipt *> *receipts;

+ (instancetype)sharedStore;

- (nullable UIImage *)imageForReceipt:(Receipt *)receipt page:(NSInteger)page;
- (NSArray<UIImage *> *)imagesForReceipt:(Receipt *)receipt;

- (nullable Receipt *)addReceiptWithType:(ReceiptType)type
                                    date:(NSDate *)date
                                  amount:(double)amount
                                merchant:(NSString *)merchant
                                    note:(NSString *)note
                                  images:(NSArray<UIImage *> *)images
                                   error:(NSError * _Nullable * _Nullable)error;

- (void)deleteReceipt:(Receipt *)receipt;

- (double)totalAmount;
- (double)totalAmountOnDay:(NSDate *)day;
- (double)totalAmountInMonthOf:(NSDate *)day;
- (NSDictionary<NSNumber *, NSNumber *> *)totalByType;
- (NSArray<Receipt *> *)receiptsOnDay:(NSDate *)day;
- (NSArray<Receipt *> *)receiptsOfType:(ReceiptType)type;
- (NSArray<NSDate *> *)distinctDaysWithReceipts;
- (NSInteger)receiptCountInMonthOf:(NSDate *)day;

@end

NS_ASSUME_NONNULL_END
