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
#import "DocumentWindow.h"
#import "DocumentWindowController.h"

@interface GlossaryManagerWindowController ()<NSTableViewDelegate, NSTableViewDataSource>

@property (strong, nonatomic) GlossaryDownloadWindowController *downloadController;

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *deleteButton;
@property (weak) IBOutlet NSTextField *glossaryDescriptionLabel;

@property NSArray<GlossaryDatabase*> *downloadedDatabases;

@end

@implementation GlossaryManagerWindowController

+ (instancetype)shared {
    static GlossaryManagerWindowController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[GlossaryManagerWindowController alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"GlossaryManagerWindowController"]) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self reload];
    
    NSString *baseStr = NSLocalizedString(@"Apart from the built-in glossaries, you can download larger localization databases with apple-endorsed translations. For more info please click here.",@"");
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:baseStr attributes:@{
        NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
        NSFontAttributeName: self.glossaryDescriptionLabel.font,
    }];
    [str addAttributes:@{NSLinkAttributeName: [NSURL URLWithString:@"https://github.com/b123400/applelocalization-tools"]} range:[baseStr rangeOfString:@"click here"]];
    
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
    [self showDownloadSheet];
}

- (void)showDownloadSheet {
    if (self.downloadController) return;
    NSMutableArray *iOSLocales = [NSMutableArray array];
    NSMutableArray *macOSLocales = [NSMutableArray array];
    for (NSWindow *window in [[NSApplication sharedApplication] windows]) {
        if ([window isKindOfClass:[DocumentWindow class]] && [window.windowController isKindOfClass:[DocumentWindowController class]]) {
            DocumentWindowController *docWinController = (DocumentWindowController*)window.windowController;
            GlossaryPlatform platform = [docWinController detectedPlatform];
            NSString *source = [docWinController detectedSourceLocale];
            NSString *target = [docWinController detectedTargetLocale];
            NSMutableArray<NSString*> *localesForPlatform = platform == GlossaryPlatformIOS ? iOSLocales : platform == GlossaryPlatformMac ? macOSLocales : nil;
            if (![[GlossaryDatabase databaseWithPlatform:platform locale:source] isDownloaded]) {
                [localesForPlatform addObject:source];
            }
            if (![[GlossaryDatabase databaseWithPlatform:platform locale:target] isDownloaded]) {
                [localesForPlatform addObject:target];
            }
        }
    }
    GlossaryDownloadWindowController *downloadController = [[GlossaryDownloadWindowController alloc] initWithiOSLocales:iOSLocales
                                                                                                           macOSLocales:macOSLocales];
    self.downloadController = downloadController;
    __weak typeof(self) _self = self;
    [self.window beginSheet:downloadController.window
          completionHandler:^(NSModalResponse returnCode) {
        [_self reload];
        _self.downloadController = nil;
    }];
}

- (IBAction)deleteGlossaryClicked:(id)sender {
    NSIndexSet *selectedIndexSets = [self.tableView selectedRowIndexes];
    [selectedIndexSets enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        GlossaryDatabase *db = self.downloadedDatabases[idx];
        [db deleteDatabase];
    }];
    [self reload];
}

@end
