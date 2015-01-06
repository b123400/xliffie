//
//  ViewController.m
//  Xliffie
//
//  Created by b123400 on 5/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "ViewController.h"
#import "File.h"
#import "TranslationPair.h"

@interface ViewController ()

@property (weak) IBOutlet NSOutlineView *outlineView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item {
    return [item isKindOfClass:[File class]];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView
  numberOfChildrenOfItem:(id)item {
    if (!item) {
        return self.document.files.count;
    } else if ([item isKindOfClass:[File class]]) {
        return [(File*)item translations].count;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(NSInteger)index
           ofItem:(id)item {
    if (!item) {
        return self.document.files[index];
    } else if ([item isKindOfClass:[File class]]) {
        return [[(File*)item translations] objectAtIndex:index];
    }
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item {
    if ([item isKindOfClass:[TranslationPair class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            return [(TranslationPair*)item source];
        } else if ([[tableColumn identifier] isEqualToString:@"target"]) {
            return [(TranslationPair*)item target];
        } else if ([[tableColumn identifier] isEqualToString:@"note"]) {
            return [(TranslationPair*)item note];
        }
    } else if ([item isKindOfClass:[File class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            return [(File*)item original];
        }
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView
     setObjectValue:(id)object
     forTableColumn:(NSTableColumn *)tableColumn
             byItem:(id)item {
    
    if ([item isKindOfClass:[TranslationPair class]]) {
        if ([[tableColumn identifier] isEqualToString:@"source"]) {
            [(TranslationPair*)item setSource:object];
        } else if ([[tableColumn identifier] isEqualToString:@"target"]) {
            [(TranslationPair*)item setTarget:object];
        } else if ([[tableColumn identifier] isEqualToString:@"note"]) {
            [(TranslationPair*)item setNote:object];
        }
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)setDocument:(Document *)document {
    _document = document;
    [self.outlineView reloadData];
}

@end
