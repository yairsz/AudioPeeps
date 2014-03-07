//
//  YSAppDelegate.m
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "YSAppDelegate.h"


@implementation YSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    self.audioVC = [[PSAudioVC alloc] initWithNibName:@"PSAudioVC" bundle:nil];  
    [self.window.contentView addSubview:self.audioVC.view];
    self.audioVC.view.frame = ((NSView*)self.window.contentView).bounds;
    
    
  
}

-(IBAction)undoLink:(id)sender {
  [self.audioVC undoLastChange:sender];
}

-(IBAction)redoLink:(id)sender {
  [self.audioVC redoLastUndo:sender];
}

- (IBAction)cut:(id)sender {
    [self.audioVC cut:sender];
}
- (IBAction)copy:(id)sender {
    [self.audioVC copy:sender];
}
- (IBAction)paste:(id)sender{
    [self.audioVC paste:sender];
}

@end
