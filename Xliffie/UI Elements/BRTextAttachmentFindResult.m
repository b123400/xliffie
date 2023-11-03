//
//  BRTextAttachmentFindResult.m
//  Xliffie
//
//  Created by b123400 on 2023/10/31.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "BRTextAttachmentFindResult.h"

@implementation BRTextAttachmentFindResult

- (NSString *)description {
    return [NSString stringWithFormat:@"BRTextAttachmentFindResult: cell(%@) range(%@) rangeOfCell(%@) highlighted(%@)", self.cell.text, NSStringFromRange(self.range), NSStringFromRange(self.rangeOfAttachment), [self highlightedTextInCell]];
}

- (NSString *)highlightedTextInCell {
    if (!self.cell) {
        return [[self.sourceText attributedSubstringFromRange:self.range] string];
    }
    return [self.cell.text substringWithRange:self.range];
}

@end
