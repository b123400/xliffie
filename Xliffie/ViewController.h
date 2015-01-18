//
//  ViewController.h
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TranslationPair.h"
#import "Document.h"
#import "File.h"

@protocol ViewControllerDelegate <NSObject>

- (void)viewController:(id)controller didSelectedFileChild:(File*)file;
- (void)viewController:(id)controller didSelectedTranslation:(TranslationPair*)pair;

@end

@interface ViewController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, strong) Document *document;
@property (nonatomic, weak) id <ViewControllerDelegate> delegate;

@end

