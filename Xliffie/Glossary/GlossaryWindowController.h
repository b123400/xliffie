//
//  GlossaryWindowController.h
//  Xliffie
//
//  Created by b123400 on 2021/09/28.
//  Copyright © 2021 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"

NS_ASSUME_NONNULL_BEGIN

@interface GlossaryWindowController : NSWindowController

@property (nonatomic, strong) Document *xliffDocument;

- (instancetype)initWithDocument:(Document *)document;

- (NSInteger)numberOfApplicableTranslation;

@end

NS_ASSUME_NONNULL_END
