//
//  GlossaryWindowController.m
//  Xliffie
//
//  Created by b123400 on 2021/09/28.
//  Copyright © 2021 b123400. All rights reserved.
//

#import "GlossaryWindowController.h"
#import "Glossary.h"
#import "TranslationPair.h"
#import "GlossaryFileRow.h"

@interface GlossaryWindowController () <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (weak) IBOutlet NSButton *skipButton;
@property (weak) IBOutlet NSTextField *descriptionLabel;
@property (weak) IBOutlet NSOutlineView *outlineView;

@property (nonatomic, strong) Glossary *glossary;
@property (nonatomic, strong) NSArray<GlossaryFileRow*> *fileRows;

@end

@implementation GlossaryWindowController

- (instancetype)initWithDocument:(Document *)document {
    if (self = [super initWithWindowNibName:@"GlossaryWindowController"]) {
        self.xliffDocument = document;
        self.glossary = [[Glossary alloc] initWithTargetLocale:self.xliffDocument.files.firstObject.targetLanguage];
        [self reloadFileRows];
    }
    return self;
}

- (void)reloadFileRows {
    NSMutableArray<GlossaryFileRow*> *fileRows = [NSMutableArray array];
    for (File *file in self.xliffDocument.files) {
        NSMutableArray *rows = [NSMutableArray array];
        for (TranslationPair *pair in file.translations) {
            NSArray<NSString *>*translatedStrings = [self.glossary translate:pair.source];
            if (!translatedStrings.count) {
                // Not available in glossary
                continue;
            }
            for (NSString *translated in translatedStrings) {
                if ([pair.target isEqualTo:translated]) {
                    // Already same as glossary
                    continue;
                }
                GlossaryRow *row = [[GlossaryRow alloc] init];
                row.glossary = translated;
                row.translationPair = pair;
                row.shouldApply = YES;
                [rows addObject:row];
            }
        }
        if (rows.count) {
            GlossaryFileRow *fileRow = [[GlossaryFileRow alloc] init];
            fileRow.file = file;
            fileRow.rows = rows;
            [fileRows addObject:fileRow];
        }
    }
    self.fileRows = fileRows;
}

- (void)reloadUI {
    self.descriptionLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%ld translations are available from the glossary.", @""), self.numberOfApplicableTranslation];
    self.skipButton.hidden = !self.showSkipButton;
}

- (void)setShowSkipButton:(BOOL)showSkipButton {
    _showSkipButton = showSkipButton;
    [self reloadUI];
}

- (NSInteger)numberOfApplicableTranslation {
    return [[self.fileRows valueForKeyPath:@"@unionOfArrays.rows"] count];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.outlineView expandItem:nil expandChildren:YES];
    
    [self reloadUI];
}

#pragma mark - Outline view

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item {
    if (!item) {
        return self.fileRows.count;
    } else if ([item isKindOfClass:[GlossaryFileRow class]]) {
        GlossaryFileRow *fileRow = (GlossaryFileRow*)item;
        return fileRow.rows.count;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item {
    if (!item) {
        return self.fileRows[index];
    } else if ([item isKindOfClass:[GlossaryFileRow class]]) {
        GlossaryFileRow *fileRow = (GlossaryFileRow*)item;
        return fileRow.rows[index];
    }
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[GlossaryFileRow class]]) {
        return YES;
    }
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item {
    if ([item isKindOfClass:[GlossaryFileRow class]]) {
        GlossaryFileRow *fileRow = (GlossaryFileRow*)item;
        if ([tableColumn.identifier isEqualTo:@"apply"]) {
            BOOL applyCount = [[fileRow.rows filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"shouldApply == YES"]] count];
            if (applyCount == fileRow.rows.count) {
                return @(YES);
            } else {
                return @(NO);
            }
        } else if ([tableColumn.identifier isEqualTo:@"source"]) {
            return fileRow.file.original;
        }
        return nil;
    } else if ([item isKindOfClass:[GlossaryRow class]]) {
        GlossaryRow *row = (GlossaryRow*)item;
        if ([tableColumn.identifier isEqualTo:@"apply"]) {
            return @(row.shouldApply);
        } else if ([tableColumn.identifier isEqualTo:@"source"]) {
            return row.translationPair.source;
        } else if ([tableColumn.identifier isEqualTo:@"target"]) {
            return row.translationPair.target;
        } else if ([tableColumn.identifier isEqualTo:@"glossary"]) {
            return row.glossary;
        }
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([tableColumn.identifier isEqualTo:@"apply"]) {
        return YES;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([tableColumn.identifier isEqual:@"apply"] && [object isKindOfClass:[NSNumber class]]) {
        if ([item isKindOfClass:[GlossaryFileRow class]]) {
            GlossaryFileRow *fileRow = (GlossaryFileRow*)item;
            for (GlossaryRow *row in fileRow.rows){
                row.shouldApply = [object boolValue];
            }
        } else if ([item isKindOfClass:[GlossaryRow class]]) {
            GlossaryRow *row = (GlossaryRow*)item;
            row.shouldApply = [object boolValue];
        }
        [outlineView reloadData];
    }
}

#pragma mark - Interactions

- (IBAction)selectAllClicked:(id)sender {
    for (GlossaryFileRow *fileRow in self.fileRows) {
        for (GlossaryRow *row in fileRow.rows) {
            row.shouldApply = YES;
        }
    }
    [self.outlineView reloadData];
}
- (IBAction)selectNoneClicked:(id)sender {
    for (GlossaryFileRow *fileRow in self.fileRows) {
        for (GlossaryRow *row in fileRow.rows) {
            row.shouldApply = NO;
        }
    }
    [self.outlineView reloadData];
}
- (IBAction)selectNonTranslatedClicked:(id)sender {
    for (GlossaryFileRow *fileRow in self.fileRows) {
        for (GlossaryRow *row in fileRow.rows) {
            row.shouldApply = !row.translationPair.isTranslated;
        }
    }
    [self.outlineView reloadData];
}
- (IBAction)okClicked:(id)sender {
    NSInteger translatedCount = 0;
    for (GlossaryFileRow *fileRow in self.fileRows) {
        for (GlossaryRow *row in fileRow.rows) {
            if (row.shouldApply) {
                row.translationPair.target = row.glossary;
                translatedCount++;
            }
        }
    }
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}
- (IBAction)cancelClicked:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}
- (IBAction)skipClicked:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseContinue];
}

@end
