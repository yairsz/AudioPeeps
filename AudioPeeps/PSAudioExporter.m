//
//  YSAudioExporter.m
//  AudioPeeps
//
//  Created by Yair Szarf on 3/1/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "PSAudioExporter.h"

@interface PSAudioExporter ()
@property (strong, nonatomic) dispatch_queue_t mainSerializationQueue, rwAudioSerializationQueue;
@property (strong, nonatomic) dispatch_group_t dispatchGroup;

@property (nonatomic) BOOL cancelled;
@property (nonatomic) BOOL audioFinished;

@property (strong, nonatomic) NSURL * outputURL;
@property (strong, nonatomic) AVAssetWriter * assetWriter;
@property (strong, nonatomic) AVAssetWriterInput * assetWriterAudioInput;

@property (strong, nonatomic) AVAssetReader * assetReader;
@property (strong, nonatomic) AVAssetReaderAudioMixOutput * assetReaderAudioMixOutput;
@property (strong, nonatomic) AVAudioMix * audioMix;
@property (strong, nonatomic) NSNumber * formatIDKey;

@property (strong, nonatomic) NSArray *metadataArray;

@property (strong, nonatomic) AVAsset * asset;
@property (strong,nonatomic) NSString * fileType;
@property (strong,nonatomic) NSMutableDictionary * settingsDict;

@end

@implementation PSAudioExporter

- (PSAudioExporter *) initWithAsset: (AVAsset *) asset andURL: (NSURL *) outputURL andFileType: (NSString *) fileType andAudioMix:(AVAudioMix *)audioMix andMetadataArray:(NSArray *)metadataArray
{
    if (self = [super init]) {
        self.audioMix = audioMix;
      self.metadataArray = metadataArray;
    NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
    // Create the main serialization queue.
    self.mainSerializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    NSString *rwAudioSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw audio serialization queue", self];
    // Create the serialization queue to use for reading and writing the audio data.
    self.rwAudioSerializationQueue = dispatch_queue_create([rwAudioSerializationQueueDescription UTF8String], NULL);

        self.fileType = fileType;
        self.asset = asset;
        self.cancelled = NO;
        self.outputURL = outputURL;
        // Asynchronously load the tracks of the asset you want to read.
        [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
            // Once the tracks have finished loading, dispatch the work to the main serialization queue.
            dispatch_async(self.mainSerializationQueue, ^{
                // Due to asynchronous nature, check to see if user has already cancelled.
                if (self.cancelled)
                    return;
                BOOL success = YES;
                NSError *localError = nil;
                // Check for success of loading the assets tracks.
                success = ([_asset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
                if (success)
                {
                    // If the tracks loaded successfully, make sure that no file exists at the output path for the asset writer.
                    NSFileManager *fm = [NSFileManager defaultManager];
                    NSString *localOutputPath = [self.outputURL path];
                    if ([fm fileExistsAtPath:localOutputPath])
                        success = [fm removeItemAtPath:localOutputPath error:&localError];
                }
                if (success)
                    success = [self setupAssetReaderAndAssetWriter:&localError];
                if (success)
                    success = [self startAssetReaderAndWriter:&localError]; 
                if (!success)
                    [self readingAndWritingDidFinishSuccessfully:success withError:localError];
            });
        }];
        
        
        
    }
    return self;
}

- (BOOL)setupAssetReaderAndAssetWriter:(NSError **)outError
{
    // Create and initialize the asset reader.
    self.assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:outError];
    BOOL success = (self.assetReader != nil);
    if (success)
    {
        // If the asset reader was successfully initialized, do the same for the asset writer.
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputURL fileType:self.fileType error:outError];
      
      self.assetWriter.metadata = self.metadataArray;
      
        success = (self.assetWriter != nil);
    }
    
    if (success)
    {
        // If the reader and writer were successfully initialized, grab the audio and video asset tracks that will be used.
        AVAssetTrack *assetAudioTrack = nil;
        NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] > 0)
            assetAudioTrack = [audioTracks objectAtIndex:0];
        
        if (assetAudioTrack)
        {
            // If there is an audio track to read, set the decompression settings to Linear PCM and create the asset reader output.
            NSDictionary *decompressionAudioSettings = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
            self.assetReaderAudioMixOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:self.asset.tracks audioSettings:decompressionAudioSettings];
            self.assetReaderAudioMixOutput.audioMix = self.audioMix;
            [self.assetReader addOutput:self.assetReaderAudioMixOutput];
            
            // Then, set the compression settings to User Setting and create the asset writer input.
            AudioChannelLayout stereoChannelLayout = {
                .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
                .mChannelBitmap = 0,
                .mNumberChannelDescriptions = 0
            };
            NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
            [self.settingsDict addEntriesFromDictionary:@{AVChannelLayoutKey:channelLayoutAsData}];
            NSDictionary * compressionAudioSettings = [NSDictionary dictionaryWithDictionary:self.settingsDict];
            
            self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetAudioTrack mediaType] outputSettings:compressionAudioSettings];
            [self.assetWriter addInput:self.assetWriterAudioInput];
        }
        
    }
    return success;
}


- (void) setFileType:(NSString *)fileType
{
    _fileType = fileType;
    
    self.formatIDKey = [TYPES_DICT objectForKey:self.fileType];
    self.settingsDict = [[SETTINGS_DICT objectForKey:self.fileType] mutableCopy];
}

- (BOOL)startAssetReaderAndWriter:(NSError **)outError
{
    BOOL success = YES;
    // Attempt to start the asset reader.
    success = [self.assetReader startReading];
    if (!success)
        *outError = [self.assetReader error];
    if (success)
    {
        // If the reader started successfully, attempt to start the asset writer.
        success = [self.assetWriter startWriting];
        if (!success)
            *outError = [self.assetWriter error];
    }
    
    if (success)
    {
        // If the asset reader and writer both started successfully, create the dispatch group where the reencoding will take place and start a sample-writing session.
        self.dispatchGroup = dispatch_group_create();
        [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
        self.audioFinished = NO;

        
        if (self.assetWriterAudioInput)
        {
            // If there is audio to reencode, enter the dispatch group before beginning the work.
            dispatch_group_enter(self.dispatchGroup);
            // Specify the block to execute when the asset writer is ready for audio media data, and specify the queue to call it on.
            [self.assetWriterAudioInput requestMediaDataWhenReadyOnQueue:self.rwAudioSerializationQueue usingBlock:^{
                // Because the block is called asynchronously, check to see whether its task is complete.
                if (self.audioFinished)
                    return;
                BOOL completedOrFailed = NO;
                // If the task isn't complete yet, make sure that the input is actually ready for more media data.
                while ([self.assetWriterAudioInput isReadyForMoreMediaData] && !completedOrFailed)
                {
                    // Get the next audio sample buffer, and append it to the output file.
                    CMSampleBufferRef sampleBuffer = [self.assetReaderAudioMixOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL)
                    {
                        BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                        completedOrFailed = !success;
                    }
                    else
                    {
                        completedOrFailed = YES;
                    }
                }
                if (completedOrFailed)
                {
                    // Mark the input as finished, but only if we haven't already done so, and then leave the dispatch group (since the audio work has finished).
                    BOOL oldFinished = self.audioFinished;
                    self.audioFinished = YES;
                    if (oldFinished == NO)
                    {
                        [self.assetWriterAudioInput markAsFinished];
                    }
                    dispatch_group_leave(self.dispatchGroup);
                }
            }];
        }
        
        // Set up the notification that the dispatch group will send when the audio and video work have both finished.
        dispatch_group_notify(self.dispatchGroup, self.mainSerializationQueue, ^{
            BOOL finalSuccess = YES;
            __block NSError *finalError = nil;
            // Check to see if the work has finished due to cancellation.
            if (self.cancelled)
            {
                // If so, cancel the reader and writer.
                [self.assetReader cancelReading];
                [self.assetWriter cancelWriting];
            }
            else
            {
                // If cancellation didn't occur, first make sure that the asset reader didn't fail.
                if ([self.assetReader status] == AVAssetReaderStatusFailed)
                {
                    finalSuccess = NO;
                    finalError = [self.assetReader error];
                }
                // If the asset reader didn't fail, attempt to stop the asset writer and check for any errors.
                if (finalSuccess)
                {
                    [self.assetWriter finishWritingWithCompletionHandler:^{
                        if (self.assetWriter.status == AVAssetWriterStatusFailed) {
                            finalError = [self.assetWriter error];
                        }
                        // Call the method to handle completion, and pass in the appropriate parameters to indicate whether reencoding was successful.
                        [self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
                    }];
                    
                }
            }
            
        });
    }
    // Return success here to indicate whether the asset reader and writer were started successfully.
    return success;
}

- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error
{
    if (!success)
    {
        // If the reencoding process failed, we need to cancel the asset reader and writer.
        [self.assetReader cancelReading];
        [self.assetWriter cancelWriting];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Handle any UI tasks here related to failure.
        });
    }
    else
    {
        // Reencoding was successful, reset booleans.
        self.cancelled = NO;
        self.audioFinished = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            // Handle any UI tasks here related to success.
        });
    }
}

- (void)cancel
{
    // Handle cancellation asynchronously, but serialize it with the main queue.
    dispatch_async(self.mainSerializationQueue, ^{
        // If we had audio data to reencode, we need to cancel the audio work.
        if (self.assetWriterAudioInput)
        {
            // Handle cancellation asynchronously again, but this time serialize it with the audio queue.
            dispatch_async(self.rwAudioSerializationQueue, ^{
                // Update the Boolean property indicating the task is complete and mark the input as finished if it hasn't already been marked as such.
                BOOL oldFinished = self.audioFinished;
                self.audioFinished = YES;
                if (oldFinished == NO)
                {
                    [self.assetWriterAudioInput markAsFinished];
                }
                // Leave the dispatch group since the audio work is finished now.
                dispatch_group_leave(self.dispatchGroup);
            });
        }
        
        // Set the cancelled Boolean property to YES to cancel any work on the main queue as well.
        self.cancelled = YES;
    });
}

@end
