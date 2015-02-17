//
//  DetailViewController.m
//  Xliffie
//
//  Created by b123400 on 18/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (strong, nonatomic) NSArray *keyArray;
@property (strong, nonatomic) NSArray *valueArray;

@end

@implementation DetailViewController

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
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([a-zA-Z0-9\.]+)\\s*=\\s*\"((?:[^\"\\\\]|\\\\.)*)\";\\s*"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (error || ![self.representedObject isKindOfClass:[NSString class]]) {
        self.keyArray = self.valueArray = nil;
        return;
    }
    __block NSUInteger expectedStartIndex = 0;
    __block BOOL parseable = YES;
    
    NSMutableDictionary *parsedDict = [NSMutableDictionary dictionary];
    
    [regex enumerateMatchesInString:self.representedObject options:0
                              range:NSMakeRange(0, [self.representedObject length])
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
                             NSString *key = [self.representedObject substringWithRange:keyRange];
                             NSString *value = [self.representedObject substringWithRange:valueRange];
                             [parsedDict setObject:value forKey:key];
    }];
    if (parseable && expectedStartIndex == [self.representedObject length]) {
        NSMutableArray *keyArray = [NSMutableArray array];
        NSMutableArray *valueArray = [NSMutableArray array];
        [parsedDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [keyArray addObject:key];
            [valueArray addObject:obj];
        }];
        self.keyArray = keyArray;
        self.valueArray = valueArray;
    } else {
        self.keyArray = self.valueArray = nil;
    }
}

#pragma mark outline view

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item {
    if (!self.keyArray) {
        return NO;
    }
    for (NSString *thisKey in self.keyArray) {
        if (thisKey == item) return YES;
    }
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView
  numberOfChildrenOfItem:(id)item {
    if (!self.keyArray) {
        return 1;
    }
    if (!item) {
        return self.keyArray.count;
    }
    return 1;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(NSInteger)index
           ofItem:(id)item {
    if (!self.keyArray) {
        return self.representedObject;
    }
    if (!item) {
        return [self.keyArray objectAtIndex:index];
    }
    return [self.valueArray objectAtIndex:[self.keyArray indexOfObject:item]];
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item {
    if (!self.keyArray) {
        return self.representedObject;
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
    [cell setObjectValue:item];
    [cell setWraps:YES];
    CGFloat height = [cell cellSizeForBounds:CGRectMake(0, 0, self.outlineView.frame.size.width-32, CGFLOAT_MAX)].height;
    return height;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return NO;
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification {
    [self.outlineView reloadData];
}

@end
