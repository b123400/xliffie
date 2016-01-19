//
//  DocumentWindowController.m
//  Xliffie
//
//  Created by b123400 on 18/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "DocumentWindowController.h"
#import "DetailViewController.h"
#import "DocumentWindowSplitView.h"
#import "DocumentListDrawer.h"
#import "TargetMissingViewController.h"
#import "TranslateServiceWindowController.h"

@interface DocumentWindowController () <DocumentListDrawerDelegate, TargetMissingViewController, TranslateServiceWindowControllerDelegate>

@property (nonatomic, strong) NSViewController *splitViewController;
@property (nonatomic, strong) DocumentViewController *mainViewController;
@property (nonatomic, strong) DetailViewController *detailViewController;

@property (nonatomic, strong) TargetMissingViewController *targetMissingViewController;

@property (weak) IBOutlet NSPopUpButton *translationSourceButton;
@property (weak) IBOutlet NSPopUpButton *translationTargetButton;

@property (weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, strong) NSMutableArray *documents;
@property (nonatomic, strong) DocumentListDrawer *documentsDrawer;
@property (nonatomic, strong) TranslateServiceWindowController *translateServiceController;
@property (nonatomic, strong) TranslationWindowController *translateController;

// { @"en" :
//     { @"hello/world.xib" : <File>
//       @"foo.string" : <File>
//     }
// }
@property (nonatomic, strong) NSMutableDictionary *filesOfLanguages;

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
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.mainViewController = [self.storyboard instantiateControllerWithIdentifier:@"DocumentViewController"];
    self.mainViewController.delegate = self;
    self.mainViewController.document = self.document;
    
    self.splitViewController = self.contentViewController;
    DocumentWindowSplitView *splitView = (DocumentWindowSplitView*)self.contentViewController.view.subviews[0];
    splitView.delegate = self;
    [splitView addSubview:self.mainViewController.view];
    
    self.detailViewController = [self.storyboard instantiateControllerWithIdentifier:@"DetailViewController"];
    [splitView addSubview:self.detailViewController.view];
    
    
    [(DocumentWindow*)self.window setDelegate:self];
    
    [splitView collapseRightView];
    
    self.documents = [NSMutableArray array];
    self.filesOfLanguages = [NSMutableDictionary dictionary];
    
    self.documentsDrawer = [[DocumentListDrawer alloc] initWithContentSize:NSMakeSize(100, self.window.frame.size.height) preferredEdge:NSMinXEdge];
    self.documentsDrawer.delegate = self;
    [self.documentsDrawer setParentWindow:self.window];
    self.documentsDrawer.minContentSize = NSMakeSize(100, 200);
    
    [self.documentsDrawer close];
    
    self.window.minSize = NSMakeSize(480, 600);
    NSRect frame = self.window.frame;
    frame.size.width = MAX(480, frame.size.width);
    frame.size.height = MAX(600, frame.size.height);
    [self.window setFrame:frame display:YES];
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
    
    [self addDocument:document];
    [self.documentsDrawer selectDocumentAtIndex:[self.documents indexOfObject:document]];
    
    [self selectMenuItemWithRepresentedObject:((Document*)document).files[0].targetLanguage
                                inPopUpButton:self.translationTargetButton];
}

- (NSString*)baseFolderPath {
    Document *document = self.document ?: self.documents[0];
    return [[[document fileURL] path] stringByDeletingLastPathComponent];
}

- (void)addDocument:(Document*)newDocument {
    for (Document *document in self.documents) {
        if ([[document fileURL]isEqualTo:[newDocument fileURL]]) return;
    }

    if (newDocument) {
        [self.documents addObject:newDocument];
    }
    
    [self reloadLanguageMap];
    [self reloadTranslationButtons];
    [self.documentsDrawer reloadData];
    [self.window invalidateRestorableState];
}

-(void)windowDidBecomeKey:(NSNotification *)notification {
    
}

- (void)windowWillClose:(NSNotification *)notification {
//    self.window = nil;
//    [self.documentsDrawer close];
//    self.documentsDrawer.delegate = nil;
//    self.documentsDrawer = nil;
}

#pragma mark undo

- (void)documentDidUndoOrRedo:(NSNotification*)notification {
    [self setDocument:self.document]; // reload to missing target controller if needed.
}

#pragma mark restore

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    NSMutableArray *urls = [NSMutableArray array];
    for (Document *document in self.documents) {
        [urls addObject:document.fileURL];
    }
    [coder encodeObject:urls forKey:@"documents"];
    [coder encodeObject:[[self.translationSourceButton selectedItem] representedObject] forKey:@"sourceLanguage"];
}

+ (void)restoreWindowWithIdentifier:(NSString *)identifier
                              state:(NSCoder *)state
                  completionHandler:(void (^)(NSWindow *,
                                              NSError *))completionHandler {
    [NSDocumentController restoreWindowWithIdentifier:identifier state:state completionHandler:^(NSWindow *window, NSError *error) {
        if ([window isKindOfClass:[DocumentWindow class]]) {
            NSArray *urls = [state decodeObjectForKey:@"documents"];
            DocumentWindowController *controller = (DocumentWindowController*)[window windowController];
            for (NSURL *url in urls) {
                Document *document = [[Document alloc] initWithContentsOfURL:url
                                                                      ofType:@"xliff"
                                                                       error:nil];
                if (document) {
                    [controller addDocument:document];
                }
            }
            if (!controller.document) {
                controller.document = controller.documents[0];
            }
            NSString *sourceLangauge = [state decodeObjectForKey:@"sourceLanguage"];
            if (sourceLangauge) {
                [controller selectMenuItemWithRepresentedObject:sourceLangauge
                                                  inPopUpButton:controller.translationSourceButton];
                [controller selectedSourceLanguage:controller.translationSourceButton.selectedItem];
            }
        }
        completionHandler(window, error);
    }];
}

#pragma mark interaction

- (void)toggleNotes {
    if (self.contentViewController != self.splitViewController) return;
    DocumentWindowSplitView *splitView = self.contentViewController.view.subviews[0];
    BOOL rightViewCollapsed = [splitView isSubviewCollapsed:[[splitView subviews] objectAtIndex: 1]];
    if (rightViewCollapsed) {
        [splitView uncollapseRightView];
    } else {
        [splitView collapseRightView];
    }
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
              weakSelf.translateController = nil;
          }];
}

#pragma mark drawer

- (NSArray *)documentsForDrawer:(id)drawer {
    return self.documents;
}

- (void)documentDrawer:(id)sender didSelectedDocumentAtIndex:(NSUInteger)index {
    if (index == -1) return;
    Document *document = self.documents[index];
    self.document = document;
}

- (IBAction)toggleDrawer:(id)sender {
    [self.documentsDrawer toggle:self];
}

- (void)openDocumentDrawer {
    [self.documentsDrawer open];
}

#pragma mark splitview

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    NSView* rightView = [[splitView subviews] objectAtIndex:1];
    return ([subview isEqual:rightView]);
}

- (BOOL)splitView:(NSSplitView *)splitView
shouldCollapseSubview:(NSView *)subview
forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
    return YES;
}

- (CGFloat)splitView:(NSSplitView *)splitView
constrainMinCoordinate:(CGFloat)proposedMin
         ofSubviewAt:(NSInteger)dividerIndex {
    return splitView.frame.size.width/2.0;
}

- (CGFloat)splitView:(NSSplitView *)splitView
constrainMaxCoordinate:(CGFloat)proposedMax
         ofSubviewAt:(NSInteger)dividerIndex {
    return splitView.frame.size.width-200;
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
    [self showTranslateWindow];
}


#pragma mark selection

- (void)viewController:(id)controller didSelectedTranslation:(TranslationPair*)pair {
    [self.detailViewController setRepresentedObject:pair.note];
}
- (IBAction)searchFilterChanged:(id)sender {
    [self.mainViewController setSearchFilter:[sender stringValue]];
}

- (void)viewController:(id)controller didSelectedFileChild:(File*)file {
    if (file.sourceLanguage && file.targetLanguage) {
        if (self.mainViewController.mapLanguage) {
            [self selectMenuItemWithRepresentedObject:self.mainViewController.mapLanguage
                                        inPopUpButton:self.translationSourceButton];
        } else {
            [self selectMenuItemWithRepresentedObject:file.sourceLanguage
                                        inPopUpButton:self.translationSourceButton];
        }
        
        [self selectMenuItemWithRepresentedObject:file.targetLanguage
                                    inPopUpButton:self.translationTargetButton];
    } else {
        
    }
}

#pragma mark top langauge menu

- (void)reloadLanguageMap {
    self.filesOfLanguages = [NSMutableDictionary dictionary];
    
    for (Document *document in self.documents) {
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
    [[self.translationSourceButton menu] removeAllItems];
    [[self.translationTargetButton menu] removeAllItems];
    
    NSMutableOrderedSet *sourceCodes = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet *targetCodes = [NSMutableOrderedSet orderedSet];
    for (Document *document in self.documents) {
        for (File *file in document.files) {
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
        [[self.translationSourceButton menu] addItem:menuItem];
    }
    
    for (NSString *languageCode in targetCodes) {
        NSString *languageName = [locale displayNameForKey:NSLocaleIdentifier
                                                     value:languageCode];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:languageName
                                                          action:@selector(selectedTargetLanguage:)
                                                   keyEquivalent:@""];
        menuItem.target = self;
        menuItem.representedObject = languageCode;
        [[self.translationTargetButton menu] addItem:menuItem];
    }
}

- (void)selectedTargetLanguage:(NSMenuItem*)sender {
    NSString *selectedTitle = sender.representedObject;
    for (Document *document in self.documents) {
        for (File *file in document.files) {
            if ([file.targetLanguage isEqualToString:selectedTitle]) {
                self.document = document;
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
    [self selectMenuItemWithRepresentedObject:targetLanguage
                                inPopUpButton:self.translationTargetButton];
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

#pragma mark utility

- (void)selectMenuItemWithRepresentedObject:(id)obj inPopUpButton:(NSPopUpButton*)button {
    NSMenuItem *selectedMenuItem = nil;
    for (NSMenuItem *item in [[button menu] itemArray]) {
        if ([obj isEqualTo:[item representedObject]]) {
            selectedMenuItem = item;
            break;
        }
    }
    [button selectItem:selectedMenuItem];
}

@end
