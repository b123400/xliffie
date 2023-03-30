//
//  DocumentTextFinderClient.h
//  Xliffie
//
//  Created by b123400 on 2023/03/24.
//  Copyright © 2023 b123400. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Document.h"
#import "XMLOutlineView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DocumentTextFinderClient : NSObject<NSTextFinderClient>

@property (nonatomic, strong) Document *document;
@property (weak, nonatomic) XMLOutlineView *outlineView;

- (instancetype)initWithDocument:(Document*)document;
- (void)reload;

@end

NS_ASSUME_NONNULL_END
