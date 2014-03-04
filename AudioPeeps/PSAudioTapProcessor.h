//
//  PSAudioTapProcessor.h
//  AudioPeeps
//
//  Created by Bennett Lin on 3/4/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVAudioMix;
@class AVAssetTrack;

@protocol AudioTapProcessorDelegate;

@interface PSAudioTapProcessor : NSObject

- (id)initWithAudioAssetTrack:(AVAssetTrack *)audioAssetTrack;

  // Properties
@property (readonly, nonatomic) AVAssetTrack *audioAssetTrack;
@property (readonly, nonatomic) AVAudioMix *audioMix;
@property (unsafe_unretained, nonatomic) id <AudioTapProcessorDelegate> delegate;
@property (nonatomic, getter = isBandpassFilterEnabled) BOOL enableBandpassFilter;
@property (nonatomic) float centerFrequency; // 0 to 1
@property (nonatomic) float bandwidth; // 0 to 1

@end

@protocol AudioTapProcessorDelegate <NSObject>

- (void)audioTapProcessor:(PSAudioTapProcessor *)audioTapProcessor
   hasNewLeftChannelValue:(float)leftChannelValue
        rightChannelValue:(float)rightChannelValue;

@end