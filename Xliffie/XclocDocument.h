//
//  XclocDocument.h
//  Xliffie
//
//  Created by Brian Chan on 2019/02/21.
//  Copyright © 2019 b123400. All rights reserved.
//

#import "Document.h"
#import "GlossaryDatabase.h"

NS_ASSUME_NONNULL_BEGIN

@interface XclocDocument : Document

+ (BOOL)isXclocExtension:(NSString *)extension;
- (GlossaryPlatform)glossaryPlatformWithSourcePath:(NSString *)pathInSourceContents;

@end

NS_ASSUME_NONNULL_END
