//
//  YSAudioEditor.h
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol PSAudioEditorDelegate <NSObject>

@optional
- (void) updateCurrentTime: (NSString *) currentTime andFloat: (float) value;
- (void) playerDidFinishPLaying;

@end

@interface PSAudioEditor : NSObject

@property (strong, nonatomic) AVMutableComposition * composition;
@property (strong, nonatomic) AVComposition *immutableComposition;

@property (unsafe_unretained) id <PSAudioEditorDelegate> delegate;


//Transport
- (void) play;
- (void) pause;
- (void) stop;
- (void) seekToTime:(float)seekTime;
- (BOOL) isPlaying;


//File
- (void) loadFile: (NSURL *) fileURL completion:(void(^)(BOOL success))completion;
- (void) deleteAudioFrom:(float) punchIn to:(float) punchOut;
- (NSString *) fileDuration;

-(void)undoAllChangesWithCompletion:(void (^)(BOOL success))completion;

@end
