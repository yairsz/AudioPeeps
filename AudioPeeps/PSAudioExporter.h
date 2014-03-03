//
//  YSAudioExporter.h
//  AudioPeeps
//
//  Created by Yair Szarf on 3/1/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface PSAudioExporter : NSObject

- (PSAudioExporter *) initWithAsset: (AVAsset *) asset andURL: (NSURL *) outputURL andFileType: (NSString *) fileType;
- (void)cancel;

@end
