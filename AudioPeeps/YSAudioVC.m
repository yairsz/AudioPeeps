//
//  YSAudioVC.m
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "YSAudioVC.h"
#define IN_TIME CMTimeMake(2, 1)
#define OUT_TIME CMTimeMake(5, 1)

@interface YSAudioVC ()
{
    NSURL * soundFileURL;
    
}

@property (weak,nonatomic) IBOutlet NSButton * setInButton;
@property (weak,nonatomic) IBOutlet NSButton * setOutButton;
@property (weak,nonatomic) IBOutlet NSButton * trimButton;
@property (strong, nonatomic) AVURLAsset * asset;
@property (strong, nonatomic) AVPlayer * player;
@property (strong, nonatomic) AVMutableComposition * composition;


@end

@implementation YSAudioVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        
    }
    return self;
}

- (AVPlayer *) player
{
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

- (AVMutableComposition *) composition
{
    if (!_composition) {
        _composition = [AVMutableComposition composition];
    }
    return  _composition;
}

- (IBAction)loadPressed:(NSButton *)sender {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"speech.wav"];
    
    
    soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    
    self.asset = [[AVURLAsset alloc] initWithURL:soundFileURL options:options];
    
    AVAssetTrack * audioAssetTrack = [[self.asset tracksWithMediaType:AVMediaTypeAudio] lastObject];
    
    AVMutableCompositionTrack * compositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.composition]];
}

- (IBAction)playPressed:(id)sender {
    
    [self.player play];
}

- (IBAction)setInPressed:(id)sender {
    
    AVMutableCompositionTrack * compositionTrack = [[self.composition tracks] lastObject];

    [compositionTrack removeTimeRange:CMTimeRangeMake(IN_TIME, OUT_TIME)];
    
}

- (IBAction)setOutPressed:(id)sender {
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
}

- (IBAction)trimPressed:(id)sender {

}

@end
