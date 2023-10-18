//
//  XMLOutlineView.m
//  Xliffie
//
//  Created by b123400 on 8/1/15.
//  Copyright (c) 2015 b123400. All rights reserved.
//

#import "XMLOutlineView.h"
#import "TranslationPair.h"
#import "BRTextAttachmentCell.h"
#import "TranslationTargetCell.h"

@interface XMLOutlineView ()

- (NSUInteger)nextEditableField:(NSUInteger)index;
- (NSUInteger)previousEditableField:(NSUInteger)index;

@end

@implementation XMLOutlineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)editColumn:(NSInteger)column row:(NSInteger)row withEvent:(NSEvent *)event select:(BOOL)select {
    [super editColumn:column row:row withEvent:event select:select];
    [self.xmlOutlineDelegate xmlOutlineView:self
                      didStartEditingColumn:column
                                        row:row
                                      event:event];
}

- (NSUInteger)nextEditableField:(NSUInteger)index {
    for (NSUInteger i = index+1; i < self.numberOfRows; i++) {
        id item = [self itemAtRow:i];
        if ([item isKindOfClass:[TranslationPair class]]) {
            return i;
        }
    }
    for (NSUInteger i = 0; i < index; i++) {
        id item = [self itemAtRow:i];
        if ([item isKindOfClass:[TranslationPair class]]) {
            return i;
        }
    }
    return NSNotFound;
}

- (NSUInteger)previousEditableField:(NSUInteger)index {
    for (NSInteger i = index-1; i >= 0; i--) {
        id item = [self itemAtRow:i];
        if ([item isKindOfClass:[TranslationPair class]]) {
            return i;
        }
    }
    for (NSInteger i = self.numberOfRows-1; i > index; i--) {
        id item = [self itemAtRow:i];
        if ([item isKindOfClass:[TranslationPair class]]) {
            return i;
        }
    }
    return NSNotFound;
}

- (void)textDidEndEditing:(NSNotification *)notification {
    NSAttributedString *attributedString = [[notification object] attributedString];
    NSString *proposed = [BRTextAttachmentCell stringForAttributedString:attributedString];
    if ([self.xmlOutlineDelegate respondsToSelector:@selector(xmlOutlineView:didEndEditingRow:proposedString:callback:)]) {
        [self.xmlOutlineDelegate xmlOutlineView:self didEndEditingRow:self.editedRow proposedString:proposed callback:^(BOOL shouldEnd) {
            
            int movement = [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue];
            NSInteger nextRow;
            
            if (shouldEnd) {
                switch (movement) {
                    case NSTabTextMovement:
                        nextRow = [self nextEditableField:self.editedRow];
                        break;
                    case NSBacktabTextMovement:
                        nextRow = [self previousEditableField:self.editedRow];
                        break;
                    default:
                        [super textDidEndEditing:notification];
                        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:self.editedRow] byExtendingSelection:NO];
                        return;
                }
                
                NSMutableDictionary *newUserInfo = [[notification userInfo] mutableCopy];
                [newUserInfo setObject:@(NSReturnTextMovement) forKey:@"NSTextMovement"];
                NSNotification *newNotification = [NSNotification notificationWithName:[notification name]
                                                                                object:[notification object]
                                                                              userInfo:newUserInfo];
                [super textDidEndEditing:newNotification];
                if (nextRow == NSNotFound) {
                    nextRow = self.editedRow;
                }
                [self selectRowIndexes:[NSIndexSet indexSetWithIndex:nextRow] byExtendingSelection:NO];
                [self editColumn:1 row:nextRow withEvent:0 select:YES];
            } else {
                [self.window makeFirstResponder:self];
            }
        }];
    }
}

- (void)textDidChange:(NSNotification *)notification {
    NSTextView *textView = [notification object];
    NSAttributedString *originalString = [textView attributedString];
    NSMutableAttributedString *m = [originalString mutableCopy];
    NSRange selection = [textView selectedRange];
    NSUInteger charCountAfterCursor = originalString.length - (selection.location + selection.length);
    NSAttributedString *replaced = [TranslationPair stringWithFormatSpecifiersReplaced:[BRTextAttachmentCell stringForAttributedString:m]];
    
    [[textView textStorage] setAttributedString:replaced];
    [textView setSelectedRange:NSMakeRange(replaced.length - charCountAfterCursor, 0)];
}

@end
