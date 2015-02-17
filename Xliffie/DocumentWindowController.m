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

@interface DocumentWindowController ()

@property (nonatomic, strong) ViewController *mainViewController;
@property (nonatomic, strong) DetailViewController *detailViewController;
@property (weak) IBOutlet NSTextField *translationField;
@property (weak) IBOutlet NSSearchField *searchField;

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
    
    [self.translationField setStringValue:@""];
    [(DocumentWindow*)self.window setDelegate:self];
    
    [splitView collapseRightView];
}

- (void)setDocument:(id)document {
    [super setDocument:document];
    self.mainViewController.document = document;
}

- (void)toggleNotes {
    DocumentWindowSplitView *splitView = self.contentViewController.view.subviews[0];
    BOOL rightViewCollapsed = [splitView isSubviewCollapsed:[[splitView subviews] objectAtIndex: 1]];
    if (rightViewCollapsed) {
        [splitView uncollapseRightView];
    } else {
        [splitView collapseRightView];
    }
}

-(void)windowDidBecomeKey:(NSNotification *)notification {
    
}

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
        NSString *displayString = [NSString stringWithFormat:NSLocalizedString(@"%@ to %@",nil), file.sourceLanguage, file.targetLanguage];
        [self.translationField setStringValue:displayString];
    } else {
        [self.translationField setStringValue:@""];
    }
}

@end
