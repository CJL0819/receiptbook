// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import <Foundation/Foundation.h>

@class UIColor;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ReceiptType) {
    ReceiptTypeInvoice = 0,
    ReceiptTypeReceipt,
    ReceiptTypeFlight,
    ReceiptTypeToll,
    ReceiptTypeOther
};

NSString *ReceiptTypeDisplayName(ReceiptType type);
NSString *ReceiptTypeSymbolName(ReceiptType type);
UIColor *ReceiptTypeTintColor(ReceiptType type);

/// 一张票据：日期、金额、商家、备注，以及扫描页数。
/// 图片本体由 ReceiptStore 按页保存在磁盘上，这里只记录页数。
@interface Receipt : NSObject

@property (nonatomic, copy) NSString *receiptID;
@property (nonatomic, assign) ReceiptType type;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) double amount;
@property (nonatomic, copy) NSString *merchant;
@property (nonatomic, copy) NSString *note;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, strong) NSDate *createdAt;

- (instancetype)initWithType:(ReceiptType)type
                        date:(NSDate *)date
                      amount:(double)amount
                    merchant:(NSString *)merchant
                        note:(NSString *)note
                   pageCount:(NSInteger)pageCount;

- (NSDictionary *)dictionaryRepresentation;
+ (nullable instancetype)receiptFromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
