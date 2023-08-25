//
//  GlossaryManagerWindowController.h
//  Xliffie
//
//  Created by b123400 on 2023/07/29.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface GlossaryManagerWindowController : NSWindowController

+ (instancetype)shared;
- (void)showDownloadSheet;

@end

NS_ASSUME_NONNULL_END
