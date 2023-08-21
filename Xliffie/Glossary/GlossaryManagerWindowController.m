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
@property (weak) IBOutlet NSTextField *glossaryDescriptionLabel;

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
    
    NSString *baseStr = NSLocalizedString(@"These databases are generated with the same source of applelocalization.com, you can read more about the generation here",@"");
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:baseStr attributes:@{
        NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
        NSFontAttributeName: self.glossaryDescriptionLabel.font,
    }];
    [str addAttributes:@{NSLinkAttributeName: [NSURL URLWithString:@"https://applelocalization.com"]} range:[baseStr rangeOfString:@"applelocalization.com"]];
    [str addAttributes:@{NSLinkAttributeName: [NSURL URLWithString:@"https://github.com/b123400/applelocalization-tools"]} range:[baseStr rangeOfString:@"here"]];
    
    self.glossaryDescriptionLabel.attributedStringValue = str;
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

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors {
    self.downloadedDatabases = [self.downloadedDatabases sortedArrayUsingDescriptors:tableView.sortDescriptors];
    [self.tableView reloadData];
}

- (IBAction)addGlossaryClicked:(id)sender {
    GlossaryDownloadWindowController *downloadController = [[GlossaryDownloadWindowController alloc] initWithLocales:@[] platform:GlossaryPlatformAny];
    self.downloadController = downloadController;
    __weak typeof(self) _self = self;
    [self.window beginSheet:downloadController.window
          completionHandler:^(NSModalResponse returnCode) {
        [_self reload];
        _self.downloadController = nil;
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
