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
@property (strong, nonatomic) NSUndoManager *undoManager;
@property (unsafe_unretained) id <PSAudioEditorDelegate> delegate;
@property BOOL mixInputParameter1On;

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
<<<<<<< HEAD
- (void) loadIntro: (NSURL *) introURL completion:(void(^)(BOOL success))completion;
- (void) loadOutro: (NSURL *) outroURL completion:(void(^)(BOOL success))completion;
=======
-(void)toggleMixInputParameter1WithCompletion:(void (^)(BOOL success))completion;
>>>>>>> 699c129fcdf45e33bd72406cd04003c5314b109f

  // undo and redo
-(void)undoLatestOperationWithCompletion:(void (^)(BOOL success))completion;
-(void)redoLatestUndoWithCompletion:(void (^)(BOOL success))completion;

@end
