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

@protocol DocumentViewControllerDelegate <NSObject>

@optional

- (void)viewController:(id)controller didSelectedFileChild:(File*)file;
- (void)viewController:(id)controller didSelectedTranslation:(TranslationPair*)pair;
- (File*)viewController:(id)controller
 alternativeFileForFile:(File*)anotherFile
           withLanguage:(NSString*)language;
- (void)viewController:(id)controller didEditedTranslation:(TranslationPair*)pair;
- (void)viewControllerTranslationProgressUpdated:(id)controller;

@end

@interface DocumentViewController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate, XMLOutlineViewDelegate>

@property (nonatomic, strong) Document *document;
@property (nonatomic, strong) NSString *searchFilter;
@property (nonatomic, weak) id <DocumentViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *mapLanguage;

@property (weak) IBOutlet XMLOutlineView *outlineView;

- (Document*)documentForDisplay;
- (BOOL)isTranslationSelected:(TranslationPair*)translation;
- (void)expendAllItems;

@end

