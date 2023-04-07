//
//  DocumentWindowController.m
//  Xliffie
//
//  Created by b123400 on 18/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "DocumentWindowController.h"
#import "DetailViewController.h"
#import "TargetMissingViewController.h"
#import "TranslateServiceWindowController.h"
#import "XclocDocument.h"
#import "NSString+Pangu.h"
#import "GlossaryWindowController.h"
#import "BRProgressButton.h"
#import "ProgressWindowController.h"
#import "NSImage+SystemImage.h"

#define DOCUMENT_WINDOW_MIN_SIZE NSMakeSize(600, 600)
#define DOCUMENT_WINDOW_LAST_FRAME_KEY @"DOCUMENT_WINDOW_LAST_FRAME_KEY"

@interface DocumentWindowController () <TargetMissingViewController, TranslateServiceWindowControllerDelegate>

@property (nonatomic, strong) NSSplitViewController *splitViewController;
@property (nonatomic, strong) DocumentViewController *mainViewController;
@property (nonatomic, strong) DetailViewController *detailViewController;
@property (nonatomic, assign) BOOL isWindowFrameInitialized;

@property (nonatomic, strong) TargetMissingViewController *targetMissingViewController;

@property (weak) IBOutlet NSSegmentedControl *languagesSegment;
@property (weak) IBOutlet NSToolbarItem *translateButton;
@property (weak) IBOutlet BRProgressButton *progressButton;
@property (weak) IBOutlet NSSearchField *searchField;

@property (nonatomic, strong) TranslateServiceWindowController *translateServiceController;
@property (nonatomic, strong) TranslationWindowController *translateController;
@property (nonatomic, strong) GlossaryWindowController *glossaryWindowController;
@property (nonatomic, strong) ProgressWindowController *progressWindowController;

// { @"en" :
//     { @"hello/world.xib" : <File>
//       @"foo.string" : <File>
//     }
// }
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableDictionary<NSString*, File*>*> *filesOfLanguages;

@end

@implementation DocumentWindowController

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(anotherWindowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.splitViewController = (NSSplitViewController*)self.contentViewController;
    
    NSArray<NSSplitViewItem *> *splitViewItems = [self.splitViewController splitViewItems];
    
    NSSplitViewItem *mainItem = splitViewItems[0];
    self.mainViewController = (DocumentViewController*)[mainItem viewController];
    self.mainViewController.delegate = self;
    self.mainViewController.document = self.document;
    
    NSSplitViewItem *detailItem = splitViewItems[1];
    detailItem.collapsed = YES;
    detailItem.maximumThickness = 200;
    detailItem.preferredThicknessFraction = 0.2;
    self.detailViewController = (DetailViewController*)[detailItem viewController];

    [(DocumentWindow*)self.window setDelegate:self];

    self.filesOfLanguages = [NSMutableDictionary dictionary];

    self.window.minSize = DOCUMENT_WINDOW_MIN_SIZE;

    if (!self.isWindowFrameInitialized) {
        self.isWindowFrameInitialized = YES;
        NSRect lastWindowFrame = self.lastWindowFrame;
        NSSize screenSize = [NSScreen mainScreen].frame.size;
        
        // Make sure the window is fully inside the frame
        lastWindowFrame = NSIntersectionRect(lastWindowFrame, (NSRect) {
            .origin = NSZeroPoint,
            .size = screenSize
        });
        
        // If it is empty, put it at the center of the screen
        if (NSIsEmptyRect(lastWindowFrame)
            || lastWindowFrame.size.width < DOCUMENT_WINDOW_MIN_SIZE.width
            || lastWindowFrame.size.height < DOCUMENT_WINDOW_MIN_SIZE.height
            ) {
            lastWindowFrame = (NSRect) {
                .origin.x = (screenSize.width - DOCUMENT_WINDOW_MIN_SIZE.width)/2,
                .origin.y = (screenSize.height - DOCUMENT_WINDOW_MIN_SIZE.height)/2,
                .size = DOCUMENT_WINDOW_MIN_SIZE
            };
        }
        [self.window setFrame:lastWindowFrame display:YES];
    }
    [self reloadTranslationButtons];
    [self reloadSearchFieldMenuTemplate];
    self.searchField.maximumRecents = 5;
}

- (void)reloadSearchFieldMenuTemplate {
    NSMenu *cellMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Search Menu",@"Search menu title")];

    NSMenuItem *item;
    item = [[NSMenuItem alloc] init];
    [item setTitle:NSLocalizedString(@"Filter", @"Search menu title")];
    [cellMenu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Not Translated", @"Search menu title") action:@selector(setTranslationPairFilterState:) keyEquivalent:@""];
    [item setTarget:self];
    if (self.filterState & TranslationPairStateMarkedAsNotTranslated || self.filterState & TranslationPairStateEmpty) {
        [item setState:NSControlStateValueOn];
    }
    NSImage *itemImage = [NSImage systemImageWithFallbackNamed:@"circle.dashed"];
    [item setImage:itemImage];
    [item setTag:TranslationPairStateEmpty]; // also marked as not translated
    [cellMenu addItem:item];

    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Same as source", @"Search menu title") action:@selector(setTranslationPairFilterState:) keyEquivalent:@""];
    [item setTarget:self];
    itemImage = [NSImage systemImageWithFallbackNamed:@"equal.circle"];
    [item setImage:itemImage];
    if (self.filterState & TranslationPairStateSame) {
        [item setState:NSControlStateValueOn];
    }
    [item setTag:TranslationPairStateSame];
    [cellMenu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Translated", @"Search menu title") action:@selector(setTranslationPairFilterState:) keyEquivalent:@""];
    [item setTarget:self];
    itemImage = [NSImage systemImageWithFallbackNamed:@"checkmark.circle"];
    [item setImage:itemImage];
    if (self.filterState & TranslationPairStateTranslated || self.filterState & TranslationPairStateMarkedAsTranslated) {
        [item setState:NSControlStateValueOn];
    }
    [item setTag:TranslationPairStateTranslated]; // also marked as translated
    [cellMenu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Translated with warnings", @"Search menu title") action:@selector(setTranslationPairFilterState:) keyEquivalent:@""];
    [item setTarget:self];
    itemImage = [NSImage systemImageWithFallbackNamed:@"checkmark.circle.trianglebadge.exclamationmark"];
    [item setImage:itemImage];
    if (self.filterState & TranslationPairStateTranslatedWithWarnings) {
        [item setState:NSControlStateValueOn];
    }
    [item setTag:TranslationPairStateTranslatedWithWarnings];
    [cellMenu addItem:item];
    
    [cellMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *recentTitle = [[NSMenuItem alloc] init];
    [recentTitle setTitle:NSLocalizedString(@"Recent Searches", @"menu item title")];
    [recentTitle setTag:NSSearchFieldRecentsTitleMenuItemTag];
    [cellMenu addItem:recentTitle];
    
    NSMenuItem *recents = [[NSMenuItem alloc] init];
    [recents setTag:NSSearchFieldRecentsMenuItemTag];
    [cellMenu addItem:recents];

    [cellMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *clearRecent = [[NSMenuItem alloc] init];
    [clearRecent setTag:NSSearchFieldClearRecentsMenuItemTag];
    [clearRecent setTitle:@"Clear Recent Searches"];
    [cellMenu addItem:clearRecent];

    id searchCell = [self.searchField cell];
    [searchCell setSearchMenuTemplate:cellMenu];
}

- (IBAction)setTranslationPairFilterState:(NSMenuItem *)sender {
    TranslationPairState itemTag = [sender tag];
    if (self.filterState & itemTag) {
        self.filterState ^= itemTag;
        if (itemTag == TranslationPairStateEmpty) {
            self.filterState ^= TranslationPairStateMarkedAsNotTranslated;
        }
        if (itemTag == TranslationPairStateTranslated) {
            self.filterState ^= TranslationPairStateMarkedAsTranslated;
        }
    } else {
        self.filterState |= itemTag;
        if (itemTag == TranslationPairStateEmpty) {
            self.filterState |= TranslationPairStateMarkedAsNotTranslated;
        }
        if (itemTag == TranslationPairStateTranslated) {
            self.filterState |= TranslationPairStateMarkedAsTranslated;
        }
    }
}

- (void)setDocument:(id)document {
    [super setDocument:document];
    BOOL isMissingTargetLanguage = NO;
    for (File *file in [(Document*)document files]) {
        if (!file.targetLanguage) {
            isMissingTargetLanguage = YES;
            break;
        }
    }
    
    NSRect frame = self.window.frame;
    if (isMissingTargetLanguage) {
        self.targetMissingViewController.document = document;
        self.contentViewController = self.targetMissingViewController;
    } else {
        self.mainViewController.document = document;
        self.contentViewController = self.splitViewController;
    }
    // because setting content vc will resize the window
    [self.window setFrame:frame display:YES animate:NO];

    if (self.mainViewController.mapLanguage) {
        [self selectLanguage:self.mainViewController.mapLanguage
            withSegmentIndex:0];
    } else {
        [self selectLanguage:((Document*)document).files[0].sourceLanguage
            withSegmentIndex:0];
    }
    [self selectLanguage:((Document*)document).files[0].targetLanguage
        withSegmentIndex:1];

    Document *doc = self.document;
    
    NSString *sourceLanguage = doc.files.firstObject.sourceLanguage;
    NSString *targetLanguage = doc.files.firstObject.targetLanguage;
    if ([sourceLanguage isEqualTo:targetLanguage]) {
        self.translateButton.enabled = NO;
    } else {
        self.translateButton.enabled = YES;
    }
    [self reloadProgress];
    [self reloadTranslationButtons];
}

- (TranslationPairState)filterState {
    return self.mainViewController.filterState;
}

- (void)setFilterState:(TranslationPairState)state {
    self.mainViewController.filterState = state;
    [self reloadSearchFieldMenuTemplate];
    [self.searchField becomeFirstResponder]; // Need this to make the search field to redraw correctly
}

- (NSString*)path {
    Document *document = self.document;
    return [[document fileURL] path];
}

- (NSString*)baseFolderPath {
    return [[self path] stringByDeletingLastPathComponent];
}

-(void)windowDidBecomeKey:(NSNotification *)notification {
    [self reloadLanguageMap];
    [self reloadTranslationButtons];
}

- (void)windowWillClose:(NSNotification *)notification {
    self.window = nil;
    [self.document setWindowController:nil];
    [self.document close];
}

#pragma mark - Window Resizing

- (void)windowDidResize:(NSNotification *)notification {
    if (!self.window.visible) return;
    [self setLastWindowFrame:self.window.frame];
}

- (void)windowDidMove:(NSNotification *)notification {
    if (!self.window.visible) return;
    [self setLastWindowFrame:self.window.frame];
}

- (CGRect)lastWindowFrame {
    NSString *rectString = [[NSUserDefaults standardUserDefaults] stringForKey:DOCUMENT_WINDOW_LAST_FRAME_KEY];
    if (!rectString) {
        return CGRectZero;
    }
    return NSRectFromString(rectString);
}

- (void)setLastWindowFrame:(CGRect)rect {
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(rect)
                                              forKey:DOCUMENT_WINDOW_LAST_FRAME_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark undo

- (void)documentDidUndoOrRedo:(NSNotification*)notification {
    [self setDocument:self.document]; // reload to missing target controller if needed.
}

#pragma mark restore

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:[(Document*)self.document fileURL] forKey:@"url"];
    [coder encodeObject:[self selectedLanguageWithSegmentIndex:0] forKey:@"sourceLanguage"];
    [coder encodeObject:NSStringFromRect(self.window.frame) forKey:@"window-frame"];
}

+ (void)restoreWindowWithIdentifier:(NSString *)identifier
                              state:(NSCoder *)state
                  completionHandler:(void (^)(NSWindow *,
                                              NSError *))completionHandler {

    DocumentWindowController *controller = (DocumentWindowController*)[[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"Document Window Controller"];
    DocumentWindow *window = (DocumentWindow*)controller.window;
    
    NSURL *url = [state decodeObjectForKey:@"url"];
    NSString *extension = [[url lastPathComponent] pathExtension];
    Document *document = nil;
    if ([Document isXliffExtension:extension]) {
        document = [[Document alloc] initWithContentsOfURL:url
                                                    ofType:@"xliff"
                                                     error:nil];
    } else if ([XclocDocument isXclocExtension:extension]) {
        document = [[XclocDocument alloc] initWithContentsOfURL:url
                                                         ofType:@"xcloc"
                                                          error:nil];
    }
    
    if (document) {
        [controller setDocument:document];
        document.windowController = controller;
        [document addWindowController:controller];
    } else {
        // There is no document for the controller, not restoring
        completionHandler(nil, nil);
        return;
    }
    
    NSString *sourceLangauge = [state decodeObjectForKey:@"sourceLanguage"];
    if (sourceLangauge) {
        [controller selectLanguage:sourceLangauge
                  withSegmentIndex:0];
        [controller selectedSourceLanguage:[controller selectedLanguageMenuItemWithSegmentIndex:0]];
    }
    
    NSString *windowFrameString = [state decodeObjectForKey:@"window-frame"];
    if (windowFrameString) {
        [window setFrame:NSRectFromString(windowFrameString) display:YES];
        controller.isWindowFrameInitialized = YES;
    }
    completionHandler(window, nil);
}

#pragma mark interaction

- (void)toggleNotes {
    if (self.contentViewController != self.splitViewController) return;
    NSSplitViewItem *splitViewItem = [[self.splitViewController splitViewItems] objectAtIndex:1];
    splitViewItem.animator.collapsed = !splitViewItem.collapsed;
}

- (void)showTranslateWindow {
    self.translateServiceController = [[TranslateServiceWindowController alloc] initWithDocument:self.document];
    self.translateServiceController.delegate = self;
    __weak typeof(self) weakSelf = self;
    [self.window beginSheet:self.translateServiceController.window
          completionHandler:^(NSModalResponse returnCode) {
              if (returnCode == NSModalResponseOK) {
                  TranslationWindowController *controller = weakSelf.translateServiceController.translationWindowController;
                  [weakSelf presentTranslationWindowController:controller];
              }
              weakSelf.translateServiceController = nil;
          }];
}

- (IBAction)addSpaceButtonPressed:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",@"")];
    [[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
    [[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"\033"];
    [alert setMessageText:NSLocalizedString(@"Add spaces to all translations?",@"confirm")];
    [alert setInformativeText:NSLocalizedString(@"You can undo by pressing command+z",@"confirm")];
    [alert setAlertStyle:NSAlertStyleInformational];
    
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {
                      if (returnCode == NSAlertFirstButtonReturn) {
                          Document *document = (Document*)self.document;
                          [[document undoManager] beginUndoGrouping];
                          for (File *file in document.files) {
                              for (TranslationPair *pair in file.translations) {
                                  if (pair.target) {
                                      pair.target = [NSString spacing:pair.target];
                                  }
                              }
                          }
                          [[document undoManager] endUndoGrouping];
                          // reload
                          self.document = self.document;
                      }
                  }];
}

- (void)viewController:(id)controller didEditedTranslation:(TranslationPair *)pair {
    [self reloadProgress];
}

- (void)viewControllerTranslationProgressUpdated:(id)controller {
    [self reloadProgress];
}

- (void)reloadProgress {
    Document *document = self.mainViewController.document;
    NSArray<TranslationPair*> *allTranslations = [document allTranslationPairs];
    
    int completedCount = 0;
    int warningCount = 0;
    for (TranslationPair *pair in allTranslations) {
        switch (pair.state) {
            case TranslationPairStateTranslatedWithWarnings:
                warningCount++;
                break;
            case TranslationPairStateTranslated:
            case TranslationPairStateMarkedAsTranslated:
                completedCount++;
                break;
            default:
                break;
        }
    }
    [self.progressButton resetSegments];
    if (@available(macOS 10.14, *)) {
        [self.progressButton addSegmentWithProgress:completedCount/(allTranslations.count/1.0) colour:[NSColor alternateSelectedControlColor]];
    } else {
        [self.progressButton addSegmentWithProgress:completedCount/(allTranslations.count/1.0) colour:[NSColor colorForControlTint:NSDefaultControlTint]];
    }
    [self.progressButton addSegmentWithProgress:warningCount/(allTranslations.count/1.0) colour:[NSColor systemRedColor]];
}

#pragma mark short cuts

- (void)documentWindowShowInfoPressed:(id)documentWindow {
    [self toggleNotes];
}

- (void)documentWindowSearchKeyPressed:(id)documentWindow {
    [self.searchField selectText:self];
}

- (IBAction)toggleNotesPressed:(id)sender {
    [self toggleNotes];
}

- (IBAction)translateButtonPressed:(id)sender {
    [self translateWithGlossaryAndWebPressed: sender];
}

- (IBAction)translateWithGlossaryMenuPressed:(id)sender {
    GlossaryWindowController *controller = [[GlossaryWindowController alloc] initWithDocument:self.document];
    controller.showSkipButton = NO;
    self.glossaryWindowController = controller;
    if (![controller numberOfApplicableTranslation]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"No translation available", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [alert runModal];
    } else {
        __weak typeof(self) weakSelf = self;
        [self.window beginSheet:controller.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSModalResponseOK) {
                [self.mainViewController.outlineView reloadData];
            }
            weakSelf.glossaryWindowController = nil;
        }];
    }
}

- (IBAction)showProgressReport:(id)sender {
    ProgressWindowController *controller = [[ProgressWindowController alloc] initWithDocument:self.document];
    self.progressWindowController = controller;
    __weak typeof(self) weakSelf = self;
    [self.window beginSheet:controller.window
          completionHandler:^(NSModalResponse returnCode) {
        weakSelf.progressWindowController = nil;
    }];
}

- (IBAction)translateWithGlossaryAndWebPressed:(id)sender {
    GlossaryWindowController *controller = [[GlossaryWindowController alloc] initWithDocument:self.document];
    controller.showSkipButton = YES;
    self.glossaryWindowController = controller;
    if (![controller numberOfApplicableTranslation]) {
        [self showTranslateWindow];
    } else {
        __weak typeof(self) weakSelf = self;
        [self.window beginSheet:controller.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSModalResponseOK) {
                [self.mainViewController.outlineView reloadData];
            }
            if (returnCode == NSModalResponseOK || returnCode == NSModalResponseContinue) {
                [self showTranslateWindow];
            }
            weakSelf.glossaryWindowController = nil;
        }];
    }
}

#pragma mark selection

- (void)viewController:(id)controller didSelectedTranslation:(TranslationPair*)pair {
    [self.detailViewController setRepresentedObject:pair];
}
- (IBAction)searchFilterChanged:(id)sender {
    if ([sender isKindOfClass:[NSTextField class]]) {
        NSString *searchString = [sender stringValue];
        [self.mainViewController setSearchFilter:searchString];
        if (searchString.length && ![self.searchField.recentSearches containsObject:searchString]) {
            self.searchField.recentSearches = [self.searchField.recentSearches arrayByAddingObject:searchString];
        }
    } else {
        // TODO, show another search view?
    }
}

- (void)viewController:(id)controller didSelectedFileChild:(File*)file {
    if (file.sourceLanguage && file.targetLanguage) {
        if (self.mainViewController.mapLanguage) {
            [self selectLanguage:self.mainViewController.mapLanguage
                withSegmentIndex:0];
        } else {
            [self selectLanguage:file.sourceLanguage
                withSegmentIndex:0];
        }
        
        [self selectLanguage:file.targetLanguage
            withSegmentIndex:1];
    } else {
        
    }
}

#pragma mark top langauge menu

- (void)reloadLanguageMap {
    self.filesOfLanguages = [NSMutableDictionary dictionary];
    for (NSWindow *window in self.window.tabbedWindows) {
        if (![window isKindOfClass:[DocumentWindow class]]) continue;
        DocumentWindow *docWindow = (DocumentWindow*)window;
        Document *document = docWindow.windowController.document;
        for (File *file in document.files) {
            if (!file.targetLanguage) continue;
            NSMutableDictionary *existingFiles = self.filesOfLanguages[file.targetLanguage];
            if (!existingFiles) {
                self.filesOfLanguages[file.targetLanguage] = existingFiles = [NSMutableDictionary dictionary];
            }
            [existingFiles setObject:file forKey:file.original];
        }
    }
}

- (void)reloadTranslationButtons {
    NSString *selectedSourceLanguage = [self selectedLanguageWithSegmentIndex:0];
    NSString *selectedTargetLanguage = [self selectedLanguageWithSegmentIndex:1];
    
    [self.languagesSegment setMenu:[[NSMenu alloc] init] forSegment:0];
    [self.languagesSegment setMenu:[[NSMenu alloc] init] forSegment:1];
    
    NSMutableOrderedSet *sourceCodes = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet *targetCodes = [NSMutableOrderedSet orderedSet];
    NSArray<NSWindow*> *windows = self.window.tabbedWindows ?: @[self.window];
    for (NSWindow *window in windows) {
        if (![window isKindOfClass:[DocumentWindow class]]) continue;
        DocumentWindow *docWindow = (DocumentWindow*)window;
        for (File *file in [docWindow.windowController.document files]) {
            [sourceCodes addObject:file.sourceLanguage];
            if (file.targetLanguage) {
                [targetCodes addObject:file.targetLanguage];
            }
        }
    }
    
    [sourceCodes unionOrderedSet:targetCodes];
    
    NSLocale *locale = [NSLocale currentLocale];
    
    for (NSString *languageCode in sourceCodes) {
        NSString *languageName = [locale displayNameForKey:NSLocaleIdentifier
                                                     value:languageCode];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:languageName
                                                          action:@selector(selectedSourceLanguage:)
                                                   keyEquivalent:@""];
        menuItem.target = self;
        menuItem.representedObject = languageCode;
        [[self.languagesSegment menuForSegment:0] addItem:menuItem];
    }
    
    for (NSString *languageCode in targetCodes) {
        NSString *languageName = [locale displayNameForKey:NSLocaleIdentifier
                                                     value:languageCode];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:languageName
                                                          action:@selector(selectedTargetLanguage:)
                                                   keyEquivalent:@""];
        menuItem.target = self;
        menuItem.representedObject = languageCode;
        [[self.languagesSegment menuForSegment:1] addItem:menuItem];
    }
    
    [self selectLanguage:selectedSourceLanguage withSegmentIndex:0];
    [self selectLanguage:selectedTargetLanguage withSegmentIndex:1];
}

- (void)selectLanguage:(NSString*)language withSegmentIndex:(NSInteger)index {
    NSArray <NSMenuItem*> *items = [[self.languagesSegment menuForSegment:index] itemArray];
    for (NSMenuItem *item in items) {
        if ([language isEqualToString:item.representedObject]) {
            [item setState:NSOnState];
            [self.languagesSegment setLabel:item.title
                                 forSegment:index];
        } else {
            [item setState:NSOffState];
        }
    }
}

- (NSMenuItem*)selectedLanguageMenuItemWithSegmentIndex:(NSInteger)index {
    NSArray <NSMenuItem*> *items = [[self.languagesSegment menuForSegment:index] itemArray];
    for (NSMenuItem *item in items) {
        if (item.state == NSOnState) {
            return item;
        }
    }
    return items.count ? items[0] : nil;
}

- (NSString*)selectedLanguageWithSegmentIndex:(NSInteger)index {
    return [self selectedLanguageMenuItemWithSegmentIndex:index].representedObject;
}

- (void)selectedTargetLanguage:(NSMenuItem*)sender {
    NSString *selectedTitle = sender.representedObject;
    for (NSWindow *window in self.window.tabbedWindows) {
        if (![window isKindOfClass:[DocumentWindow class]]) continue;
        DocumentWindow *docWindow = (DocumentWindow*)window;
        Document *document = docWindow.windowController.document;
        for (File *file in document.files) {
            if ([file.targetLanguage isEqualToString:selectedTitle]) {
                [docWindow makeKeyWindow];
                return;
            }
        }
    }
}

- (void)selectedSourceLanguage:(NSMenuItem*)sender {
    self.mainViewController.mapLanguage = sender.representedObject;
    self.document = self.document; // reload content vc
}

- (File *)viewController:(id)controller
      alternativeFileForFile:(File *)anotherFile
                withLanguage:(NSString *)language {
    NSDictionary *thisLanguageFiles = self.filesOfLanguages[language];
    if (!thisLanguageFiles) return nil;
    return thisLanguageFiles[anotherFile.original];
}

#pragma mark Target language missing

- (TargetMissingViewController*)targetMissingViewController {
    if (!_targetMissingViewController) {
        _targetMissingViewController = [self.storyboard instantiateControllerWithIdentifier:@"targetMissing"];
        _targetMissingViewController.delegate = self;
    }
    return _targetMissingViewController;
}

- (void)targetMissingViewController:(id)sender didSetTargetLanguage:(NSString *)targetLanguage {
    // reload current document
    self.document = self.document;
    [self reloadLanguageMap];
    [self reloadTranslationButtons];

    [self selectLanguage:targetLanguage withSegmentIndex:1];
}

- (void)anotherWindowWillClose:(NSNotification*)notification {
    [self reloadTranslationButtons];
}

#pragma mark Translation Service

- (BOOL)translateServiceWindowController:(id)sender isTranslationPairSelected:(TranslationPair *)pair {
    return [self.mainViewController isTranslationSelected:pair];
}

- (void)presentTranslationWindowController:(TranslationWindowController*)controller {
    self.translateController = controller;
    __weak typeof(self) weakSelf = self;
    [self.window beginSheet:controller.window
          completionHandler:^(NSModalResponse returnCode) {
              if (returnCode == NSModalResponseOK) {
                  weakSelf.document = weakSelf.document; // reload vc
              }
              weakSelf.translateController = nil;
          }];
}

@end
