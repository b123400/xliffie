//
//  PreferenceWindowController.m
//  Xliffie
//
//  Created by b123400 on 2021/10/01.
//  Copyright © 2021 b123400. All rights reserved.
//

#import "PreferenceWindowController.h"
#import "MatomoTracker+Shared.h"

@interface PreferenceWindowController ()
@property (weak) IBOutlet NSButton *trackingEnabledCheckbox;


@end

@implementation PreferenceWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"PreferenceWindowController"];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.trackingEnabledCheckbox.state = [MatomoTracker shared].isOptedOut ? NSOffState : NSOnState;
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (IBAction)trackingEnabledClicked:(id)sender {
    [MatomoTracker shared].isOptedOut = self.trackingEnabledCheckbox.state == NSOffState;
}

@end
