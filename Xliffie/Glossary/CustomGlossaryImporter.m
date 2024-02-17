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

@end

@implementation CustomGlossaryImporter

- (void)importFromFile:(NSURL *)url {
    CHCSVParser *parser = [[CHCSVParser alloc] initWithContentsOfCSVURL:url];
    parser.delegate = self;
    [parser parse];
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

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber {
    if (self.rowNumber == 1) return;
    [self.delegate didReadRow:self.currentRow fromImporter:self];
}

@end
