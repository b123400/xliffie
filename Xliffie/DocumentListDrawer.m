//
//  DocumentListDrawer.m
//  Xliffie
//
//  Created by b123400 on 8/3/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//
#import "Document.h"
#import "DocumentListDrawer.h"

@interface DocumentListDrawer () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSTableView *tableView;

@end

@implementation DocumentListDrawer

- (instancetype)initWithContentSize:(NSSize)contentSize preferredEdge:(NSRectEdge)edge {
    self = [super initWithContentSize:contentSize preferredEdge:edge];
    
    self.tableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 100, 300)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"col1"];
    [column setDataCell:[[NSCell alloc] initTextCell:@"hi"]];
    [column setWidth:100];
    [self.tableView addTableColumn:column];
    
    [self setContentView:self.tableView];
    
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [self.delegate documentsForDrawer:self].count;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex {
    Document *document = [[self.delegate documentsForDrawer:self] objectAtIndex:rowIndex];
    return [[document.fileURL absoluteString] lastPathComponent];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self.delegate documentDrawer:self didSelectedDocumentAtIndex:[self.tableView selectedRow]];
}

- (void)reloadData {
    [self.tableView reloadData];
    CGRect frame = self.tableView.frame;
    frame.size.height = self.contentSize.height;
    self.tableView.frame = frame;
}

- (void)selectDocumentAtIndex:(NSUInteger)index {
    if (index == -1 || index == NSNotFound) return;
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
}

@end
