//
//  YSAudioEditor.m
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "YSAudioEditor.h"
@interface YSAudioEditor()

@property (strong, nonatomic) AVURLAsset * asset;

@end

@implementation YSAudioEditor


- (YSAudioEditor *) initWithURL: (NSURL *) URL
{
    if (self = [super init]) {
        
        NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
        _asset = [[AVURLAsset alloc] initWithURL:URL options:options];
    }
    
    return self;
}
@end
