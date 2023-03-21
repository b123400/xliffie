//
//  TranslationWindowController.m
//  Xliffie
//
//  Created by b123400 on 13/1/2016.
//  Copyright © 2016 b123400. All rights reserved.
//

#import "TranslationWindowController.h"
#import "TranslationUtility.h"
#import "DocumentViewController.h"

@interface TranslationWindowController () <NSOutlineViewDataSource, NSOutlineViewDelegate, DocumentViewControllerDelegate>

@property (nonatomic, strong) NSArray <TranslationPair*> *pairs;
@property (nonatomic, assign) BRLocaleMapService service;
@property (nonatomic, strong) Document *translatedDocument;

@property (nonatomic, strong) NSProgressIndicator *loadingIndicator;
@property (weak) IBOutlet NSView *documentView;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *okButton;
@property (nonatomic, strong) DocumentViewController *documentViewController;

@end

@implementation TranslationWindowController

- (instancetype)initWithTranslationPairs:(NSArray <TranslationPair*> *)pairs
                      translationService:(BRLocaleMapService)service {
    self = [super initWithWindowNibName:@"TranslationWindowController"];
    self.pairs = pairs;
    self.service = service;
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    NSRect frame = self.window.frame;
    frame.size.height = 150;
    frame.size.width = 200;
    [self.window setFrame:frame display:YES animate:NO];
    [self.window.contentView setNeedsLayout:YES];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSSize loadingSize = NSMakeSize(50, 50);
    NSPoint cooridinate = NSMakePoint((self.window.frame.size.width - loadingSize.width)/2,
                                      (self.window.frame.size.height - loadingSize.height)/2);
    self.loadingIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(cooridinate.x,
                                                                                  cooridinate.y,
                                                                                  loadingSize.width,
                                                                                  loadingSize.height)];

    self.loadingIndicator.style = NSProgressIndicatorSpinningStyle;
    [self.window.contentView addSubview:self.loadingIndicator];
    [self.loadingIndicator startAnimation:self];
    
    self.okButton.hidden = YES;
    self.cancelButton.hidden = YES;
    [self startTranslate];
}

- (void)showTranslationTable {
    self.documentViewController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"DocumentViewController"];
    self.documentViewController.delegate = self;
    self.documentViewController.document = self.translatedDocument;
    self.documentViewController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.documentViewController.view.frame = NSMakeRect(0, 0, self.documentView.frame.size.width, self.documentView.frame.size.height);
    [self.documentView addSubview:self.documentViewController.view];
    [self.documentViewController expendAllItems];
    
    self.loadingIndicator.hidden = YES;
    self.okButton.hidden = NO;
    self.cancelButton.hidden = NO;

    NSRect frame = self.window.frame;
    frame.size.height = 600;
    frame.size.width = 800;
    [self.window setFrame:frame display:YES animate:YES];
    [self.window.contentView setNeedsLayout:YES];
}

#pragma mark - interaction

- (IBAction)cancelButtonPressed:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)okButtonPressed:(id)sender {
    NSArray *pairsWithWarning = [self translationWithWarnings];
    if (!pairsWithWarning.count) {
        [self applyTranslation];
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Go ahead", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
        [alert setMessageText:NSLocalizedString(@"Are you sure?", @"Translate alert message")];
        [alert setInformativeText:
         [NSString stringWithFormat:
          NSLocalizedString(@"There are %lu records with formatting warnings, better fix them before applying.",
                            @"Translate alert message"),
          (unsigned long)pairsWithWarning.count]];
        [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@""]; // make "go ahead" not a default
        [[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"\r"]; // make cancel the default
        NSModalResponse response = [alert runModal];
        if (response == NSAlertFirstButtonReturn) {
            [self applyTranslation];
            [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
        }
    }
}

#pragma mark - translate

- (void)startTranslate {
    NSMutableArray *texts = [NSMutableArray arrayWithCapacity:self.pairs.count];
    for (TranslationPair *pair in self.pairs) {
        [texts addObject:pair.source];
    }
    
    NSString *sourceLanguage = [self.pairs firstObject].file.sourceLanguage;
    NSString *targetLanguage = [self.pairs firstObject].file.targetLanguage;
    
    __weak typeof(self) weakSelf = self;
    
    [TranslationUtility translateTexts:texts
                          fromLanguage:sourceLanguage
                            toLanguage:targetLanguage
                           withService:self.service
                             autoSplit:YES
                              callback:^(NSError *error, NSArray<NSString *> *translatedTexts) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      if (error) {
                                          NSAlert *alert = [NSAlert alertWithError:error];
                                          alert.alertStyle = NSCriticalAlertStyle;
                                          [alert runModal];
                                          [weakSelf.window.sheetParent endSheet:weakSelf.window
                                                                     returnCode:NSModalResponseAbort];
                                          return;
                                      }
                                      [weakSelf finishedTranslate:translatedTexts];
                                  });
                              }];
}

- (void)finishedTranslate:(NSArray <NSString *> *)translatedTexts {
    self.translatedDocument = [self documentWithTranslatedTexts:translatedTexts];
    [self showTranslationTable];
}

#pragma mark - virtual document

- (Document*)documentWithTranslatedTexts:(NSArray <NSString*> *)translatedTexts {
    
    NSMapTable *fileTables = [NSMapTable strongToStrongObjectsMapTable];
    
    // Create a map for [old file] -> [new file]
    for (TranslationPair *pair in self.pairs) {
        if (![fileTables objectForKey:pair.file]) {
            File *newFile = [[File alloc] init];
            newFile.original = pair.file.original;
            newFile.translations = [NSMutableArray array];
            [fileTables setObject:newFile forKey:pair.file];
        }
    }
    
    // Create new translation pair that looks like the original with new translation
    NSMutableOrderedSet *files = [[NSMutableOrderedSet alloc] initWithCapacity:fileTables.count];
    for (NSInteger i = 0; i < self.pairs.count; i++) {
        TranslationPair *thisPair = self.pairs[i];
        File *thisFile = [fileTables objectForKey:thisPair.file];
        NSString *translated = translatedTexts[i];

        TranslationPair *newPair = [[TranslationPair alloc] init];
        newPair.file = thisFile;
        newPair.source = thisPair.source;
        newPair.target = translated;
        [thisFile.translations addObject:newPair];
        [files addObject:thisFile];
    }
    
    Document *newDocument = [[Document alloc] init];
    newDocument.files = [[files array] mutableCopy];
    return newDocument;
}

- (void)applyTranslation {
    NSMutableArray <TranslationPair*> *translatedPairs = [NSMutableArray arrayWithCapacity:self.pairs.count];
    for (File *file in self.translatedDocument.files) {
        [translatedPairs addObjectsFromArray:file.translations];
    }
    
    for (NSInteger i = 0; i < self.pairs.count; i++) {
        TranslationPair *pair = self.pairs[i];
        pair.target = translatedPairs[i].target;
    }
}

#pragma mark - checking

- (NSArray*)translationWithWarnings {
    NSMutableArray <TranslationPair*> *translatedPairs = [NSMutableArray array];
    for (File *file in self.translatedDocument.files) {
        for (TranslationPair *pair in file.translations) {
            if ([[pair warningsForTarget] count]) {
                [translatedPairs addObject:pair];
            }
        }
    }
    return translatedPairs;
}

@end
