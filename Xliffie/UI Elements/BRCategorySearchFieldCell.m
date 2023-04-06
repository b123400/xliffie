//
//  BRCategorySearchFieldCell.m
//  Xliffie
//
//  Created by b123400 on 2023/04/04.
//  Copyright © 2023 b123400. All rights reserved.
//

#import "BRCategorySearchFieldCell.h"
#import "BRCategorySearchField.h"
#import "NSImage+SystemImage.h"

//#define ICON_WIDTH 15
#define ICON_GAP 2

@implementation BRCategorySearchFieldCell

- (NSRect)searchTextRectForBounds:(NSRect)rect {
    CGFloat offset = [self iconsWidth];
    NSRect r = [super searchTextRectForBounds:rect];
    r.origin.x += offset;
    r.size.width -= offset;
    r.size.width = MAX(90, r.size.width);
    return r;
}

- (CGFloat)iconsWidth {
    CGFloat width = 0;
    NSRect searchTextRect = [super searchTextRectForBounds:self.controlView.bounds];
    for (NSMenuItem *item in [self selectedItems]) {
        width += [item image].size.width * (searchTextRect.size.height / [item image].size.height) + ICON_GAP;
    }
    return width;
}

- (NSArray<NSMenuItem*> *)selectedItems {
    BRCategorySearchField *searchField = (BRCategorySearchField *)self.controlView;
    NSArray<NSMenuItem*> *items = [[searchField searchMenuTemplate] itemArray];
    return [items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSMenuItem * _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return evaluatedObject.state == NSControlStateValueOn;
    }]];
}

- (void)drawSelectedIcons {
    NSRect searchTextRect = [self searchTextRectForBounds:self.controlView.bounds];
    NSRect searchButtonBound = [self searchButtonRectForBounds:self.controlView.bounds];
    
    NSPoint point = NSMakePoint(NSMaxX(searchButtonBound), (NSHeight(self.controlView.bounds) - NSHeight(searchTextRect)) / 2);
    
    NSColor *accentColor;
    if (@available(macOS 10.14, *)) {
        accentColor = [NSColor controlAccentColor];
    } else {
        accentColor = [NSColor colorForControlTint:NSDefaultControlTint];
    }

    for (NSMenuItem *item in [self selectedItems]) {
        CGFloat width = [item image].size.width * (searchTextRect.size.height / [item image].size.height);
        NSRect rect = NSMakeRect(point.x,
                                 point.y,
                                 width,
                                 searchTextRect.size.height);
        [[[item image] tintedImageWithColor:accentColor] drawInRect:rect];
        point.x += width + ICON_GAP;
    }
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawInteriorWithFrame:cellFrame inView:controlView];
    [self drawSelectedIcons];
}

@end
