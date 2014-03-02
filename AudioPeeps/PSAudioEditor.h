//
//  YSAudioEditor.h
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface PSAudioEditor : NSObject

@property (strong, nonatomic) AVMutableComposition * composition;

- (void) play;
- (void) loadFile: (NSURL *) fileURL;
- (void) deleteAudioFrom:(float) punchIn to:(float) punchOut;
//- (void) exportAudio:(int)fileFormat;
- (void) seekToTime:(float)seekTime;
- (void) pause;
- (void) stop;

@end
