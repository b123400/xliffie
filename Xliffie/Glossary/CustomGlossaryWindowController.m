//
//  CustomGlossaryWindowController.m
//  Xliffie
//
//  Created by b123400 on 2024/02/01.
//  Copyright © 2024 b123400. All rights reserved.
//

#import "CustomGlossaryWindowController.h"

@interface CustomGlossaryWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@end

@implementation CustomGlossaryWindowController

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"CustomGlossaryWindowController"]) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 1;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return @"a";
}

@end
