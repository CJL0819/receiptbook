// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "ReceiptOCR.h"
#import <Vision/Vision.h>

@implementation ReceiptOCRResult

- (instancetype)init {
    self = [super init];
    if (self) {
        _amount = 0;
        _merchant = @"";
        _summary = @"";
        _rawText = @"";
    }
    return self;
}

@end

@implementation ReceiptOCR

+ (ReceiptOCRResult *)analyzeImages:(NSArray<UIImage *> *)images {
    ReceiptOCRResult *result = [[ReceiptOCRResult alloc] init];
    NSMutableArray<NSString *> *allLines = [NSMutableArray array];
    for (UIImage *image in images) {
        [allLines addObjectsFromArray:[self recognizedLinesInImage:image]];
    }
    result.rawText = [allLines componentsJoinedByString:@"\n"];
    result.amount = [self extractAmountFromLines:allLines];
    result.merchant = [self extractMerchantFromLines:allLines];
    result.date = [self extractDateFromLines:allLines];
    result.summary = [self buildSummaryWithAmount:result.amount merchant:result.merchant];
    return result;
}

#pragma mark - OCR

+ (NSArray<NSString *> *)recognizedLinesInImage:(UIImage *)image {
    if (!image.CGImage) return @[];

    VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] init];
    request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
    request.recognitionLanguages = @[@"zh-Hans", @"en-US"];
    request.usesLanguageCorrection = YES;

    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
    NSError *error = nil;
    [handler performRequests:@[request] error:&error];
    if (error) {
        NSLog(@"ReceiptOCR error: %@", error.localizedDescription);
        return @[];
    }

    NSArray<VNRecognizedTextObservation *> *observations = request.results;
    // 按从上到下排序：Vision 的 boundingBox 原点在左下，y 越大越靠上。
    NSArray *sorted = [observations sortedArrayUsingComparator:^NSComparisonResult(VNRecognizedTextObservation *a, VNRecognizedTextObservation *b) {
        if (a.boundingBox.origin.y > b.boundingBox.origin.y) return NSOrderedAscending;
        if (a.boundingBox.origin.y < b.boundingBox.origin.y) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    for (VNRecognizedTextObservation *observation in sorted) {
        VNRecognizedText *candidate = [observation topCandidates:1].firstObject;
        if (candidate && candidate.string.length > 0) {
            [lines addObject:candidate.string];
        }
    }
    return lines;
}

#pragma mark - 抽取规则

+ (double)extractAmountFromLines:(NSArray<NSString *> *)lines {
    NSArray<NSString *> *keywords = @[
        @"合计", @"总计", @"应付", @"应收", @"实收", @"实付",
        @"消费金额", @"应付金额", @"实付金额", @"金额",
        @"total", @"amount", @"sum", @"grand"
    ];
    for (NSString *line in lines) {
        NSString *lower = [line lowercaseString];
        BOOL hitKeyword = NO;
        for (NSString *keyword in keywords) {
            if ([lower containsString:keyword]) {
                hitKeyword = YES;
                break;
            }
        }
        BOOL hasSymbol = [line containsString:@"¥"] || [line containsString:@"￥"];
        if (!hitKeyword && !hasSymbol) continue;

        NSNumber *number = [self lastNumberInString:line];
        if (number && number.doubleValue > 0) {
            return number.doubleValue;
        }
    }
    return 0;
}

+ (NSString *)extractMerchantFromLines:(NSArray<NSString *> *)lines {
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0 && trimmed.length <= 30) {
            return trimmed;
        }
    }
    return @"";
}

+ (NSDate *)extractDateFromLines:(NSArray<NSString *> *)lines {
    for (NSString *line in lines) {
        NSDate *date = [self parseDateFromString:line];
        if (date) return date;
    }
    return nil;
}

+ (NSString *)buildSummaryWithAmount:(double)amount merchant:(NSString *)merchant {
    if (amount > 0 && merchant.length > 0) {
        return [NSString stringWithFormat:@"%@ 消费 ¥%.2f", merchant, amount];
    }
    if (amount > 0) {
        return [NSString stringWithFormat:@"消费 ¥%.2f", amount];
    }
    if (merchant.length > 0) {
        return merchant;
    }
    return @"";
}

#pragma mark - Helpers

+ (NSNumber *)lastNumberInString:(NSString *)string {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d[\\d,]*(?:\\.\\d+)?"
                                                                           options:0
                                                                             error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:string
                                                             options:0
                                                               range:NSMakeRange(0, string.length)];
    NSNumber *value = nil;
    for (NSTextCheckingResult *match in matches) {
        NSString *numberString = [string substringWithRange:match.range];
        numberString = [numberString stringByReplacingOccurrencesOfString:@"," withString:@""];
        value = @(numberString.doubleValue);
    }
    return value;
}

+ (NSDate *)parseDateFromString:(NSString *)string {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger year = 0, month = 0, day = 0;

    NSRegularExpression *fullRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{4})[年/\\-](\\d{1,2})[月/\\-](\\d{1,2})"
                                                                               options:0
                                                                                 error:nil];
    NSTextCheckingResult *fullMatch = [fullRegex firstMatchInString:string
                                                            options:0
                                                              range:NSMakeRange(0, string.length)];
    if (fullMatch) {
        year = [[string substringWithRange:[fullMatch rangeAtIndex:1]] integerValue];
        month = [[string substringWithRange:[fullMatch rangeAtIndex:2]] integerValue];
        day = [[string substringWithRange:[fullMatch rangeAtIndex:3]] integerValue];
    } else {
        NSRegularExpression *mdRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,2})月(\\d{1,2})日"
                                                                                 options:0
                                                                                   error:nil];
        NSTextCheckingResult *mdMatch = [mdRegex firstMatchInString:string
                                                            options:0
                                                              range:NSMakeRange(0, string.length)];
        if (!mdMatch) return nil;
        year = [calendar component:NSCalendarUnitYear fromDate:[NSDate date]];
        month = [[string substringWithRange:[mdMatch rangeAtIndex:1]] integerValue];
        day = [[string substringWithRange:[mdMatch rangeAtIndex:2]] integerValue];
    }

    NSInteger hour = 0, minute = 0;
    NSRegularExpression *timeRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,2}):(\\d{2})"
                                                                               options:0
                                                                                 error:nil];
    NSTextCheckingResult *timeMatch = [timeRegex firstMatchInString:string
                                                            options:0
                                                              range:NSMakeRange(0, string.length)];
    if (timeMatch) {
        hour = [[string substringWithRange:[timeMatch rangeAtIndex:1]] integerValue];
        minute = [[string substringWithRange:[timeMatch rangeAtIndex:2]] integerValue];
    }

    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = hour;
    components.minute = minute;
    return [calendar dateFromComponents:components];
}

@end
