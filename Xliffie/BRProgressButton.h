//
//  BRProgressButton.h
//  Xliffie
//
//  Created by b123400 on 2023/03/22.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface BRProgressButton : NSButton

- (void)addSegmentWithProgress:(double)progress colour:(NSColor *)colour;
- (void)resetSegments;

@end

NS_ASSUME_NONNULL_END
