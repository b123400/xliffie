//
//  ProgressLoadingWindowController.h
//  Xliffie
//
//  Created by b123400 on 2024/02/25.
//  Copyright © 2024 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgressLoadingWindowController : NSWindowController

- (instancetype)initWithProgress:(NSProgress *)progress;

@end

NS_ASSUME_NONNULL_END
