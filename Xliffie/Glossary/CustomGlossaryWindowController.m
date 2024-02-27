//
//  CustomGlossaryWindowController.m
//  Xliffie
//
//  Created by b123400 on 2024/02/01.
//  Copyright © 2024 b123400. All rights reserved.
//

#import "CustomGlossaryWindowController.h"
#import "Utilities.h"
#import "CustomGlossaryDatabase.h"
#import "ProgressLoadingWindowController.h"

@interface CustomGlossaryWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSArray<CustomGlossaryRow *> *rows;
@property (weak) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) ProgressLoadingWindowController *loadingModal;

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@end

@implementation CustomGlossaryWindowController

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"CustomGlossaryWindowController"]) {
        self.rows = [NSArray array];
        self.numberFormatter = [[NSNumberFormatter alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(customGlossaryDatabaseUpdated:)
                                                     name:CUSTOM_GLOSSARY_DATABASE_UPDATED_NOTIFICATION
                                                   object:[CustomGlossaryDatabase shared]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(localeCellWllDisplayMenu:)
                                                     name:NSPopUpButtonCellWillPopUpNotification
                                                   object:nil];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self reload];
}

- (void)customGlossaryDatabaseUpdated:(NSNotification *)notification {
    [self reload];
}

- (void)reload {
    self.rows = [[[CustomGlossaryDatabase shared] allRows] sortedArrayUsingDescriptors:self.tableView.sortDescriptors];
    [self.tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.rows.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CustomGlossaryRow *r = self.rows[row];
//    Cannot set cell value by returning here, do at willDisplayCell:
//    if ([tableColumn.identifier isEqual:@"sourceLocale"]) {
//        return r.sourceLocale;
//    } else if ([tableColumn.identifier isEqual:@"targetLocale"]) {
//        return r.targetLocale;
    if ([tableColumn.identifier isEqual:@"source"]) {
        return r.source;
    } else if ([tableColumn.identifier isEqual:@"target"]) {
        return r.target;
    }
    return nil;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CustomGlossaryRow *r = self.rows[row];
    if ([tableColumn.identifier isEqualTo:@"sourceLocale"] || [tableColumn.identifier isEqualTo:@"targetLocale"]) {
        NSPopUpButtonCell *c = cell;
        NSMenu *menu = [c menu];
        menu.identifier = [NSString stringWithFormat:@"%@_%ld", tableColumn.identifier, row];
        
        NSString *targetLocale = [tableColumn.identifier isEqual:@"sourceLocale"] ? r.sourceLocale
            : [tableColumn.identifier isEqual:@"targetLocale"] ? r.targetLocale
            : nil;

        NSString *languageName = targetLocale
            ? [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:targetLocale]
            : NSLocalizedString(@"Any", @"");
        [c setTitle:languageName];
    }
}

- (void)localeCellWllDisplayMenu:(NSNotification *)notification {
    NSPopUpButtonCell *cell = [notification object];
    NSMenu *menu = [cell menu];
    NSArray *components = [[menu identifier] componentsSeparatedByString:@"_"];
    NSString *columnId = components[0];
    NSInteger row = [[self.numberFormatter numberFromString:components[1]] integerValue];
    CustomGlossaryRow *r = self.rows[row];
    NSString *targetLocale = [columnId isEqual:@"sourceLocale"] ? r.sourceLocale
        : [columnId isEqual:@"targetLocale"] ? r.targetLocale
        : nil;
    SEL targetMethod = @selector(selectedLocale:);
    [Utilities refillMenu:menu withAllAvailableLocalesWithTarget:self action:targetMethod];
    NSMenuItem *anyItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Any", @"Custom glossary locale")
                                                     action:targetMethod
                                              keyEquivalent:@""];
    anyItem.target = self;
    [menu insertItem:anyItem atIndex:0];
    
    if (targetLocale) {
        NSMenuItem *rootItem = nil;
        for (NSMenuItem *item in menu.itemArray) {
            if ([item.representedObject isEqual:targetLocale]) {
                rootItem = item;
                break;
            }
        }
        if (rootItem) {
            [menu removeItem:rootItem];
            [menu insertItem:rootItem atIndex:0];
            [cell selectItem:rootItem];
        } else {
            NSString *languageName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                           value:targetLocale];
            NSMenuItem *newSelectedItem = [[NSMenuItem alloc] initWithTitle:languageName ?: @""
                                                                     action:targetMethod
                                                              keyEquivalent:@""];
            newSelectedItem.target = self;
            newSelectedItem.representedObject = targetLocale;
            [menu insertItem:newSelectedItem atIndex:0];
            [cell selectItem:newSelectedItem];
        }
    } else {
        [cell selectItem:anyItem];
    }
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors {
    [self reload];
}

- (void)selectedLocale:(NSMenuItem *)sender {
    NSString *locale = sender.representedObject;
    while (sender.parentItem) {
        sender = sender.parentItem;
    }
    NSArray *components = [[sender.menu identifier] componentsSeparatedByString:@"_"];
    NSString *columnId = components[0];
    NSInteger row = [[self.numberFormatter numberFromString:components[1]] integerValue];
    CustomGlossaryRow *obj = self.rows[row];
    if ([columnId isEqual:@"sourceLocale"]) {
        obj.sourceLocale = locale;
    } else if ([columnId isEqual:@"targetLocale"]) {
        obj.targetLocale = locale;
    }
    [[CustomGlossaryDatabase shared] updateRow:obj];
}

#pragma mark - Buttons

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CustomGlossaryRow *obj = self.rows[row];
    if ([tableColumn.identifier isEqual:@"source"]) {
        obj.source = object;
    } else if ([tableColumn.identifier isEqual:@"target"]) {
        obj.target = object;
    }
    [[CustomGlossaryDatabase shared] updateRow:obj];
}

- (IBAction)addButtonPressed:(id)sender {
    [[CustomGlossaryDatabase shared] insertWithSourceLocale:nil
                                               targetLocale:nil
                                                     source:@""
                                                     target:@""];
    [self.tableView editColumn:2 row:self.rows.count - 1 withEvent:nil select:YES];
}

- (IBAction)deleteButtonPressed:(id)sender {
    NSIndexSet *indexes = [self.tableView selectedRowIndexes];
    NSArray *rows = self.rows;
    [CustomGlossaryDatabase shared].notificationEnabled = NO;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        CustomGlossaryRow *row = rows[idx];
        [[CustomGlossaryDatabase shared] deleteRow:row];
    }];
    [CustomGlossaryDatabase shared].notificationEnabled = YES;
    [self reload];
}

- (IBAction)exportButtonPressed:(id)sender {
    NSSavePanel *panel = [[NSSavePanel alloc] init];
    [panel setNameFieldStringValue:@"glossary.csv"];
    NSModalResponse response = [panel runModal];
    if (response == NSModalResponseOK) {
        NSProgress *progress = [[CustomGlossaryDatabase shared] exportToFile:[[panel URL] path]
                                       withTotalCount:self.rows.count
                                             callback:^(NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [[NSAlert alertWithError:error] runModal];
                }
                [self.window endSheet:self.loadingModal.window];
                self.loadingModal = nil;
            });
        }];
        ProgressLoadingWindowController *loading = [[ProgressLoadingWindowController alloc] initWithProgress:progress];
        [self.window beginSheet:loading.window completionHandler:nil];
        self.loadingModal = loading;
    }
}

- (IBAction)importButtonPressed:(id)sender {
    NSOpenPanel *panel = [[NSOpenPanel alloc] init];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[@"csv"];
    if ([panel runModal] == NSModalResponseOK) {
        NSProgress *progress = [[CustomGlossaryDatabase shared] importWithFile:panel.URL callback:^(NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.window endSheet:self.loadingModal.window];
                self.loadingModal = nil;
            });
        }];
        ProgressLoadingWindowController *loading = [[ProgressLoadingWindowController alloc] initWithProgress:progress];
        [self.window beginSheet:loading.window completionHandler:nil];
        self.loadingModal = loading;
    }
}

@end
