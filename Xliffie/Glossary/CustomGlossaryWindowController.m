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

@interface CustomGlossaryWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSArray<CustomGlossaryRow *> *rows;
@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@end

@implementation CustomGlossaryWindowController

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"CustomGlossaryWindowController"]) {
        self.rows = [NSArray array];
        self.numberFormatter = [[NSNumberFormatter alloc] init];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
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
        NSString *targetLocale = [tableColumn.identifier isEqual:@"sourceLocale"] ? r.sourceLocale
            : [tableColumn.identifier isEqual:@"targetLocale"] ? r.targetLocale
            : nil;
        SEL targetMethod = [tableColumn.identifier isEqual:@"sourceLocale"] ? @selector(selectedSourceLocale:)
            : [tableColumn.identifier isEqual:@"targetLocale"] ? @selector(selectedTargetLocale:)
            : nil;

        NSPopUpButtonCell *c = cell;
        NSMenu *menu = [Utilities menuOfAllAvailableLocalesWithTarget:self action:targetMethod];
        menu.identifier = [self.numberFormatter stringFromNumber:@(row)];
        NSMenuItem *anyItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Any", @"Custom glossary locale")
                                                         action:targetMethod
                                                  keyEquivalent:@""];
        anyItem.target = self;
        [menu insertItem:anyItem atIndex:0];
        c.menu = menu;
        
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
                [c selectItem:rootItem];
            } else {
                NSString *languageName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                                               value:targetLocale];
                NSMenuItem *newSelectedItem = [[NSMenuItem alloc] initWithTitle:languageName
                                                                         action:targetMethod
                                                                  keyEquivalent:@""];
                newSelectedItem.target = self;
                newSelectedItem.representedObject = targetLocale;
                [menu insertItem:newSelectedItem atIndex:0];
                [c selectItem:newSelectedItem];
            }
        }
    }
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors {
    [self reload];
}

- (void)selectedSourceLocale:(NSMenuItem *)sender {
    NSString *locale = sender.representedObject;
    NSInteger row = [[self.numberFormatter numberFromString:sender.menu.identifier] integerValue];
    CustomGlossaryRow *obj = self.rows[row];
    obj.sourceLocale = locale;
    [[CustomGlossaryDatabase shared] updateRow:obj];
    [self reload];
}

- (void)selectedTargetLocale:(NSMenuItem *)sender {
    NSString *locale = sender.representedObject;
    NSInteger row = [[self.numberFormatter numberFromString:sender.menu.identifier] integerValue];
    CustomGlossaryRow *obj = self.rows[row];
    obj.targetLocale = locale;
    [[CustomGlossaryDatabase shared] updateRow:obj];
    [self reload];
}

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
    [self reload];
    [self.tableView editColumn:2 row:self.rows.count - 1 withEvent:nil select:YES];
}

- (IBAction)deleteButtonPressed:(id)sender {
    NSIndexSet *indexes = [self.tableView selectedRowIndexes];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        CustomGlossaryRow *row = self.rows[idx];
        [[CustomGlossaryDatabase shared] deleteRow:row];
    }];
    [self reload];
}


@end
