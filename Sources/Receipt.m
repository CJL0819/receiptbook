// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "Receipt.h"

NSString *ReceiptTypeDisplayName(ReceiptType type) {
    switch (type) {
        case ReceiptTypeInvoice: return @"发票";
        case ReceiptTypeReceipt: return @"小票";
        case ReceiptTypeFlight: return @"机票";
        case ReceiptTypeToll: return @"收费条";
        case ReceiptTypeOther: return @"其他";
    }
    return @"其他";
}

@implementation Receipt

- (instancetype)initWithType:(ReceiptType)type
                        date:(NSDate *)date
                      amount:(double)amount
                    merchant:(NSString *)merchant
                        note:(NSString *)note
                   pageCount:(NSInteger)pageCount {
    self = [super init];
    if (self) {
        _receiptID = [[NSUUID UUID] UUIDString];
        _type = type;
        _date = date ?: [NSDate date];
        _amount = amount;
        _merchant = merchant ?: @"";
        _note = note ?: @"";
        _pageCount = pageCount;
        _createdAt = [NSDate date];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"id": self.receiptID,
        @"type": @(self.type),
        @"date": @(self.date.timeIntervalSince1970),
        @"amount": @(self.amount),
        @"merchant": self.merchant,
        @"note": self.note,
        @"pageCount": @(self.pageCount),
        @"createdAt": @(self.createdAt.timeIntervalSince1970)
    };
}

+ (instancetype)receiptFromDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    Receipt *receipt = [[Receipt alloc] initWithType:(ReceiptType)[dict[@"type"] integerValue]
                                                date:[NSDate dateWithTimeIntervalSince1970:[dict[@"date"] doubleValue]]
                                              amount:[dict[@"amount"] doubleValue]
                                            merchant:dict[@"merchant"] ?: @""
                                                note:dict[@"note"] ?: @""
                                           pageCount:[dict[@"pageCount"] integerValue]];
    if ([dict[@"id"] isKindOfClass:[NSString class]]) {
        receipt.receiptID = dict[@"id"];
    }
    if (dict[@"createdAt"]) {
        receipt.createdAt = [NSDate dateWithTimeIntervalSince1970:[dict[@"createdAt"] doubleValue]];
    }
    return receipt;
}

@end
