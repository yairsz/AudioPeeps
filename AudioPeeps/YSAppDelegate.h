//
//  YSAppDelegate.h
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSAudioVC.h"

@interface YSAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic) NSWindow * audioWindow;
@property (nonatomic) PSAudioVC * audioVC;

-(IBAction)undoLink:(id)sender;
-(IBAction)redoLink:(id)sender;

@end
