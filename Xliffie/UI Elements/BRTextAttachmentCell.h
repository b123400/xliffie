//
//  MyTextAttachmentCell.h
//  Xliffie
//
//  Created by b123400 on 2023/10/17.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BRTextAttachmentCell : NSTextAttachmentCell

@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) BOOL strokeInsteadOfFill;

+ (NSString *)stringForAttributedString:(NSAttributedString *)input;

@end

NS_ASSUME_NONNULL_END
