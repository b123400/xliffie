//
//  ViewController.m
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "DocumentViewController.h"
#import "TranslationPair.h"
#import "TranslationTargetCell.h"
#import "SuggestionsWindowController.h"
#import "Glossary.h"
#import "NSAttributedString+FileIcon.h"
#import "DocumentTextFinderClient.h"
#import "GlossaryDatabase.h"
#import "XclocDocument.h"
#import "TranslationPairGroup.h"
#import "CustomGlossaryDatabase.h"

@interface DocumentViewController () <SuggestionsWindowControllerDelegate>

@property (strong, nonatomic) Document *filteredDocument;
@property (strong, nonatomic) Document *mappingDocument;

@property (strong, nonatomic) NSTextFinder *textFinder;
@property (strong, nonatomic) DocumentTextFinderClient *textFinderClient;

@end

@implementation DocumentViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentDidUndoOrRedo:)
                                                 name:NSUndoManagerDidUndoChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentDidUndoOrRedo:)
                                                 name:NSUndoManagerDidRedoChangeNotification
                                               object:nil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.outlineView.autosaveExpandedItems = YES;
    self.outlineView.xmlOutlineDelegate = self;
    
    self.textFinderClient = [[DocumentTextFinderClient alloc] initWithDocument:self.document];
    self.textFinderClient.outlineView = self.outlineView;
    
    self.textFinder = [[NSTextFinder alloc] init];
    self.textFinder.findBarContainer = self.outlineView.enclosingScrollView;
    self.textFinder.incrementalSearchingEnabled = YES;
    self.textFinder.incrementalSearchingShouldDimContentView = YES;
    self.textFinder.client = self.textFinderClient;
    
    [self.outlineView.enclosingScrollView addObserver:self forKeyPath:@"findBarVisible" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.outlineView.enclosingScrollView && [keyPath isEqual:@"findBarVisible"]) {
        NSNumber *newValue = change[NSKeyValueChangeNewKey];
        if ([newValue isKindOfClass:[NSNumber class]]) {
            if (![newValue boolValue]) {
                [self.outlineView.window makeFirstResponder:self.outlineView];
            }
        }
    }
}

- (void)dealloc {
    [self.outlineView.enclosingScrollView removeObserver:self forKeyPath:@"findBarVisible"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.textFinder cancelFindIndicator];
    self.textFinder.client = nil;
}

#pragma mark Notification

- (void)documentDidUndoOrRedo:(NSNotification*)notification {
    NSUndoManager *manager = [notification object];
    __weak typeof(self) _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (manager == _self.documentForDisplay.undoManager) {
            [_self.outlineView reloadData];
        }
    });
}

#pragma mark OutlineView

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item {
    return [item isKindOfClass:[File class]]
        || [item isKindOfClass:[TranslationPairGroup class]];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView
  numberOfChildrenOfItem:(id)item {
    if (!item) {
        return self.documentForDisplay.files.count;
    } else if ([item isKindOfClass:[File class]]) {
        return [(File*)item groupedTranslations].count;
    } else if ([item isKindOfClass:[TranslationPairGroup class]]) {
        return [(TranslationPairGroup*)item children].count;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(NSInteger)index
           ofItem:(id)item {
    if (!item) {
        return self.documentForDisplay.files[index];
    } else if ([item isKindOfClass:[File class]]) {
        return [[(File*)item groupedTranslations] objectAtIndex:index];
    } else if ([item isKindOfClass:[TranslationPairGroup class]]) {
        return [(TranslationPairGroup*)item children][index];
    }
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item {
    if ([item isKindOfClass:[TranslationPair class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            return [(TranslationPair*)item sourceForDisplayWithFormatSpecifierReplaced];
        } else if ([[tableColumn identifier] isEqualToString:@"target"]) {
            return [(TranslationPair*)item targetWithFormatSpecifierReplaced];
        }
    } else if ([item isKindOfClass:[File class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            NSString *path = [(File*)item original];
            return [NSAttributedString attributedStringWithFileIcon:path];
        }
    } else if ([item isKindOfClass:[TranslationPairGroup class]]) {
        TranslationPairGroup *group = (TranslationPairGroup*)item;
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            return [group stringForSourceColumn];
        } else if ([[tableColumn identifier] isEqualToString:@"target"]) {
            return [group.mainPair targetWithFormatSpecifierReplaced];
        }
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView
     setObjectValue:(id)object
     forTableColumn:(NSTableColumn *)tableColumn
             byItem:(id)item {
    if ([item isKindOfClass:[TranslationPair class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            [(TranslationPair*)item setSource:object];
        } else if ([[tableColumn identifier] isEqualToString:@"target"] && [object isKindOfClass:[NSAttributedString class]]) {
            [(TranslationPair*)item setAttributedTarget:object];
        } else if ([[tableColumn identifier] isEqualToString:@"note"]) {
            [(TranslationPair*)item setNote:object];
        }
        if ([self.delegate respondsToSelector:@selector(viewController:didEditedTranslation:)]) {
            [self.delegate viewController:self didEditedTranslation:item];
        }
    }
    [self.textFinderClient reload];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"target"] && [item isKindOfClass:[TranslationPair class]]) {
        return YES;
    }
    if ([[tableColumn identifier] isEqualToString:@"target"] && [item isKindOfClass:[TranslationPairGroup class]] && [(TranslationPairGroup*)item mainPair]) {
        return YES;
    }
    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSUInteger index = [self.outlineView selectedRow];
    id item = [self.outlineView itemAtRow:index];
    if ([item isKindOfClass:[TranslationPair class]]) {
        if ([self.delegate respondsToSelector:@selector(viewController:didSelectedTranslation:)]) {
            [self.delegate viewController:self didSelectedTranslation:item];
        }
        if ([self.delegate respondsToSelector:@selector(viewController:didSelectedFileChild:)]) {
            [self.delegate viewController:self didSelectedFileChild:[item file]];
        }
    } else if ([item isKindOfClass:[File class]]) {
        if ([self.delegate respondsToSelector:@selector(viewController:didSelectedTranslation:)]) {
            [self.delegate viewController:self didSelectedTranslation:nil];
        }
        if ([self.delegate respondsToSelector:@selector(viewController:didSelectedFileChild:)]) {
            [self.delegate viewController:self didSelectedFileChild:item];
        }
    }
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (!item) return nil;
    NSCell *dataCell = [tableColumn dataCell];
    NSString *value = [self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
    [dataCell setObjectValue:value];
    [dataCell setWraps:YES];
    if ([[tableColumn identifier] isEqualToString:@"target"] && [dataCell isKindOfClass:[TranslationTargetCell class]]) {
        TranslationTargetCell *cell = (TranslationTargetCell *)dataCell;
        if ([item isKindOfClass:[TranslationPair class]]) {
            TranslationPair *pair = (TranslationPair*)item;
            switch (pair.state) {
                case TranslationPairStateEmpty:
                case TranslationPairStateMarkedAsNotTranslated:
                case TranslationPairStateSame:
                    cell.dotColor = [NSColor systemOrangeColor];
                    break;
                case TranslationPairStateTranslatedWithWarnings: // TODO: show warning sign instead of mixing with non-translated
                    cell.dotColor = [NSColor systemRedColor];
                    break;
                case TranslationPairStateTranslated:
                case TranslationPairStateMarkedAsTranslated:
                    cell.dotColor = nil;
                    break;
            }
        } else if ([item isKindOfClass:[File class]]) {
            File *file = (File*)item;
            if (![outlineView isItemExpanded:item]) {
                __block BOOL anyEmpty = NO;
                __block BOOL anyWarning = NO;
                [file.translations enumerateObjectsUsingBlock:^(TranslationPair * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    switch (obj.state) {
                        case TranslationPairStateTranslatedWithWarnings:
                            anyWarning = YES;
                            *stop = YES;
                            break;
                        case TranslationPairStateEmpty:
                        case TranslationPairStateSame:
                        case TranslationPairStateMarkedAsNotTranslated:
                            anyEmpty = YES;
                            *stop = YES;
                            break;
                        case TranslationPairStateTranslated:
                        case TranslationPairStateMarkedAsTranslated:
                            // nothing
                            break;
                    }
                }];
                if (anyWarning) {
                    cell.dotColor = [NSColor systemRedColor];
                } else if (anyEmpty) {
                    cell.dotColor = [NSColor orangeColor];
                }
            } else {
                cell.dotColor = nil;
            }
        } else {
            cell.dotColor = nil;
        }
    }
    return dataCell;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    NSTableColumn *firstColumn = [[self.outlineView tableColumns] firstObject];
    NSTableColumn *secondColumn = [[self.outlineView tableColumns] objectAtIndex:1];
    NSCell *cell = [firstColumn dataCell];
    [cell setWraps:YES];
    
    CGFloat firstColumnWidth = [firstColumn width];
    NSInteger row = [self.outlineView rowForItem:item];
    if (row >= 0) {
        CGFloat indentationWidth = [outlineView indentationPerLevel];
        NSInteger level = [self.outlineView levelForRow:row];
        firstColumnWidth -= indentationWidth * level;
    }
    
    if ([item isKindOfClass:[File class]]
        || [item isKindOfClass:[TranslationPairGroup class]]
        ) {
        id obj = [self outlineView:outlineView objectValueForTableColumn:firstColumn byItem:item];
        [cell setObjectValue:obj];
        return [cell cellSizeForBounds:CGRectMake(0, 0, firstColumnWidth, CGFLOAT_MAX)].height;
    }
    
    [cell setObjectValue:[(TranslationPair*)item sourceForDisplayWithFormatSpecifierReplaced]];
    CGFloat sourceHeight = [cell cellSizeForBounds:CGRectMake(0, 0, firstColumnWidth, CGFLOAT_MAX)].height + 5;
    [cell setObjectValue:[item targetWithFormatSpecifierReplaced]];
    CGFloat targetHeight = [cell cellSizeForBounds:CGRectMake(0, 0, [secondColumn width], CGFLOAT_MAX)].height + 5;
    return MAX(sourceHeight, targetHeight);
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification {
    [self.outlineView reloadData];
}

# pragma mark - Suggestions

- (BOOL)control:(NSControl *)control
       textView:(NSTextView *)textView
doCommandBySelector:(SEL)commandSelector {
    if (control == self.outlineView) {
        if (commandSelector == @selector(cancelOperation:)) {
            [control abortEditing];
            [self.view.window makeFirstResponder:control];
            if ([[[SuggestionsWindowController shared] window] isVisible]) {
                [[SuggestionsWindowController shared] hide];
            }
            return YES;
        }
        if (commandSelector == @selector(moveUp:)) {
            [[SuggestionsWindowController shared] moveUp:textView];
            return YES;
        }
        if (commandSelector == @selector(moveDown:)) {
            [[SuggestionsWindowController shared] moveDown:textView];
            return YES;
        }
        if (commandSelector == @selector(insertNewline:)) {
            Suggestion *s = [[SuggestionsWindowController shared] selectedSuggestion];
            if (s) {
                [textView setString:s.title];
                [[SuggestionsWindowController shared] hide];
                return NO; // Let it finish editing
            }
            return NO;
        }
    }
    return NO;
}

- (void)suggestionWindowController:(id)controller didSelectSuggestion:(Suggestion *)suggestion {
    [self.outlineView.currentEditor setString:suggestion.title];
    [self.outlineView.window makeFirstResponder:self.outlineView]; // end editing
    [[SuggestionsWindowController shared] hide];
}

- (void)xmlOutlineView:(id)sender
 didStartEditingColumn:(NSInteger)column
                   row:(NSInteger)row
                 event:(NSEvent *)event {
    NSRect cellRect = [self.outlineView frameOfCellAtColumn:column row:row];
    TranslationPair *pair = (TranslationPair*)[self.outlineView itemAtRow:row];
    if (![pair isKindOfClass:[TranslationPair class]]) return;
    SuggestionsWindowController *suggestionController = [SuggestionsWindowController shared];
    NSText *currentEditor = [self.outlineView currentEditor];
    NSProgressIndicator *loadingView = nil;
    for (NSView *view in [currentEditor subviews]) {
        if ([view isKindOfClass:[NSProgressIndicator class]]) {
            loadingView = (NSProgressIndicator*)view;
            break;
        }
    }
    if (!loadingView) {
        loadingView = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 20, 20)];
        loadingView.style = NSProgressIndicatorStyleSpinning;
        [loadingView setDisplayedWhenStopped:NO];
        [currentEditor addSubview:loadingView];
    }
    typeof(self) __weak _self = self;
    CGFloat loadingSize = 18;
    loadingView.frame = NSMakeRect(currentEditor.frame.size.width - loadingSize, 2, loadingSize, loadingSize);
    NSArray<Suggestion *> *suggestions = [self suggestionsForTranslationPair:pair callback:^(NSArray<Suggestion *> *allSuggestions) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [loadingView stopAnimation:_self];
            if (![_self.view.window isKeyWindow] || [_self.view.window sheets].count || [_self.outlineView editedRow] != row) {
                return;
            }
            if (suggestionController.searchingObject != pair) {
                // It's loading for something newer, ignore this result
                return;
            }
            if (!allSuggestions.count) {
                [[SuggestionsWindowController shared] hide];
                return;
            }
            [suggestionController setSuggestions:allSuggestions];
            suggestionController.delegate = _self;
            [suggestionController showAtRect:cellRect
                                      ofView:_self.outlineView];
            [[suggestionController window] makeKeyAndOrderFront:_self];
        });
    }];
    [loadingView startAnimation:self];
    suggestionController.searchingObject = pair;
    if (suggestions.count) {
        [suggestionController setSuggestions:suggestions];
        suggestionController.delegate = self;
        [suggestionController showAtRect:cellRect
                                  ofView:self.outlineView];
        [[suggestionController window] makeKeyAndOrderFront:self];
    }
}

- (NSArray<Suggestion *> *)suggestionsForTranslationPair:(TranslationPair *)pair callback:(void(^)(NSArray<Suggestion *> *allSuggestions))callback {
    NSMutableArray<Suggestion*> *suggestions = [NSMutableArray array];
    // Dedup suggestions by title
    NSMutableSet<NSString*> *addedSuggestions = [NSMutableSet set];
    
    NSArray<CustomGlossaryRow *> *customRows = [[CustomGlossaryDatabase shared] rowsWithSourceLocale:pair.file.sourceLanguage
                                                                             targetLocale:pair.file.targetLanguage
                                                                                   source:pair.source];
    for (CustomGlossaryRow *customRow in customRows) {
        Suggestion *s = [[Suggestion alloc] init];
        s.title = customRow.target;
        s.source = SuggestionSourceCustomGlossary;
        [suggestions addObject:s];
        [addedSuggestions addObject:customRow.target];
    }
    
    Glossary *glossary = [Glossary sharedGlossaryWithLocale:pair.file.targetLanguage];
    NSArray<NSString *> *glossaryTranslations = [glossary translate:pair.source];
    for (NSString *glossaryTranslation in glossaryTranslations) {
        if (glossaryTranslation && ![glossaryTranslation isEqualTo:pair.target] && ![addedSuggestions containsObject:glossaryTranslation]) {
            Suggestion *s = [[Suggestion alloc] init];
            s.title = glossaryTranslation;
            s.source = SuggestionSourceGlossary;
            [suggestions addObject:s];
            [addedSuggestions addObject:glossaryTranslation];
        }
    }
    for (File *file in self.document.files) {
        for (TranslationPair *p in file.translations) {
            if (p == pair) continue;
            if (!p.target.length) continue;
            if ([addedSuggestions containsObject:p.target]) continue;
            if ([p.source isEqualTo:pair.source] && ![p.target isEqualTo:pair.target]) {
                // An item with same source but different target, suggest the translated target to this item
                Suggestion *s = [[Suggestion alloc] init];
                s.title = p.target;
                s.source = SuggestionSourceFile;
                s.sourceFile = file;
                [suggestions addObject:s];
                [addedSuggestions addObject:p.target];
            }
        }
    }
    
    GlossaryPlatform platform = [self.document isKindOfClass:[XclocDocument class]]
        ? [(XclocDocument*)self.document glossaryPlatformWithSourcePath:pair.file.original]
        : GlossaryPlatformAny;
    [GlossaryDatabase searchGlossariesForTerms:@[pair.source]
                                  withPlatform:platform
                                    fromLocale:pair.file.sourceLanguage
                                      toLocale:pair.file.targetLanguage
                                      callback:^(GlossarySearchResults * _Nonnull results) {
        NSArray *thisResults = [results targetsWithSource:pair.source];
        for (GlossarySearchResult *r in thisResults) {
            if ([r.target isEqual:pair.source] || [r.target isEqual:pair.target] || [addedSuggestions containsObject:r.target]) continue;
            Suggestion *s = [[Suggestion alloc] init];
            s.title = r.target;
            s.source = SuggestionSourceAppleGlossary;
            s.appleGlossaryHitCount = r.bundlePaths.count;
            [addedSuggestions addObject:r.target];
            [suggestions addObject:s];
        }
        callback(suggestions);
    }];
    return suggestions;
}

#pragma mark checking

- (void)xmlOutlineView:(id)sender didEndEditingRow:(NSInteger)row proposedString:(NSString*)proposed callback:(void (^)(BOOL))callback {
    [[SuggestionsWindowController shared] hide];
    TranslationPair *pair = [self.outlineView itemAtRow:row];
    if ([pair isKindOfClass:[TranslationPairGroup class]]) {
        pair = [(TranslationPairGroup*)pair mainPair];
    }
    NSArray *warnings = [pair formatWarningsForProposedTranslation:proposed];
    if ([warnings count]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Apply it anyway",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
        [alert setMessageText:NSLocalizedString(@"Maybe you've made a mistake?",nil)];
        [alert setInformativeText:[warnings componentsJoinedByString:@"\n"]];
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                callback(YES);
            } else {
                callback(NO);
            }
        }];
    } else {
        callback(YES);
    }
}

#pragma mark Document

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (void)setDocument:(Document *)document {
    _document = document;
    [self applyMapLanguage:self.mapLanguage];
    [self expendAllItems];
    self.textFinderClient.document = [self documentForDisplay];
}

- (void)expendAllItems {
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (Document*)documentForDisplay {
    if (self.filteredDocument) {
        return self.filteredDocument;
    }
    return self.document;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([[menuItem identifier] isEqualToString:@"markAsTranslated"]) {
        NSInteger index = [self.outlineView clickedRow];
        NSIndexSet *indexSet = [self.outlineView selectedRowIndexes];
        NSIndexSet *targetIndexSet;
        if ([indexSet containsIndex:index]) {
            targetIndexSet = indexSet;
        } else {
            targetIndexSet = [NSIndexSet indexSetWithIndex:index];
        }
        
        BOOL __block anyNotTranslated = NO;
        BOOL __block hasNonTranslation = NO;
        [targetIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            id obj = [[self outlineView] itemAtRow:idx];
            if (![obj isKindOfClass:[TranslationPair class]]) {
                hasNonTranslation = YES;
                return;
            }
            TranslationPair *pair = (TranslationPair*)obj;
            if (!pair.isTranslated) {
                anyNotTranslated = YES;
                *stop = YES;
            }
        }];
        if (anyNotTranslated) {
            [menuItem setTitle:NSLocalizedString(@"Mark as translated", @"Menu item")];
        } else {
            [menuItem setTitle:NSLocalizedString(@"Mark as not translated", @"Menu item")];
        }
        if (hasNonTranslation && targetIndexSet.count == 1) {
            return NO;
        }
        return YES;
    }
    return YES;
}

- (IBAction)markAsTranslated:(id)sender {
    NSInteger index = [self.outlineView clickedRow];
    NSIndexSet *indexSet = [self.outlineView selectedRowIndexes];
    NSIndexSet *targetIndexSet;
    if (index < 0) {
        targetIndexSet = indexSet;
    } else if ([indexSet containsIndex:index]) {
        targetIndexSet = indexSet;
    } else {
        targetIndexSet = [NSIndexSet indexSetWithIndex:index];
    }
    
    BOOL __block anyNotTranslated = NO;
    [targetIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        id obj = [[self outlineView] itemAtRow:idx];
        if (![obj isKindOfClass:[TranslationPair class]]) return;
        TranslationPair *pair = (TranslationPair*)obj;
        if (!pair.isTranslated) {
            anyNotTranslated = YES;
            *stop = YES;
        }
    }];
    
    [targetIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        id obj = [[self outlineView] itemAtRow:idx];
        if (![obj isKindOfClass:[TranslationPair class]]) return;
        TranslationPair *pair = (TranslationPair*)obj;
        if (anyNotTranslated) {
            [pair markAsTranslated];
        } else {
            [pair markAsNotTranslated];
        }
    }];
    if ([self.delegate respondsToSelector:@selector(viewControllerTranslationProgressUpdated:)]) {
        [self.delegate viewControllerTranslationProgressUpdated:self];
    }
    [self.outlineView reloadDataForRowIndexes:targetIndexSet columnIndexes:[NSIndexSet indexSetWithIndex:1]];
}

- (IBAction)copySourceToTarget:(id)sender {
    NSIndexSet *indexSet = [self.outlineView selectedRowIndexes];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        id item = [self.outlineView itemAtRow:idx];
        if ([item isKindOfClass:[TranslationPair class]]) {
            TranslationPair *pair = (TranslationPair*)item;
            pair.target = [pair sourceForDisplay];
        }
    }];
    [self.outlineView reloadData];
}

#pragma mark Search

- (void)performTextFinderAction:(id)sender {
    if ([sender isKindOfClass:[NSMenuItem class]] ) {
        NSMenuItem *menuItem = (NSMenuItem*)sender;
        if ([self.textFinder validateAction:menuItem.tag]) {
            if (menuItem.tag == NSTextFinderActionShowFindInterface) {
                // This is a special tag
                [self.textFinder performAction:NSTextFinderActionSetSearchString];
            }
            [self.textFinder performAction:menuItem.tag];
        }
    }
}

- (void)setFilterState:(TranslationPairState)filterState {
    _filterState = filterState;
    [self reloadFilteredDocument];
}

- (void)setSearchFilter:(NSString *)searchFilter {
    _searchFilter = searchFilter;
    [self reloadFilteredDocument];
}

- (void)reloadFilteredDocument {
    if (!_searchFilter.length && !self.filterState) {
        self.filteredDocument = nil;
    } else {
        self.filteredDocument = [self.document filteredDocumentWithSearchFilter:self.searchFilter state:self.filterState];
    }
    self.textFinderClient.document = [self documentForDisplay];
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (BOOL)isTranslationSelected:(TranslationPair*)translation {
    NSIndexSet *selectedIndexs = [self.outlineView selectedRowIndexes];
    __block BOOL isSelected = NO;
    [selectedIndexs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        TranslationPair *thisTranslation = [self.outlineView itemAtRow:idx];
        if ([thisTranslation isEqualTo:translation]) {
            isSelected = YES;
            *stop = YES;
        }
    }];
    return isSelected;
}

#pragma mark mapping language

- (void)setMapLanguage:(NSString *)mapLanguage {
    if ([_mapLanguage isEqualToString:mapLanguage]) {
        return;
    }
    _mapLanguage = mapLanguage;
    [self applyMapLanguage:mapLanguage];
}

- (void)applyMapLanguage:(NSString*)mapLanguage {
    if (![self.delegate respondsToSelector:@selector(viewController:alternativeFileForFile:withLanguage:)]) {
        return;
    }
    for (File *file in self.document.files) {
        File *alternativeFile = [self.delegate viewController:self
                                       alternativeFileForFile:file
                                                 withLanguage:mapLanguage];
        [file setSourceMapFile:alternativeFile];
    }
    [self.outlineView reloadData];
}

@end
