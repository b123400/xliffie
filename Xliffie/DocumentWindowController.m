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
    
    NSSplitViewItem *detailItem = [[splitVc splitViewItems] lastObject];
    self.detailViewController = (DetailViewController*)[detailItem viewController];
    
    [self.translationField setStringValue:@""];
    [(DocumentWindow*)self.window setDelegate:self];
    
    splitVc.splitView.delegate = self;
    [mainItem setCanCollapse:NO];
    [detailItem setCanCollapse:YES];
    [self collapseRightView];
}

- (void)toggleNotes {
    NSSplitViewController *splitVc = (NSSplitViewController*)[self contentViewController];
    NSSplitView *splitView = splitVc.splitView;
    
    BOOL rightViewCollapsed = [splitView isSubviewCollapsed:[[splitView subviews] objectAtIndex: 1]];
    if (rightViewCollapsed) {
        [self uncollapseRightView];
    } else {
        [self collapseRightView];
    }
}

-(void)collapseRightView
{
    NSSplitViewController *splitVc = (NSSplitViewController*)[self contentViewController];
    NSSplitView *splitView = splitVc.splitView;
    NSView *right = [[splitView subviews] objectAtIndex:1];
    NSView *left  = [[splitView subviews] objectAtIndex:0];
    NSRect leftFrame = [left frame];
    NSRect overallFrame = [splitView frame];
    [right setHidden:YES];
    [left setFrameSize:NSMakeSize(overallFrame.size.width,leftFrame.size.height)];
    [splitView display];
}

-(void)uncollapseRightView
{
    NSSplitViewController *splitVc = (NSSplitViewController*)[self contentViewController];
    NSSplitView *splitView = splitVc.splitView;
    
    NSView *left  = [[splitView subviews] objectAtIndex:0];
    NSView *right = [[splitView subviews] objectAtIndex:1];
    [right setHidden:NO];
    CGFloat dividerThickness = [splitView dividerThickness];
    // get the different frames
    NSRect leftFrame = [left frame];
    NSRect rightFrame = [right frame];
    // Adjust left frame size
    rightFrame.size.width = MAX(rightFrame.size.width, 200);
    rightFrame.size.width = MIN(self.window.frame.size.width * 0.5, 200);

    leftFrame.size.width = (leftFrame.size.width-rightFrame.size.width-dividerThickness);
    rightFrame.origin.x = leftFrame.size.width + dividerThickness;
    
    [left setFrameSize:leftFrame.size];
    [right setFrame:rightFrame];
    [splitView display];
}

-(void)windowDidBecomeKey:(NSNotification *)notification {
    
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    NSView* rightView = [[splitView subviews] objectAtIndex:1];
    return ([subview isEqual:rightView]);
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    return YES;
}

- (CGFloat)splitView:(NSSplitView *)splitView
constrainSplitPosition:(CGFloat)proposedPosition
         ofSubviewAt:(NSInteger)dividerIndex {
    proposedPosition = MAX(proposedPosition, self.window.frame.size.width/2);
    proposedPosition = MIN(proposedPosition, self.window.frame.size.width - 200);

    return proposedPosition;
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
