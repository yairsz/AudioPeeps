//
//  YSAudioVC.h
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AppKit/AppKit.h>
#import "SSDragAudioImageView.h"
#import "PSAudioEditor.h"
#import "PSAudioExporter.h"

@interface PSAudioVC : NSViewController <SSDragAudioImageViewDraggingDelegate>

@property (strong, nonatomic) PSAudioEditor * audioEditor;
@property (strong, nonatomic) PSAudioExporter * audioExporter;
@property (strong,nonatomic) NSString * fileType;
@property (strong,nonatomic) NSString * fileExtension;


-(IBAction)redoLastUndo:(id)sender;
-(IBAction)undoLastChange:(id)sender;

- (IBAction)cut:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;

@property (nonatomic) CGFloat playTime;
@property (nonatomic) float punchInValue;
@property (nonatomic) float punchOutValue;

@end
