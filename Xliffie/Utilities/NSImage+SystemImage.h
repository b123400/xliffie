//
//  NSImage+SystemImage.h
//  Xliffie
//
//  Created by b123400 on 2023/04/06.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (SystemImage)

+ (NSImage *)systemImageWithFallbackNamed:(NSString *)name;
- (NSImage *)tintedImageWithColor:(NSColor *)color;

@end

NS_ASSUME_NONNULL_END
