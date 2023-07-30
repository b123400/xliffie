//
//  GlossaryManagerWindowController.m
//  Xliffie
//
//  Created by b123400 on 2023/07/29.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "GlossaryManagerWindowController.h"
#import "GlossaryDatabase.h"
#import "GlossaryDownloadWindowController.h"

@interface GlossaryManagerWindowController ()<NSTableViewDelegate, NSTableViewDataSource>

@property (strong, nonatomic) GlossaryDownloadWindowController *downloadController;

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *deleteButton;

@property NSArray<GlossaryDatabase*> *downloadedDatabases;

@end

@implementation GlossaryManagerWindowController

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"GlossaryManagerWindowController"]) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self reload];
}

- (void)reload {
    NSMutableArray *dbs = [NSMutableArray array];
    [dbs addObjectsFromArray: [GlossaryDatabase downloadedDatabasesWithPlatform:GlossaryPlatformMac]];
    [dbs addObjectsFromArray:[GlossaryDatabase downloadedDatabasesWithPlatform:GlossaryPlatformIOS]];
    self.downloadedDatabases = dbs;
    [self.tableView reloadData];
    [self reloadDeleteButton];
}

- (void)reloadDeleteButton {
    NSInteger selected = [self.tableView selectedRow];
    [self.deleteButton setEnabled:selected >= 0];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.downloadedDatabases.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    GlossaryDatabase *db = self.downloadedDatabases[row];
    NSView *view = [tableView makeViewWithIdentifier:tableColumn.identifier
                                               owner:self];
    if ([tableColumn.identifier isEqual:@"locale"]) {
        if (![view isKindOfClass:[NSTableCellView class]]) return nil;
        NSTableCellView *cellView = (NSTableCellView *)view;
        [cellView.textField setStringValue:db.locale];
        return cellView;
    } else if ([tableColumn.identifier isEqual:@"platform"]) {
        if (![view isKindOfClass:[NSTableCellView class]]) return nil;
        NSTableCellView *cellView = (NSTableCellView *)view;
        [cellView.textField setStringValue:db.platform == GlossaryPlatformMac ? @"Mac OS X" : @"iOS"];
        return cellView;
    } else if ([tableColumn.identifier isEqual:@"fileSize"]) {
        if (![view isKindOfClass:[NSTableCellView class]]) return nil;
        NSTableCellView *cellView = (NSTableCellView *)view;
        [cellView.textField setStringValue:[NSByteCountFormatter stringFromByteCount:[db fileSize] countStyle:NSByteCountFormatterCountStyleFile]];
        return cellView;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([notification object] == self.tableView) {
        [self reloadDeleteButton];
    }
}

- (IBAction)addGlossaryClicked:(id)sender {
    GlossaryDownloadWindowController *downloadController = [[GlossaryDownloadWindowController alloc] init];
    self.downloadController = downloadController;
    __weak typeof(self) _self = self;
    [self.window beginSheet:downloadController.window
          completionHandler:^(NSModalResponse returnCode) {
        [_self reload];
    }];
}

- (IBAction)deleteGlossaryClicked:(id)sender {
    NSInteger selected = [self.tableView selectedRow];
    if (selected < 0) return;
    GlossaryDatabase *db = self.downloadedDatabases[selected];
    [db deleteDatabase];
    [self reload];
}

@end
