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

@interface DocumentWindowController () <DocumentListDrawerDelegate>

@property (nonatomic, strong) ViewController *mainViewController;
@property (nonatomic, strong) DetailViewController *detailViewController;

@property (weak) IBOutlet NSPopUpButton *translationSourceButton;
@property (weak) IBOutlet NSPopUpButton *translationTargetButton;

@property (weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, strong) NSMutableArray *documents;
@property (nonatomic, strong) DocumentListDrawer *documentsDrawer;

// { @"en" :
//     { @"hello/world.xib" : <File>
//       @"foo.string" : <File>
//     }
// }
@property (nonatomic, strong) NSMutableDictionary *filesOfLanguages;

@end

@implementation DocumentWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.mainViewController = [self.storyboard instantiateControllerWithIdentifier:@"ViewController"];
    self.mainViewController.delegate = self;
    self.mainViewController.document = self.document;
    
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
    self.mainViewController.document = document;
    
    [self addDocument:document];
    [self.documentsDrawer selectDocumentAtIndex:[self.documents indexOfObject:document]];
    [self.translationTargetButton selectItemWithTitle:[((Document*)document).files[0] targetLanguage]];
}

- (NSURL*)baseFolderURL {
    return [[(NSDocument*)self.document fileURL] URLByDeletingLastPathComponent];
}

- (void)addDocument:(Document*)newDocument {
    for (Document *document in self.documents) {
        if ([[document fileURL]isEqualTo:[newDocument fileURL]]) return;
    }
    for (File *file in newDocument.files) {
        NSMutableDictionary *existingFiles = self.filesOfLanguages[file.targetLanguage];
        if (!existingFiles) {
            self.filesOfLanguages[file.targetLanguage] = existingFiles = [NSMutableDictionary dictionary];
        }
        [existingFiles setObject:file forKey:file.original];
    }
    if (newDocument) {
        [self.documents addObject:newDocument];
    }
    [self reloadTranslationButtons];
    [self.documentsDrawer reloadData];
    [self.window invalidateRestorableState];
}

-(void)windowDidBecomeKey:(NSNotification *)notification {
    
}

#pragma mark restore

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    NSMutableArray *urls = [NSMutableArray array];
    for (Document *document in self.documents) {
        [urls addObject:document.fileURL];
    }
    [coder encodeObject:urls forKey:@"documents"];
    [coder encodeObject:[self.translationSourceButton titleOfSelectedItem] forKey:@"sourceLanguage"];
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
                [controller.translationSourceButton selectItemWithTitle:sourceLangauge];
                [controller translationSourceButtonPressed:controller.translationSourceButton];
            }
        }
        completionHandler(window, error);
    }];
}

#pragma mark interaction

- (void)toggleNotes {
    DocumentWindowSplitView *splitView = self.contentViewController.view.subviews[0];
    BOOL rightViewCollapsed = [splitView isSubviewCollapsed:[[splitView subviews] objectAtIndex: 1]];
    if (rightViewCollapsed) {
        [splitView uncollapseRightView];
    } else {
        [splitView collapseRightView];
    }
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

#pragma mark selection

- (void)viewController:(id)controller didSelectedTranslation:(TranslationPair*)pair {
    [self.detailViewController setRepresentedObject:pair.note];
}
- (IBAction)searchFilterChanged:(id)sender {
    [self.mainViewController setSearchFilter:[sender stringValue]];
}

- (void)viewController:(id)controller didSelectedFileChild:(File*)file {
    if (file.sourceLanguage && file.targetLanguage) {
        [self.translationSourceButton selectItemWithTitle:NSLocalizedString(file.sourceLanguage, @"")];
        [self.translationTargetButton selectItemWithTitle:NSLocalizedString(file.targetLanguage, @"")];
    } else {
        
    }
}

#pragma mark top langauge menu

- (void)reloadTranslationButtons {
    [self.translationSourceButton removeAllItems];
    [self.translationTargetButton removeAllItems];
    
    NSMutableOrderedSet *sourceTitles = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet *targetTitles = [NSMutableOrderedSet orderedSet];
    for (Document *document in self.documents) {
        for (File *file in document.files) {
            [sourceTitles addObject:file.sourceLanguage];
            [targetTitles addObject:file.targetLanguage];
        }
    }
    
    [sourceTitles unionOrderedSet:targetTitles];
    
    [self.translationSourceButton addItemsWithTitles:[sourceTitles array]];
    [self.translationTargetButton addItemsWithTitles:[targetTitles array]];
}

- (IBAction)translationSourceButtonPressed:(id)sender {
    self.mainViewController.mapLanguage = [self.translationSourceButton titleOfSelectedItem];
}

- (File *)viewController:(id)controller
      alternativeFileForFile:(File *)anotherFile
                withLanguage:(NSString *)language {
    NSDictionary *thisLanguageFiles = self.filesOfLanguages[language];
    if (!thisLanguageFiles) return nil;
    return thisLanguageFiles[anotherFile.original];
}

- (IBAction)translationTargetButtonPressed:(id)sender {
    NSString *selectedTitle = [self.translationTargetButton titleOfSelectedItem];
    for (Document *document in self.documents) {
        for (File *file in document.files) {
            if ([file.targetLanguage isEqualToString:selectedTitle]) {
                self.document = document;
                return;
            }
        }
    }
}

@end
