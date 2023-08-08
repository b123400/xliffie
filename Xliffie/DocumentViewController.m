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
}

#pragma mark Notification

- (void)documentDidUndoOrRedo:(NSNotification*)notification {
    NSUndoManager *manager = [notification object];
    if (manager == self.documentForDisplay.undoManager) {
        [self.outlineView reloadData];
    }
}

#pragma mark OutlineView

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item {
    return [item isKindOfClass:[File class]];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView
  numberOfChildrenOfItem:(id)item {
    if (!item) {
        return self.documentForDisplay.files.count;
    } else if ([item isKindOfClass:[File class]]) {
        return [(File*)item translations].count;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(NSInteger)index
           ofItem:(id)item {
    if (!item) {
        return self.documentForDisplay.files[index];
    } else if ([item isKindOfClass:[File class]]) {
        return [[(File*)item translations] objectAtIndex:index];
    }
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item {
    if ([item isKindOfClass:[TranslationPair class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            return [(TranslationPair*)item sourceForDisplay];
        } else if ([[tableColumn identifier] isEqualToString:@"target"]) {
            return [(TranslationPair*)item target];
        }
    } else if ([item isKindOfClass:[File class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            NSString *path = [(File*)item original];
            return [NSAttributedString attributedStringWithFileIcon:path];
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
        } else if ([[tableColumn identifier] isEqualToString:@"target"]) {
            [(TranslationPair*)item setTarget:object];
        } else if ([[tableColumn identifier] isEqualToString:@"note"]) {
            [(TranslationPair*)item setNote:object];
        }
        if ([self.delegate respondsToSelector:@selector(viewController:didEditedTranslation:)]) {
            [self.delegate viewController:self didEditedTranslation:item];
        }
    }
    [self.textFinderClient reload];
}

- (void)outlineView:(NSOutlineView *)outlineView
    willDisplayCell:(TranslationTargetCell*)cell
     forTableColumn:(NSTableColumn *)tableColumn
               item:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"target"]) {
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
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"target"] && [item isKindOfClass:[TranslationPair class]]) {
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
    } else {
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
    NSCell *cell = [tableColumn dataCell];
    NSString *value = [self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
    [cell setObjectValue:value];
    [cell setWraps:YES];
    return cell;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    NSTableColumn *firstColumn = [[self.outlineView tableColumns] firstObject];
    NSTableColumn *secondColumn = [[self.outlineView tableColumns] objectAtIndex:1];
    NSCell *cell = [firstColumn dataCell];
    [cell setWraps:YES];
    
    CGFloat indentationWidth = [outlineView indentationPerLevel];
    CGFloat firstColumnWidth = [firstColumn width];
    if ([item isKindOfClass:[File class]]) {
        firstColumnWidth -= indentationWidth;
    } else {
        // TranslationPair, which means indentation = 2
        firstColumnWidth -= indentationWidth * 2;
    }
    
    if ([item isKindOfClass:[File class]]) {
        [cell setObjectValue:[item original]];
        return [cell cellSizeForBounds:CGRectMake(0, 0, firstColumnWidth, CGFLOAT_MAX)].height;
    }
    
    [cell setObjectValue:[(TranslationPair*)item source]];
    CGFloat sourceHeight = [cell cellSizeForBounds:CGRectMake(0, 0, firstColumnWidth, CGFLOAT_MAX)].height + 5;
    [cell setObjectValue:[item target]];
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
    [self suggestionsForTranslationPair:pair callback:^(NSArray<Suggestion *> *suggestions) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!suggestions.count) return;
            [[SuggestionsWindowController shared] setSuggestions:suggestions];
            [SuggestionsWindowController shared].delegate = self;
            [[SuggestionsWindowController shared] showAtRect:cellRect
                                                      ofView:self.outlineView];
            [[[SuggestionsWindowController shared] window] makeKeyAndOrderFront:self];
        });
    }];
}

- (void)suggestionsForTranslationPair:(TranslationPair *)pair callback:(void(^)(NSArray<Suggestion *> *suggestions))callback {
    NSMutableArray<Suggestion*> *suggestions = [NSMutableArray array];
    // Dedup suggestions by title
    NSMutableSet<NSString*> *addedSuggestions = [NSMutableSet set];
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
            if ([r.target isEqual:pair.source] || [addedSuggestions containsObject:r.target]) continue;
            Suggestion *s = [[Suggestion alloc] init];
            s.title = r.target;
            s.source = SuggestionSourceAppleGlossary;
            s.appleGlossaryHitCount = r.bundlePaths.count;
            [addedSuggestions addObject:r.target];
            [suggestions addObject:s];
        }
        callback(suggestions);
    }];
}

#pragma mark checking

- (void)xmlOutlineView:(id)sender didEndEditingRow:(NSInteger)row proposedString:(NSString*)proposed callback:(void (^)(BOOL))callback {
    [[SuggestionsWindowController shared] hide];
    TranslationPair *pair = [self.outlineView itemAtRow:row];
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
    self.textFinderClient.document = document;
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
    if ([indexSet containsIndex:index]) {
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
