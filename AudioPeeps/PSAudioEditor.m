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
//{
//    NSError *outError;
//    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:self.composition error:&outError];
//    BOOL success = (assetReader != nil);
//    
//    AVAsset *localAsset = assetReader.asset;
//    // Get the audio track to read.
//    AVAssetTrack *audioTrack = [[localAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
//    // Decompression settings for Linear PCM
////    NSDictionary *decompressionAudioSettings = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
//    // Create the output with the audio track and decompression settings.
//    AVAssetReaderOutput *trackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
//    // Add the output to the reader if possible.
//    if ([assetReader canAddOutput:trackOutput])
//        [assetReader addOutput:trackOutput];
//    
//    
//    
//    // Start the asset reader up.
//    [assetReader startReading];
//    BOOL done = NO;
//    while (!done)
//    {
//        // Copy the next sample buffer from the reader output.
//        CMSampleBufferRef sampleBuffer = [trackOutput copyNextSampleBuffer];
//        if (sampleBuffer)
//        {
//            // Do something with sampleBuffer here.
//            CFRelease(sampleBuffer);
//            sampleBuffer = NULL;
//        }
//        else
//        {
//            // Find out why the asset reader output couldn't copy another sample buffer.
//            if (assetReader.status == AVAssetReaderStatusFailed)
//            {
//                NSError *failureError = assetReader.error;
//                // Handle the error here.
//                NSLog(@"%@",failureError);
//            }
//            else
//            {
//                // The asset reader output has read all of its samples.
//                done = YES;
//            }
//        }
//    }
//    
//    
//    
//    NSString *fileExtension, *fileType;
//    int fileFormatKey;
//    switch (fileFormat) {
//        case PSAudioFileFormatMP3:
//            fileFormatKey = kAudioFormatMPEGLayer3;
//            fileType = AVFileTypeMPEGLayer3;
//            fileExtension = @"mp3";
//            break;
//        case PSAudioFileFormatAAC:
//            fileFormatKey = kAudioFormatMPEG4AAC;
//            fileType = AVFileTypeMPEG4;
//            fileExtension = @"aac";
//            break;
//        case PSAudioFileFormatAIF:
//            fileFormatKey = kAudioFormatLinearPCM;
//            fileType = AVFileTypeAIFF;
//            fileExtension = @"aif";
//            break;
//    }
//    NSString *pathComponentString = [NSString stringWithFormat:@"exportFile.%@", fileExtension];
//
//    NSFileManager *manager = [NSFileManager defaultManager];
//    [manager createDirectoryAtPath:[self docsPath] withIntermediateDirectories:YES attributes:nil error:nil];
//    
//    NSString * path =[[self docsPath] stringByAppendingPathComponent:pathComponentString];
//  // Remove Existing File
//    [manager removeItemAtPath:path error:nil];
//
//    
//    NSError *outError;
//    NSURL *outputURL = [NSURL fileURLWithPath:path];;
//    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:fileType error:&outError];
//    BOOL success = (assetWriter != nil);
//    
//    
//    
//    // Configure the channel layout as stereo.
//    AudioChannelLayout stereoChannelLayout = {
//        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
//        .mChannelBitmap = 0,
//        .mNumberChannelDescriptions = 0
//    };
//    // Convert the channel layout object to an NSData object.
//    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
//    // Get the compression settings for 128 kbps AAC.
//    NSDictionary *compressionAudioSettings = @{
//                                               AVFormatIDKey         : [NSNumber numberWithUnsignedInt:fileFormatKey],
//                                               AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],
//                                               AVSampleRateKey       : [NSNumber numberWithInteger:44100],
//                                               AVChannelLayoutKey    : channelLayoutAsData,
//                                               AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]
//                                               };
//    // Create the asset writer input with the compression settings and specify the media type as audio.
//    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:compressionAudioSettings];
//    // Add the input to the writer if possible.
//    if ([assetWriter canAddInput:assetWriterInput])
//        [assetWriter addInput:assetWriterInput];
//    
//
//    AVAssetTrack *audioAssetTrack = [[self.composition tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
//    assetWriterInput.transform = audioAssetTrack.preferredTransform;
//    
//    [assetWriter startSessionAtSourceTime:kCMTimeZero];
//    // Prepare the asset writer for writing.
//    [assetWriter startWriting];
//    // Start a sample-writing session.
//    [assetWriter startSessionAtSourceTime:kCMTimeZero];
//    
//    dispatch_queue_t assetWriterQueue;
//    assetWriterQueue = dispatch_queue_create("assetWriterQueue", DISPATCH_QUEUE_SERIAL);
//    // Specify the block to execute when the asset writer is ready for media data and the queue to call it on.
//    [assetWriterInput requestMediaDataWhenReadyOnQueue:assetWriterQueue usingBlock:^{
//        while ([assetWriterInput isReadyForMoreMediaData])
//        {
//            // Get the next sample buffer.
//            CMSampleBufferRef nextSampleBuffer = [self copyNextSampleBufferToWrite];
//            if (nextSampleBuffer)
//            {
//                // If it exists, append the next sample buffer to the output file.
//                [assetWriterInput appendSampleBuffer:nextSampleBuffer];
//                CFRelease(nextSampleBuffer);
//                nextSampleBuffer = nil;
//            }
//            else
//            {
//                // Assume that lack of a next sample buffer means the sample buffer source is out of samples and mark the input as finished.
//                [assetWriterInput markAsFinished];
//                break;
//            }
//        }
//    }];
//    
//}
//
//
//- (CMSampleBufferRef) copyNextSampleBufferToWrite
//{
//    return nil;
//}


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
