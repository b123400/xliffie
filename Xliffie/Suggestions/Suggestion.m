//
//  Suggestion.m
//  Xliffie
//
//  Created by b123400 on 2022/12/06.
//  Copyright © 2022 b123400. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "Suggestion.h"
#import "NSAttributedString+FileIcon.h"

@implementation Suggestion

- (NSAttributedString *)stringForDisplay {
    if (self.source == SuggestionSourceGlossary) {
        return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"From 📚Glossary", @"")];
    }
    if (self.source == SuggestionSourceFile && self.sourceFile) {
        NSString *path = self.sourceFile.original;
        NSAttributedString *fileString = [NSAttributedString attributedStringWithFileIcon:path];
        NSMutableAttributedString *fullString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"From %@",@"Suggestion popup, %@ = filename")];
        [fullString replaceCharactersInRange:[fullString.string rangeOfString:@"%@"] withAttributedString:fileString];
        return fullString;
    }
    return nil;
}

@end
