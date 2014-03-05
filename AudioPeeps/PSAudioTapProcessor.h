//
//  PSAudioTapProcessor.h
//  AudioPeeps
//
//  Created by Bennett Lin on 3/4/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface PSAudioTapProcessor : NSObject

- (id)initWithTrack:(AVMutableCompositionTrack *)compositionTrack;

  // Properties
@property (readonly, nonatomic) AVMutableCompositionTrack *compositionTrack;
@property (readonly, nonatomic) AVMutableAudioMix *audioMix;
@property (nonatomic, getter = isMixInput1Enabled) BOOL enableMixInput1Filter;
@property (nonatomic, getter = isMixInput2Enabled) BOOL enableMixInput2Filter;
@property (nonatomic) float centerFrequency; // 0 to 1
@property (nonatomic) float bandwidth; // 0 to 1

-(void)flushAudioMix;

@end