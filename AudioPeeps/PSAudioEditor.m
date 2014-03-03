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
@property (strong, nonatomic) AVMutableComposition * composition;
@property (strong, nonatomic) NSUndoManager *undoManager;

@end

@implementation PSAudioEditor


- (PSAudioEditor *) initWithURL: (NSURL *) URL
{
    if (self = [super init]) {
        
        NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
        _asset = [[AVURLAsset alloc] initWithURL:URL options:options];
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


- (void) loadFile: (NSURL *) fileURL
{
    
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    
    self.asset = [[AVURLAsset alloc] initWithURL:fileURL options:options];
    
    AVAssetTrack * audioAssetTrack = [[self.asset tracksWithMediaType:AVMediaTypeAudio] lastObject];
    
    AVMutableCompositionTrack * compositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.composition]];
}

- (void) deleteAudioFrom:(float) punchIn to:(float) punchOut
{
    AVMutableCompositionTrack * compositionTrack = [[self.composition tracks] lastObject];
    
    CMTime inTime = CMTimeMake(self.composition.duration.value * punchIn, self.composition.duration.timescale);
    CMTime outTime = CMTimeMake(self.composition.duration.value * punchOut, self.composition.duration.timescale);
    
    [compositionTrack removeTimeRange:CMTimeRangeMake(inTime, outTime)];
}

- (void) exportAudio:(int)fileFormat
{
    AVAssetExportSession * export = [AVAssetExportSession exportSessionWithAsset:self.composition presetName:AVAssetExportPresetAppleM4A];
    
    
    NSString *fileExtension;
    switch (fileFormat) {
        case PSAudioFileFormatMP3:
            export.outputFileType = AVFileTypeMPEGLayer3;
            fileExtension = @"mp3";
            break;
        case PSAudioFileFormatAAC:
            export.outputFileType = AVFileTypeAppleM4A;
            fileExtension = @"mp4";
            break;
        case PSAudioFileFormatAIF:
            export.outputFileType = AVFileTypeAIFF;
            fileExtension = @"aif";
            break;
    }
    NSString *pathComponentString = [NSString stringWithFormat:@"exportFile.%@", fileExtension];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:[self docsPath] withIntermediateDirectories:YES attributes:nil error:nil];
    NSString * path =[[self docsPath] stringByAppendingPathComponent:pathComponentString];
    // Remove Existing File
    [manager removeItemAtPath:path error:nil];
    
    export.outputURL = [NSURL fileURLWithPath:path];
    export.timeRange = CMTimeRangeMake(kCMTimeZero, self.composition.duration);
    
    NSLog(@"%@",export.outputURL);
    
    [export exportAsynchronouslyWithCompletionHandler:^{
        long exportStatus = export.status;
        
        switch (exportStatus) {
                
            case AVAssetExportSessionStatusFailed: {
                
                NSDictionary *errorInfo = export.error.userInfo;
                
                NSLog (@"AVAssetExportSessionStatusFailed: %@", errorInfo);
                break;
            }
                
            case AVAssetExportSessionStatusCompleted: {
                
                NSLog (@"AVAssetExportSessionStatusCompleted");
                NSSound *sound = [NSSound soundNamed:@"Sosumi"];
                [sound play];
                break;
            }
                
            case AVAssetExportSessionStatusUnknown: { NSLog (@"AVAssetExportSessionStatusUnknown");
                break;
            }
            case AVAssetExportSessionStatusExporting: { NSLog (@"AVAssetExportSessionStatusExporting");
                break;
            }
                
            case AVAssetExportSessionStatusCancelled: { NSLog (@"AVAssetExportSessionStatusCancelled");
                
                NSLog(@"Cancellated");
                break;
            }
                
            case AVAssetExportSessionStatusWaiting: {
                NSLog (@"AVAssetExportSessionStatusWaiting");
                break;
            }
                
            default:
            {
                NSLog (@"didn't get export status");
                break;
            }
        }
        
        
        
    }];

}

- (NSString *) docsPath
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * path = dirPaths[0];
    return [path stringByAppendingPathComponent:@"AudioPeeps"];
}



@end
