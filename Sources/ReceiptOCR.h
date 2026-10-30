// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 从票据扫描图里抽出来的信息。
@interface ReceiptOCRResult : NSObject
@property (nonatomic, assign) double amount;          // 0 表示未识别到
@property (nonatomic, copy) NSString *merchant;
@property (nonatomic, strong, nullable) NSDate *date; // 可能为 nil
@property (nonatomic, copy) NSString *summary;        // 生成的备注摘要
@property (nonatomic, copy) NSString *rawText;        // 识别出的全部文本，供以后扩展
@end

@interface ReceiptOCR : NSObject
/// 对若干张扫描图做 OCR，并用规则抽取金额/商家/日期，生成摘要。
+ (ReceiptOCRResult *)analyzeImages:(NSArray<UIImage *> *)images;
@end

NS_ASSUME_NONNULL_END
