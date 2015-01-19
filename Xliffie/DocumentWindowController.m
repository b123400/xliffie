//
//  DocumentWindowController.m
//  Xliffie
//
//  Created by b123400 on 18/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "DocumentWindowController.h"
#import "DetailViewController.h"

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
    NSSplitViewController *splitVc = (NSSplitViewController*)[self contentViewController];
    NSSplitViewItem *mainItem = [[splitVc splitViewItems] firstObject];
    self.mainViewController = (ViewController*)[mainItem viewController];
    self.mainViewController.delegate = self;
    
    self.detailViewController = (DetailViewController*)[[[splitVc splitViewItems] lastObject] viewController];
    
    [self.translationField setStringValue:@""];
    [(DocumentWindow*)self.window setDelegate:self];
}

- (void)toggleNotes {
    NSSplitViewController *splitVc = (NSSplitViewController*)[self contentViewController];
    NSSplitViewItem *noteItem = [[splitVc splitViewItems] objectAtIndex:1];
    [[noteItem viewController] setPreferredContentSize:NSMakeSize(200, 600)];
    noteItem.animator.collapsed = !noteItem.animator.collapsed;
}

-(void)windowDidBecomeKey:(NSNotification *)notification {
    
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

- (void)viewController:(id)controller didSelectedTranslation:(TranslationPair*)pair {
    [self.detailViewController setRepresentedObject:pair.note];
}
- (IBAction)searchFilterChanged:(id)sender {
    [self.mainViewController setSearchFilter:[sender stringValue]];
}

- (void)viewController:(id)controller didSelectedFileChild:(File*)file {
    if (file.sourceLanguage && file.targetLanguage) {
        NSString *displayString = [NSString stringWithFormat:@"%@ to %@", file.sourceLanguage, file.targetLanguage];
        [self.translationField setStringValue:displayString];
    } else {
        [self.translationField setStringValue:@""];
    }
}

@end
