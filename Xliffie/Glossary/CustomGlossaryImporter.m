//
//  CustomGlossaryImporter.m
//  Xliffie
//
//  Created by b123400 on 2024/02/17.
//  Copyright © 2024 b123400. All rights reserved.
//

#import "CustomGlossaryImporter.h"
#import "CHCSVParser.h"

@interface CustomGlossaryImporter () <CHCSVParserDelegate>

@property (nonatomic, strong) CustomGlossaryRow *currentRow;
@property (nonatomic, assign) NSInteger rowNumber;
@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, copy) void (^callback)(NSError * _Nullable error);

@end

@implementation CustomGlossaryImporter

- (NSProgress *)importFromFile:(NSURL *)url withCallback:(void (^)(NSError *error))callback {
    self.callback = callback;
    NSNumber *fileSize = nil;
    NSError *error = nil;
    [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:&error];
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:[fileSize unsignedIntegerValue]];
    self.progress = progress;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        CHCSVParser *parser = [[CHCSVParser alloc] initWithContentsOfCSVURL:url];
        parser.delegate = self;
        [parser parse];
    });
    return progress;
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber {
    self.currentRow = [[CustomGlossaryRow alloc] init];
    self.rowNumber = recordNumber;
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex {
    if (self.rowNumber == 1) return;
    switch (fieldIndex) {
        case 0:
            self.currentRow.sourceLocale = field.length ? field : nil;
            break;
        case 1:
            self.currentRow.targetLocale = field.length ? field : nil;
            break;
        case 2:
            self.currentRow.source = field;
            break;
        case 3:
            self.currentRow.target = field;
            break;
    }
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
    if (self.callback) {
        self.callback(error);
    }
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber {
    if (self.rowNumber == 1) return;
    [self.progress setCompletedUnitCount:[parser totalBytesRead]];
    [self.delegate didReadRow:self.currentRow fromImporter:self];
}

- (void)parserDidEndDocument:(CHCSVParser *)parser {
    if (self.callback) {
        self.callback(nil);
    }
}

@end
