//
//  RoundedCornersView.h
//  Xliffie
//
//  Created by b123400 on 2022/12/06.
//  Copyright © 2022 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RoundedCornersView : NSView

@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong, nullable) NSColor *backgroundColor;

@end

NS_ASSUME_NONNULL_END
