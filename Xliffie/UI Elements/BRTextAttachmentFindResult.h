//
//  BRTextAttachmentFindResult.h
//  Xliffie
//
//  Created by b123400 on 2023/10/31.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BRTextAttachmentCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface BRTextAttachmentFindResult : NSObject

@property (nonatomic, nullable, strong) BRTextAttachmentCell *cell;
@property (nonatomic, assign) NSRange rangeOfAttachment;

// when cell is nonnull, range is relative to the cell's text
// when cell is null, range is relative to the source attributed string
@property (nonatomic, assign) NSRange range;
@property (nonatomic, assign) NSAttributedString *sourceText;

@end

NS_ASSUME_NONNULL_END
