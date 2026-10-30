// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "ReceiptStore.h"

@interface ReceiptStore ()
@property (nonatomic, strong) NSMutableArray<Receipt *> *mutableReceipts;
@property (nonatomic, strong) NSURL *indexURL;
@property (nonatomic, strong) NSURL *imagesRootURL;
@end

@implementation ReceiptStore

+ (instancetype)sharedStore {
    static ReceiptStore *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ReceiptStore alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURL *docs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                             inDomains:NSUserDomainMask].firstObject;
        _indexURL = [docs URLByAppendingPathComponent:@"receipts.json"];
        _imagesRootURL = [docs URLByAppendingPathComponent:@"Receipts" isDirectory:YES];
        _mutableReceipts = [NSMutableArray array];
        [self load];
    }
    return self;
}

- (NSArray<Receipt *> *)receipts {
    return [self.mutableReceipts copy];
}

- (void)load {
    NSData *data = [NSData dataWithContentsOfURL:self.indexURL];
    if (!data) return;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![object isKindOfClass:[NSArray class]]) return;
    for (NSDictionary *dict in object) {
        Receipt *receipt = [Receipt receiptFromDictionary:dict];
        if (receipt) [self.mutableReceipts addObject:receipt];
    }
    [self sort];
}

- (void)sort {
    [self.mutableReceipts sortUsingComparator:^NSComparisonResult(Receipt *a, Receipt *b) {
        return [b.date compare:a.date];
    }];
}

- (void)persist {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.mutableReceipts.count];
    for (Receipt *receipt in self.mutableReceipts) {
        [array addObject:[receipt dictionaryRepresentation]];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:nil];
    if (data) [data writeToURL:self.indexURL atomically:YES];
}

- (NSURL *)directoryForReceipt:(Receipt *)receipt {
    return [self.imagesRootURL URLByAppendingPathComponent:receipt.receiptID isDirectory:YES];
}

- (UIImage *)imageForReceipt:(Receipt *)receipt page:(NSInteger)page {
    NSURL *url = [[self directoryForReceipt:receipt]
        URLByAppendingPathComponent:[NSString stringWithFormat:@"page%ld.jpg", (long)page]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    return data ? [UIImage imageWithData:data] : nil;
}

- (NSArray<UIImage *> *)imagesForReceipt:(Receipt *)receipt {
    NSMutableArray *images = [NSMutableArray array];
    for (NSInteger i = 0; i < receipt.pageCount; i++) {
        UIImage *image = [self imageForReceipt:receipt page:i];
        if (image) [images addObject:image];
    }
    return images;
}

- (Receipt *)addReceiptWithType:(ReceiptType)type
                           date:(NSDate *)date
                         amount:(double)amount
                       merchant:(NSString *)merchant
                           note:(NSString *)note
                         images:(NSArray<UIImage *> *)images
                          error:(NSError **)error {
    Receipt *receipt = [[Receipt alloc] initWithType:type
                                                date:date
                                              amount:amount
                                            merchant:merchant
                                                note:note
                                           pageCount:images.count];
    NSURL *dir = [self directoryForReceipt:receipt];
    if (![[NSFileManager defaultManager] createDirectoryAtURL:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:error]) {
        return nil;
    }
    for (NSInteger i = 0; i < (NSInteger)images.count; i++) {
        NSData *data = UIImageJPEGRepresentation(images[i], 0.85);
        if (data) {
            NSURL *url = [dir URLByAppendingPathComponent:[NSString stringWithFormat:@"page%ld.jpg", (long)i]];
            if (![data writeToURL:url options:NSDataWritingAtomic error:error]) {
                return nil;
            }
        }
    }
    [self.mutableReceipts addObject:receipt];
    [self sort];
    [self persist];
    return receipt;
}

- (void)deleteReceipt:(Receipt *)receipt {
    [self.mutableReceipts removeObject:receipt];
    [[NSFileManager defaultManager] removeItemAtURL:[self directoryForReceipt:receipt] error:nil];
    [self persist];
}

- (double)totalAmount {
    double total = 0;
    for (Receipt *receipt in self.mutableReceipts) {
        total += receipt.amount;
    }
    return total;
}

- (double)totalAmountOnDay:(NSDate *)day {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    double total = 0;
    for (Receipt *receipt in self.mutableReceipts) {
        if ([calendar isDate:receipt.date inSameDayAsDate:day]) {
            total += receipt.amount;
        }
    }
    return total;
}

- (double)totalAmountInMonthOf:(NSDate *)day {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    double total = 0;
    for (Receipt *receipt in self.mutableReceipts) {
        if ([calendar isDate:receipt.date equalToDate:day toUnitGranularity:NSCalendarUnitMonth]) {
            total += receipt.amount;
        }
    }
    return total;
}

- (NSDictionary<NSNumber *, NSNumber *> *)totalByType {
    NSMutableDictionary<NSNumber *, NSNumber *> *result = [NSMutableDictionary dictionary];
    for (Receipt *receipt in self.mutableReceipts) {
        NSNumber *key = @(receipt.type);
        double current = [result[key] doubleValue];
        result[key] = @(current + receipt.amount);
    }
    return result;
}

- (NSArray<Receipt *> *)receiptsOnDay:(NSDate *)day {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSMutableArray *result = [NSMutableArray array];
    for (Receipt *receipt in self.mutableReceipts) {
        if ([calendar isDate:receipt.date inSameDayAsDate:day]) {
            [result addObject:receipt];
        }
    }
    return result;
}

- (NSArray<Receipt *> *)receiptsOfType:(ReceiptType)type {
    NSMutableArray *result = [NSMutableArray array];
    for (Receipt *receipt in self.mutableReceipts) {
        if (receipt.type == type) {
            [result addObject:receipt];
        }
    }
    return result;
}

- (NSArray<NSDate *> *)distinctDaysWithReceipts {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSMutableSet<NSDate *> *days = [NSMutableSet set];
    for (Receipt *receipt in self.mutableReceipts) {
        [days addObject:[calendar startOfDayForDate:receipt.date]];
    }
    return [days.allObjects sortedArrayUsingComparator:^NSComparisonResult(NSDate *a, NSDate *b) {
        return [b compare:a];
    }];
}

- (NSInteger)receiptCountInMonthOf:(NSDate *)day {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger count = 0;
    for (Receipt *receipt in self.mutableReceipts) {
        if ([calendar isDate:receipt.date equalToDate:day toUnitGranularity:NSCalendarUnitMonth]) {
            count += 1;
        }
    }
    return count;
}

@end
