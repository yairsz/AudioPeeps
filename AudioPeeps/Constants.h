//
//  Constants.h
//  AudioPeeps
//
//  Created by Yair Szarf on 2/26/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#ifndef AudioPeeps_Constants_h
#define AudioPeeps_Constants_h

#define AVAILABLE_FORMATS @[@"M4A",@"AIFF",@"WAVE"]

#define EXTENSIONS @[@".m4a",@".aif",@".wav"]

#define AVAILABLE_FORMATS_DICT @{ \
                        @"M4A" : AVFileTypeAppleM4A, \
                        @"AIFF": AVFileTypeAIFF, \
                        @"WAVE": AVFileTypeWAVE\
                        }

#define TYPES_DICT @{ \
                    AVFileTypeAppleM4A : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC], \
                    AVFileTypeWAVE : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], \
                    AVFileTypeAIFF : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM],\
                    AVFileTypeAIFC : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM],\
                    }
#define SETTINGS_DICT @{ \
                    AVFileTypeAppleM4A : @{ \
                    AVFormatIDKey         : self.formatIDKey, \
                    AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],\
                    AVSampleRateKey       : [NSNumber numberWithInteger:44100],\
                    AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]\
                    }, \
                    AVFileTypeWAVE : @{ \
                    AVFormatIDKey                   : self.formatIDKey, \
                    AVLinearPCMIsNonInterleavedKey  : AVLinearPCMIsNonInterleaved, \
                    AVLinearPCMIsBigEndianKey       : @NO, \
                    AVLinearPCMBitDepthKey          : [NSNumber numberWithInt:16], \
                    AVLinearPCMIsFloatKey           : @NO, \
                    AVSampleRateKey                 : [NSNumber numberWithInteger:44100], \
                    AVNumberOfChannelsKey           : [NSNumber numberWithUnsignedInteger:2] \
                    }, \
                    AVFileTypeAIFF : @{ \
                    AVFormatIDKey                   : self.formatIDKey, \
                    AVLinearPCMIsNonInterleavedKey  : AVLinearPCMIsNonInterleaved, \
                    AVLinearPCMIsBigEndianKey       : @YES, \
                    AVLinearPCMBitDepthKey          : [NSNumber numberWithInt:16], \
                    AVLinearPCMIsFloatKey           : @NO, \
                    AVSampleRateKey                 : [NSNumber numberWithInteger:44100], \
                    AVNumberOfChannelsKey           : [NSNumber numberWithUnsignedInteger:2] \
                    }, \
                    AVFileTypeAIFC : @{ \
                    AVFormatIDKey                   : self.formatIDKey, \
                    AVLinearPCMIsNonInterleavedKey  : AVLinearPCMIsNonInterleaved, \
                    AVLinearPCMIsBigEndianKey       : @NO, \
                    AVLinearPCMBitDepthKey          : [NSNumber numberWithInt:16], \
                    AVLinearPCMIsFloatKey           : @NO, \
                    AVSampleRateKey                 : [NSNumber numberWithInteger:44100], \
                    AVNumberOfChannelsKey           : [NSNumber numberWithUnsignedInteger:2] \
                    }\
}




#endif

typedef enum audioPlayerStates {
  kAudioPlayerNoFile,
  kAudioPlayerStopped,
  kAudioPlayerPlaying,
  kAudioPlayerPaused
} AudioPlayerState;
