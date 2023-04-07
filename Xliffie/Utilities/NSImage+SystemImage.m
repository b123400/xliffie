//
//  NSImage+SystemImage.m
//  Xliffie
//
//  Created by b123400 on 2023/04/06.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "NSImage+SystemImage.h"

@implementation NSImage (SystemImage)

+ (NSImage *)systemImageWithFallbackNamed:(NSString *)name {
    NSImage *image;
    if (@available(macOS 11.0, *)) {
        image = [NSImage imageWithSystemSymbolName:name accessibilityDescription:nil];
    }
    if (!image) {
        image = [NSImage imageNamed:name];
    }
    return image;
}

- (NSImage *)tintedImageWithColor:(NSColor *)color {
    return [NSImage imageWithSize:self.size flipped:false drawingHandler:^BOOL(NSRect dstRect) {
        [self drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        [color set];
        NSRectFillUsingOperation(dstRect, NSCompositingOperationSourceAtop);
        return YES;
    }];
}

@end
