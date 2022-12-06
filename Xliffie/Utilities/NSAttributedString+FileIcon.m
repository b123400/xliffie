//
//  NSAttributedString+FileIcon.m
//  Xliffie
//
//  Created by b123400 on 2022/12/06.
//  Copyright © 2022 b123400. All rights reserved.
//

#import "NSAttributedString+FileIcon.h"
#import <AppKit/AppKit.h>

@implementation NSAttributedString (FileIcon)

+ (NSAttributedString *)attributedStringWithFileIcon:(NSString *)path {
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
    [fileString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [fileString appendAttributedString:[[NSAttributedString alloc] initWithString:path]];
    
    return fileString;
}

@end
