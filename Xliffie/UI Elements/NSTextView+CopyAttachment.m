//
//  NSTextView+CopyAttachment.m
//  Xliffie
//
//  Created by b123400 on 2023/10/18.
//  Copyright © 2023 b123400. All rights reserved.
//
#import <objc/runtime.h>
#import "NSTextView+CopyAttachment.h"
#import "BRTextAttachmentCell.h"

@implementation NSTextView (CopyAttachment)

/// So I tried to make a nice editable text field...
/// The default one is nice except, when I add custom NSTextAttachement in it, it doesn't handle copy and paste well.
/// I tried to implement methods like this:
/// - (BOOL)textView: writeCell: atIndex: toPasteboard: type:
/// which is designed for copying attachment, but it is only triggered when I am copy only the attachment,
/// when I copy mixed text and attachment, it doesn't merge together.
/// A solution would be returning a custom field edior from the cell, so I tried.
/// With a custom NSTextView subclass overriding -writeSelectionToPasteboard: type:, I can compute my own text to copy so that's fine,
/// however returning a [NSTextView fieldEditor] or anything would result in a text view that's kind of different from the default one,
/// even when the fieldEditor = YES is set, like pressing Enter doesn't end editing and focus ring gone missing.
/// Since all I need is overriding the copy mechanism, I decided to swizzle the method, and it goes so well.

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSTextView class];
        
        SEL originalSelector = @selector(writeSelectionToPasteboard:type:);
        SEL swizzledSelector = @selector(my_writeSelectionToPasteboard:type:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        IMP originalImp = method_getImplementation(originalMethod);
        IMP swizzledImp = method_getImplementation(swizzledMethod);
        
        class_replaceMethod(class,
                            swizzledSelector,
                            originalImp,
                            method_getTypeEncoding(originalMethod));
        class_replaceMethod(class,
                            originalSelector,
                            swizzledImp,
                            method_getTypeEncoding(swizzledMethod));
    });
}

- (BOOL)my_writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSPasteboardType)type {
    NSAttributedString *selectedString = [self.attributedString attributedSubstringFromRange:self.selectedRange];
    NSString *plainString = [BRTextAttachmentCell stringForAttributedString:selectedString];
    [pboard setString:plainString forType:type];
    return YES;
}

@end
