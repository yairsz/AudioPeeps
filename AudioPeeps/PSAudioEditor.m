//
//  YSAudioEditor.m
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "PSAudioEditor.h"
#import "PSAudioTapProcessor.h"
#import "Constants.h"

@interface PSAudioEditor() <PSAudioEditorDelegate>
{
    NSURL * soundFileURL;
    
}

@property (strong, nonatomic) AVURLAsset * asset;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) PSAudioTapProcessor *tapProcessor;
@property (strong, nonatomic) dispatch_queue_t timeUpdateQueue;
@property (nonatomic) CMTime duration;

@property (strong, nonatomic) AVComposition *immutableComposition;
@property (strong, nonatomic) id observer;

@end

@implementation PSAudioEditor

#pragma mark - init and accessor methods

- (PSAudioEditor *) init {
  if (self = [super init]) {
    self.mixInputParameter1On = NO;
    self.mixInputParameter2On = NO;
    self.mixInputParameter3On = NO;
    self.mixInputParameter4On = NO;
    self.mixInputParameter5On = NO;
  }
  return self;
}


#pragma mark - Setters and Getters


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

-(AVPlayerItem *)playerItem {
  if (!_playerItem) {
    _playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
  }
  return _playerItem;
}

-(void)setImmutableComposition:(AVComposition *)immutableComposition {
  if (!_immutableComposition || !immutableComposition) {
    _immutableComposition = immutableComposition;
  } else if (_immutableComposition != immutableComposition) {
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

- (void) setPlayhead:(CGFloat)playhead
{
    _playhead = playhead;
    [self seekToTime:playhead];
}

#pragma mark - Transport Methods

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


- (BOOL) isPlaying
{
    return self.player.rate;
}



-(void)toggleMixInput:(MixInputNumber)inputNumber WithCompletion:(void (^)(BOOL))completion {
  switch (inputNumber) {
    case kMixInput1:
      if (self.mixInputParameter1On) { // it's on, turn off
        self.mixInputParameter1On = NO;
        self.tapProcessor.enableMixInput1Filter = NO;
      } else { // it's off, turn on
        self.mixInputParameter1On = YES;
        self.tapProcessor.enableMixInput1Filter = YES;
      }
      break;
    case kMixInput2:
      if (self.mixInputParameter2On) { // it's on, turn off
        self.mixInputParameter2On = NO;
        self.tapProcessor.enableMixInput2Filter = NO;
      } else { // it's off, turn on
        self.mixInputParameter2On = YES;
        self.tapProcessor.enableMixInput2Filter = YES;
      }
      break;
    case kMixInput3:
      if (self.mixInputParameter3On) { // it's on, turn off
        self.mixInputParameter3On = NO;
        self.tapProcessor.enableMixInput3Filter = NO;
      } else { // it's off, turn on
        self.mixInputParameter3On = YES;
        self.tapProcessor.enableMixInput3Filter = YES;
      }
      break;
    case kMixInput4:
      if (self.mixInputParameter4On) { // it's on, turn off
        self.mixInputParameter4On = NO;
        self.tapProcessor.enableMixInput4Filter = NO;
      } else { // it's off, turn on
        self.mixInputParameter4On = YES;
        self.tapProcessor.enableMixInput4Filter = YES;
      }
      break;
    case kMixInput5:
      if (self.mixInputParameter5On) { // it's on, turn off
        self.mixInputParameter5On = NO;
        self.tapProcessor.enableMixInput5Filter = NO;
      } else { // it's off, turn on
        self.mixInputParameter5On = YES;
        self.tapProcessor.enableMixInput5Filter = YES;
      }
      break;
      
    default:
      break;
  }
  [self.tapProcessor flushAudioMix];
  [self updatePlayerItem];
  completion(YES);
}


#pragma mark - File Methods

- (void) loadFile: (NSURL *) fileURL completion:(void (^)(BOOL))completion
{
    self.composition = nil;
    self.immutableComposition = nil;
    [self.undoManager removeAllActions];
  
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    
    self.asset = [[AVURLAsset alloc] initWithURL:fileURL options:options];
    
    AVAssetTrack * audioAssetTrack = [[self.asset tracksWithMediaType:AVMediaTypeAudio] lastObject];
  
    AVMutableCompositionTrack * compositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
  
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
  
  self.tapProcessor = [[PSAudioTapProcessor alloc] initWithTrack:compositionTrack];
  self.playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
  
  [self updatePlayerItem];
  
  self.immutableComposition = [self.composition copy];
  
    [self updateObservers];
  
    completion(YES);
}

-(void)updatePlayerItem {
  [self.playerItem setAudioMix:self.tapProcessor.audioMix];
  [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
}

- (void) deleteAudioFrom:(float) punchIn to:(float) punchOut
{
    AVMutableCompositionTrack * compositionTrack = [[self.composition tracks] lastObject];
  
    CMTime inTime = CMTimeMake(self.composition.duration.value * punchIn, self.composition.duration.timescale);
    CMTime outTime = CMTimeMake(self.composition.duration.value * punchOut, self.composition.duration.timescale);
    
    [compositionTrack removeTimeRange:CMTimeRangeMake(inTime, outTime)];
  
    self.immutableComposition = [self.composition copy];
  
    [self updateObservers];
}

- (NSString *) fileDuration{
    CMTime duration = self.player.currentItem.asset.duration;
    return [self stringFromTime:duration];
}


- (void) loadIntro:(NSURL *)introURL completion:(void(^)(BOOL success))completion
{
    
}

- (void) loadOutro:(NSURL *)outro completion:(void(^)(BOOL success))completion
{
    
    
}

#pragma mark - Utility Methods


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
