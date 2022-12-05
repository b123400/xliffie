//
//  SuggestionsWindowController.m
//  Xliffie
//
//  Created by b123400 on 2022/12/05.
//  Copyright © 2022 b123400. All rights reserved.
//

#import "SuggestionsWindowController.h"

@interface SuggestionsWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *tableView;

@end

@implementation SuggestionsWindowController

+ (instancetype)shared {
    static SuggestionsWindowController *controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[SuggestionsWindowController alloc] initWithWindowNibName:@"SuggestionsWindowController"];
    });
    return controller;
}

- (instancetype)initWithWindowNibName:(NSNibName)windowNibName {
    if (self = [super initWithWindowNibName:windowNibName]) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.backgroundColor = [NSColor clearColor];
}

- (void)setSuggestions:(NSArray<Suggestion *> *)suggestions {
    _suggestions = suggestions;
    [self.tableView reloadData];
}

- (void)showAtRect:(NSRect)rect ofView:(NSView *)view {
    NSRect rectInWindow = [view convertRect:rect toView:nil];
    NSRect screenRect = [view.window convertRectToScreen:rectInWindow];
    
    CGFloat height = 20 + 25 * self.suggestions.count;
    CGFloat width = 300;
    NSRect selfRect = NSMakeRect(screenRect.origin.x,
                                 screenRect.origin.y - height,
                                 width,
                                 height);
    [self.window setFrame:selfRect display:YES];
}

- (void)hide {
    [self.window orderOut:self];
    self.suggestions = @[];
}

- (void)moveUp:(id)sender {
    NSInteger selected = [self.tableView selectedRow];
    if (selected == -1) {
        selected = self.suggestions.count - 1;
    } else {
        selected--;
    }
    if (selected >= 0 && selected < self.suggestions.count) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected]
                    byExtendingSelection:NO];
    }
}
- (void)moveDown:(id)sender {
    NSInteger selected = [self.tableView selectedRow];
    if (selected == -1) {
        selected = 0;
    } else {
        selected++;
    }
    if (selected >= 0 && selected < self.suggestions.count) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected]
                    byExtendingSelection:NO];
    }
}

- (Suggestion *)selectedSuggestion {
    NSInteger selected = self.tableView.selectedRow;
    if (selected == -1) return nil;
    return self.suggestions[selected];
}

# pragma mark - Table view

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    Suggestion *suggestion = self.suggestions[row];
    NSTableCellView *cell = [self.tableView makeViewWithIdentifier:@"cell" owner:tableView];
    cell.textField.stringValue = suggestion.title;
    return cell;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.suggestions.count;
}

@end
