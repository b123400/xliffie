//
//  Suggestion.m
//  Xliffie
//
//  Created by b123400 on 2022/12/06.
//  Copyright © 2022 b123400. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "Suggestion.h"

@implementation Suggestion

- (NSAttributedString *)stringForDisplay {
    if (self.source == SuggestionSourceGlossary) {
        return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"From 📚Glossary", @"")];
    }
    if (self.source == SuggestionSourceFile && self.sourceFile) {
        NSString *path = self.sourceFile.original;
        CFStringRef fileExtension = (__bridge CFStringRef)[path pathExtension];
        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
        NSImage *image = [[NSWorkspace sharedWorkspace]iconForFileType:(__bridge NSString *)fileUTI];
        
        NSMutableAttributedString *fileString = [[NSMutableAttributedString alloc] init];
        if (image) {
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = image;
            attachment.bounds = CGRectMake(0, -3, 16, 16);
            [fileString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
        }
        [fileString appendAttributedString:[[NSAttributedString alloc] initWithString:self.sourceFile.original]];
        
        NSMutableAttributedString *fullString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"From %@",@"Suggestion popup, %@ = filename")];
        [fullString replaceCharactersInRange:[fullString.string rangeOfString:@"%@"] withAttributedString:fileString];
        
        return fullString;
    }
    return nil;
}

@end
