//
//  ViewController.h
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMLOutlineView.h"
#import "TranslationPair.h"
#import "Document.h"
#import "File.h"

@protocol ViewControllerDelegate <NSObject>

- (void)viewController:(id)controller didSelectedFileChild:(File*)file;
- (void)viewController:(id)controller didSelectedTranslation:(TranslationPair*)pair;
- (File*)viewController:(id)controller
     alternativeFileForFile:(File*)anotherFile
               withLanguage:(NSString*)language;

@end

@interface ViewController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate, XMLOutlineViewDelegate>

@property (nonatomic, strong) Document *document;
@property (nonatomic, strong) NSString *searchFilter;
@property (nonatomic, weak) id <ViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *mapLanguage;

- (Document*)documentForDisplay;

@end

