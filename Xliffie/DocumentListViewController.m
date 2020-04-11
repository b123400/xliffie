//
//  DocumentListViewController.m
//  Xliffie
//
//  Created by b123400 on 2020/04/11.
//  Copyright © 2020 b123400. All rights reserved.
//

#import "DocumentListViewController.h"

@interface DocumentListViewController ()

@end

@implementation DocumentListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark table view

- (void)reloadData {
    [self.tableView reloadData];
}

- (void)selectDocumentAtIndex:(NSUInteger)index {
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[self.delegate documentsForListController:self] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSArray<NSDocument *> *documents = [self.delegate documentsForListController:self];
    NSDocument *doc = [documents objectAtIndex:row];
    return [[doc fileURL] lastPathComponent];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self.delegate listController:self didSelectedDocumentAtIndex:[self.tableView selectedRow]];
}

@end
