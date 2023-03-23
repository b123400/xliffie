//
//  ProgressWindowController.h
//  Xliffie
//
//  Created by b123400 on 2023/03/22.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProgressWindowController : NSWindowController

- (instancetype)initWithDocument:(Document *)doc;

@end

NS_ASSUME_NONNULL_END
