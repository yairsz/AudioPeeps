//
//  YSAudioEditor.m
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "PSAudioEditor.h"
#import "Constants.h"

@interface PSAudioEditor()
{
    NSURL * soundFileURL;
    
}

@property (strong, nonatomic) AVURLAsset * asset;
@property (strong, nonatomic) AVPlayer * player;
@property (strong, nonatomic) dispatch_queue_t timeUpdateQueue;
@property (nonatomic) CMTime duration;

@property (strong, nonatomic) NSUndoManager *undoManager;
@property (strong, nonatomic) AVComposition *immutableComposition;
@property (strong, nonatomic) id observer;

@end

@implementation PSAudioEditor

- (PSAudioEditor *) init {
  if (self = [super init]) {
  }
  return self;
}

- (NSUndoManager *) undoManager
{
    if (!_undoManager) {
        _undoManager = [NSUndoManager new];
    }
    return _undoManager;
}

- (AVMutableComposition *) composition
{
    if (!_composition) {
        _composition = [AVMutableComposition composition];
    }
    return  _composition;
}

-(void)setImmutableComposition:(AVComposition *)immutableComposition {
  if (_immutableComposition != immutableComposition) {
      [self.undoManager registerUndoWithTarget:self selector:@selector(setImmutableComposition:) object:_immutableComposition];
    _immutableComposition = immutableComposition;
  }
}

- (AVPlayer *) player
{
    if (!_player) {
        _player = [[AVPlayer alloc] init];
        self.timeUpdateQueue = dispatch_queue_create([@"AudioEditorTimeUpdatesQueue" UTF8String], NULL);
        __weak PSAudioEditor * weakSelf = self;
        [_player addPeriodicTimeObserverForInterval:CMTimeMake(1,20)
                                              queue:self.timeUpdateQueue
                                         usingBlock:^(CMTime time) {
                                             float durSeconds = CMTimeGetSeconds(weakSelf.duration);
                                             float currSeconds = CMTimeGetSeconds(time);
                                             float value = 1/durSeconds * currSeconds;
                                             NSString * timeString = [weakSelf stringFromTime:time];
                                             [weakSelf.delegate updateCurrentTime:timeString andFloat:value];
                                         }];
    }
    return _player;
}


- (void) play
{
    
   [self.player play]; 
}

- (void) seekToTime:(float)seekTime
{
    CMTime seekCMTime = CMTimeMake(self.composition.duration.value * seekTime, self.composition.duration.timescale);
    [self.player seekToTime:seekCMTime];
}

- (void) pause
{
    [self.player pause];
}

- (void) stop
{
    [self.player pause];
    [self seekToTime:0.f];
}

- (void) loadFile: (NSURL *) fileURL completion:(void (^)(BOOL))completion
{
    self.composition = nil;
    
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    
    self.asset = [[AVURLAsset alloc] initWithURL:fileURL options:options];
    
    AVAssetTrack * audioAssetTrack = [[self.asset tracksWithMediaType:AVMediaTypeAudio] lastObject];
    
    AVMutableCompositionTrack * compositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.composition]];
  
  self.immutableComposition = [self.composition copy];
    [self updateObservers];
  
    completion(YES);
}

- (void) deleteAudioFrom:(float) punchIn to:(float) punchOut
{
    AVMutableCompositionTrack * compositionTrack = [[self.composition tracks] lastObject];
  
  self.immutableComposition = [self.composition copy];
  
    CMTime inTime = CMTimeMake(self.composition.duration.value * punchIn, self.composition.duration.timescale);
    CMTime outTime = CMTimeMake(self.composition.duration.value * punchOut, self.composition.duration.timescale);
    
    [compositionTrack removeTimeRange:CMTimeRangeMake(inTime, outTime)];
  
    [self updateObservers];
}

- (BOOL) isPlaying
{
    return self.player.rate;
}

- (NSString *) fileDuration{
    CMTime duration = self.player.currentItem.asset.duration;
    return [self stringFromTime:duration];
}

- (NSString *)stringFromTime: (CMTime) time
{
    NSString *timeIntervalString;
    
    NSInteger ti = time.value / time.timescale;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    
    if (hours) {
        timeIntervalString = [NSString stringWithFormat:@"%02li:%02li:%02li", (long)hours, (long)minutes, (long)seconds];
    } else {
        timeIntervalString = [NSString stringWithFormat:@"%02li:%02li", (long)minutes, (long)seconds];
    }
    
    return timeIntervalString;
}

- (void) updateObservers
{
    if (self.observer)[self.player removeTimeObserver:self.observer];
    self.duration = self.player.currentItem.asset.duration;
    
    __weak PSAudioEditor * weakSelf = self;
    self.observer = [self.player
                 addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:self.duration]]
                                           queue:self.timeUpdateQueue
                                      usingBlock:^{
                                          [weakSelf.delegate playerDidFinishPLaying];
                                          [weakSelf stop];
                                      }];
}

#pragma mark - undo methods

-(void)undoLatestOperationWithCompletion:(void (^)(BOOL))completion {
  [self.undoManager undo];
  self.composition = [self.immutableComposition mutableCopy];
  [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.composition]];
  [self updateObservers];
  completion(YES);
}

-(void)redoLatestUndoWithCompletion:(void (^)(BOOL))completion {
  [self.undoManager redo];
    self.composition = [self.immutableComposition mutableCopy];
  [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.composition]];
  [self updateObservers];
  completion(YES);
}

@end
