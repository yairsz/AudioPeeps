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

- (void) updateCurrentTime: (NSString *) currentTime andFloat: (float) value;
- (void) didFinishEdit: (NSArray *) segmentPairs; //of NSNumber;
- (void) playerDidFinishPLaying;

@end

@interface PSAudioEditor : NSObject

@property (strong, nonatomic) AVMutableComposition * composition;
@property (nonatomic) float durationInSeconds;
@property (strong, nonatomic) NSUndoManager *undoManager;
@property (unsafe_unretained) id <PSAudioEditorDelegate> delegate;
@property BOOL mixInputParameter1On;
@property BOOL mixInputParameter2On;
@property BOOL mixInputParameter3On;
@property BOOL mixInputParameter4On;
@property BOOL mixInputParameter5On;

@property (strong, nonatomic) AVAudioMix * audioMix;

@property (strong, nonatomic) AVPlayer * player;
@property (nonatomic) CGFloat playhead;

@property (nonatomic) CMTimeRange copiedTimeRange;


@property (strong,nonatomic) NSArray * currentSegments; //referenced to the source file


//Transport
- (void) play;
- (void) pause;
- (void) stop;
- (void) seekToTime:(float)seekTime;
- (BOOL) isPlaying;

//Edit
- (void) cutAudioFrom:(float) punchIn to:(float) punchOut;
- (void) copyAudioFrom:(float) punchIn to:(float) punchOut;
- (void) pasteAudioAt: (float) time;
- (void) deleteAudioFrom:(float) punchIn to:(float) punchOut;


//File
- (void) loadFile: (NSURL *) fileURL completion:(void(^)(BOOL success))completion;
- (NSString *) fileDuration;
- (void) loadIntro: (NSURL *) introURL completion:(void(^)(BOOL success))completion;
- (void) loadOutro: (NSURL *) outroURL completion:(void(^)(BOOL success))completion;

-(void)toggleMixInput:(MixInputNumber)inputNumber WithCompletion:(void (^)(BOOL success))completion;


  // undo and redo
-(void)undoLatestOperationWithCompletion:(void (^)(BOOL success))completion;
-(void)redoLatestUndoWithCompletion:(void (^)(BOOL success))completion;

@end
