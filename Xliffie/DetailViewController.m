//
//  DetailViewController.m
//  Xliffie
//
//  Created by b123400 on 18/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "DetailViewController.h"
#import "TranslationPair.h"

@interface DetailViewController ()

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (strong, nonatomic) NSArray<NSArray<NSString *>*> *items;

@end

@implementation DetailViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.items = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    [self parseRepresentedObject];
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)parseRepresentedObject {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([a-zA-Z0-9\\.]+)\\s*=\\s*\"((?:[^\"\\\\]|\\\\.)*)\";\\s*"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    TranslationPair *pair = self.representedObject;
    if (error || ![self.representedObject isKindOfClass:[TranslationPair class]]) {
        return;
    }
    NSString *noteString = pair.note;
    __block NSUInteger expectedStartIndex = 0;
    __block BOOL parseable = YES;

    NSMutableArray<NSMutableArray<NSString*>*> *items = [NSMutableArray array];
    
    [regex enumerateMatchesInString:noteString options:0
                              range:NSMakeRange(0, [noteString length])
                         usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange thisRange = result.range;
        if (thisRange.location != expectedStartIndex) {
            parseable = NO;
            *stop = YES;
            return;
        }
        expectedStartIndex = thisRange.location + thisRange.length;
        NSRange keyRange = [result rangeAtIndex:1];
        NSRange valueRange = [result rangeAtIndex:2];
        if (keyRange.location == NSNotFound || valueRange.location == NSNotFound) {
            parseable = NO;
            *stop = YES;
            return;
        }
        NSString *key = [noteString substringWithRange:keyRange];
        NSString *value = [noteString substringWithRange:valueRange];
        [items addObject:@[key, value].mutableCopy];
    }];
    if (!parseable || expectedStartIndex != [noteString length]) {
        // If it's not completely parsable, we show the raw string to user
        items = @[@[noteString].mutableCopy].mutableCopy;
    }
    
    // Add warnings
    NSArray<NSString *> *warnings = [pair warningsForTarget];
    if (warnings.count) {
        [items addObject:[@[NSLocalizedString(@"⚠️Warnings", @"Detail view")] arrayByAddingObjectsFromArray:warnings].mutableCopy];
    }
    self.items = items;
}

#pragma mark outline view

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item {
    if ([item isKindOfClass:[NSArray class]]) {
        return [item count] > 1;
    }
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView
  numberOfChildrenOfItem:(id)item {
    if (!item) {
        return self.items.count;
    }
    if ([item isKindOfClass:[NSArray class]]) {
        return [item count] - 1;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(NSInteger)index
           ofItem:(id)item {
    if (!item) {
        return self.items[index];
    }
    if ([item isKindOfClass:[NSArray class]]) {
        return item[index + 1];
    }
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item {
    if ([item isKindOfClass:[NSArray class]]) {
        return [item firstObject];
    }
    if ([item isKindOfClass:[NSString class]]) {
        return item;
    }
    return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (item) {
        NSCell *cell = [tableColumn dataCell];
        [cell setObjectValue:item];
        [cell setWraps:YES];
        return cell;
    }
    return nil;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    NSCell *cell = [[[outlineView tableColumns] firstObject] dataCell];
    if ([item isKindOfClass:[NSArray class]]) {
        [cell setObjectValue:[item firstObject]];
    } else {
        [cell setObjectValue:item];
    }
    [cell setWraps:YES];
    CGFloat height = [cell cellSizeForBounds:CGRectMake(0, 0, [outlineView.tableColumns.firstObject width], CGFLOAT_MAX)].height;
    return height;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return NO;
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification {
    [self.outlineView reloadData];
}

@end
