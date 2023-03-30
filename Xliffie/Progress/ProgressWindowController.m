//
//  ProgressWindowController.m
//  Xliffie
//
//  Created by b123400 on 2023/03/22.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "ProgressWindowController.h"
#import "TranslationPair.h"

@interface ProgressWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@property (assign) NSUInteger totalWordCount;
@property (assign) NSUInteger warningWordCount;
@property (assign) NSUInteger translatedWordCount;
@property (assign) NSUInteger emptyWordCount;

@property (assign) NSUInteger totalItemCount;
@property (assign) NSUInteger warningItemCount;
@property (assign) NSUInteger translatedItemCount;
@property (assign) NSUInteger emptyItemCount;

@property (assign) NSUInteger totalCharacterCount;
@property (assign) NSUInteger warningCharacterCount;
@property (assign) NSUInteger translatedCharacterCount;
@property (assign) NSUInteger emptyCharacterCount;

@end

@implementation ProgressWindowController

- (instancetype)initWithDocument:(Document *)doc {
    if (self = [super initWithWindowNibName:@"ProgressWindowController"]) {
        self.document = doc;
        [self calculate];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}
- (IBAction)closeButtonClicked:(id)sender {
    [self.window.sheetParent endSheet:self.window
                           returnCode:NSModalResponseCancel];
}

- (void)calculate {
    self.totalWordCount = 0;
    self.warningWordCount = 0;
    self.translatedWordCount = 0;
    self.emptyWordCount = 0;
    self.totalItemCount = 0;
    self.warningItemCount = 0;
    self.translatedItemCount = 0;
    self.emptyItemCount = 0;
    self.totalCharacterCount = 0;
    self.warningCharacterCount = 0;
    self.translatedCharacterCount = 0;
    self.emptyCharacterCount = 0;

    NSArray<TranslationPair*> *allTranslations = [self.document allTranslationPairs];
    for (TranslationPair *p in allTranslations) {
        __block NSUInteger wordCount = 0;
        [p.source enumerateSubstringsInRange:NSMakeRange(0, p.source.length)
                                 options:NSStringEnumerationByWords
                              usingBlock:^(NSString *character, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            wordCount++;
        }];
        self.totalItemCount++;
        self.totalWordCount += wordCount;
        self.totalCharacterCount += p.source.length;
        switch (p.state) {
            case TranslationPairStateMarkedAsTranslated:
            case TranslationPairStateTranslated:
                self.translatedItemCount++;
                self.translatedWordCount += wordCount;
                self.translatedCharacterCount += p.source.length;
                break;
            case TranslationPairStateTranslatedWithWarnings:
                self.warningItemCount++;
                self.warningWordCount += wordCount;
                self.warningCharacterCount += p.source.length;
                break;
            case TranslationPairStateMarkedAsNotTranslated:
            case TranslationPairStateSame:
            case TranslationPairStateEmpty:
                self.emptyItemCount++;
                self.emptyWordCount += wordCount;
                self.emptyCharacterCount += p.source.length;
                break;
        }
    }
}

# pragma mark: Table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 4;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tableColumn.identifier isEqualTo:@"first"]) {
        switch (row) {
            case 0:
                return NSLocalizedString(@"Total", @"Progress report");
            case 1:
                return NSLocalizedString(@"Translated with warnings", @"Progress report");
            case 2:
                return NSLocalizedString(@"Translated", @"Progress report");
            case 3:
                return NSLocalizedString(@"Not Translated", @"Progress report");
        }
    } else if ([tableColumn.identifier isEqualTo:@"itemCount"]) {
        switch (row) {
            case 0:
                return @(self.totalItemCount);
            case 1:
                return @(self.warningItemCount);
            case 2:
                return @(self.translatedItemCount);
            case 3:
                return @(self.emptyItemCount);
        }
    } else if ([tableColumn.identifier isEqualTo:@"wordCount"]) {
        switch (row) {
            case 0:
                return @(self.totalWordCount);
            case 1:
                return @(self.warningWordCount);
            case 2:
                return @(self.translatedWordCount);
            case 3:
                return @(self.emptyWordCount);
        }
    } else if ([tableColumn.identifier isEqualTo:@"characterCount"]) {
        switch (row) {
            case 0:
                return @(self.totalCharacterCount);
            case 1:
                return @(self.warningCharacterCount);
            case 2:
                return @(self.translatedCharacterCount);
            case 3:
                return @(self.emptyCharacterCount);
        }
    }
    return nil;
}

@end
