//
//  PSAudioTapProcessor.m
//  AudioPeeps
//
//  Created by Bennett Lin on 3/4/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "PSAudioTapProcessor.h"
#import "Constants.h"

  // This struct is used to pass along data between the MTAudioProcessingTap callbacks.
typedef struct AVAudioTapProcessorContext {
	Boolean supportedTapProcessingFormat;
	Boolean isNonInterleaved;
	Float64 sampleRate;
	AudioUnit audioUnit1;
  AudioUnit audioUnit2;
  AudioUnit audioUnit3;
  AudioUnit audioUnit4;
  AudioUnit audioUnit5;
	Float64 sampleCount;
	float leftChannelVolume;
	float rightChannelVolume;
	void *self;
} AVAudioTapProcessorContext;
  // MTAudioProcessingTap callbacks.
static void tap_InitCallback(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut);
static void tap_FinalizeCallback(MTAudioProcessingTapRef tap);
static void tap_PrepareCallback(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat);
static void tap_UnprepareCallback(MTAudioProcessingTapRef tap);
static void tap_ProcessCallback(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut);
  // Audio Unit callbacks.
static OSStatus AU_RenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData);
  // Load presets
static CFPropertyListRef loadPresetForAudioUnit(AudioUnit audioUnit, NSURL *presetUrl);

@interface PSAudioTapProcessor () {
	AVMutableAudioMix *_audioMix;
}
@end

@implementation PSAudioTapProcessor

-(id)initWithTrack:(AVMutableCompositionTrack *)compositionTrack {
	NSParameterAssert(compositionTrack && [compositionTrack.mediaType isEqualToString:AVMediaTypeAudio]);
	self = [super init];
	
	if (self) {
		_compositionTrack = compositionTrack;
    
	}
	return self;
}

#pragma mark - Properties

-(void)flushAudioMix {
  _audioMix = nil;
}

-(AVMutableAudioMix *)audioMix {
	if (!_audioMix) {
		AVMutableAudioMix *audioMix = [AVMutableAudioMix new];
    AVMutableAudioMixInputParameters *audioMixInputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:self.compositionTrack];
    if (audioMixInputParameters) {
      MTAudioProcessingTapCallbacks callbacks;
      callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
      callbacks.clientInfo = (__bridge void *)self,
      callbacks.init = tap_InitCallback;
      callbacks.finalize = tap_FinalizeCallback;
      callbacks.prepare = tap_PrepareCallback;
      callbacks.unprepare = tap_UnprepareCallback;
      callbacks.process = tap_ProcessCallback;
      MTAudioProcessingTapRef audioProcessingTap;
      if (noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &audioProcessingTap)) {
        audioMixInputParameters.audioTapProcessor = audioProcessingTap;
        CFRelease(audioProcessingTap);
        audioMix.inputParameters = @[audioMixInputParameters];
        _audioMix = audioMix;
			}
		}
	}
	return _audioMix;
}

@end

#pragma mark - MTAudioProcessingTap callbacks

static void tap_InitCallback(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut) {
	AVAudioTapProcessorContext *context = calloc(1, sizeof(AVAudioTapProcessorContext));
    // Initialize MTAudioProcessingTap context.
	context->supportedTapProcessingFormat = false;
	context->isNonInterleaved = false;
	context->sampleRate = NAN;
	context->audioUnit1 = NULL;
  context->audioUnit2 = NULL;
  context->audioUnit3 = NULL;
  context->audioUnit4 = NULL;
  context->audioUnit5 = NULL;
	context->sampleCount = 0.0f;
	context->leftChannelVolume = 0.0f;
	context->rightChannelVolume = 0.0f;
	context->self = clientInfo;
	
	*tapStorageOut = context;
}

static void tap_FinalizeCallback(MTAudioProcessingTapRef tap) {
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    // Clear MTAudioProcessingTap context.
	context->self = NULL;
	free(context);
}

static void tap_PrepareCallback(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *streamBasicDescription) {
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    // Store sample rate for -setCenterFrequency:.
	context->sampleRate = streamBasicDescription->mSampleRate;
	/* Verify processing format (this is not needed for Audio Unit, but for RMS calculation). */
	context->supportedTapProcessingFormat = true;
	if (streamBasicDescription->mFormatID != kAudioFormatLinearPCM) {
		NSLog(@"Unsupported audio format ID for audioProcessingTap. LinearPCM only.");
		context->supportedTapProcessingFormat = false;
	}
	if (!(streamBasicDescription->mFormatFlags & kAudioFormatFlagIsFloat)) {
		NSLog(@"Unsupported audio format flag for audioProcessingTap. Float only.");
		context->supportedTapProcessingFormat = false;
	}
	if (streamBasicDescription->mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
		context->isNonInterleaved = true;
	}
  
	AudioUnit audioUnit1;
	AudioComponentDescription audioComponentDescription1;
	audioComponentDescription1.componentType = kAudioUnitType_Effect;
	audioComponentDescription1.componentSubType = kAudioUnitSubType_MatrixReverb;
  audioComponentDescription1.componentManufacturer = kAudioUnitManufacturer_Apple;
	audioComponentDescription1.componentFlags = 0;
	audioComponentDescription1.componentFlagsMask = 0;
	AudioComponent audioComponent1 = AudioComponentFindNext(NULL, &audioComponentDescription1);
	if (audioComponent1) {
		if (noErr == AudioComponentInstanceNew(audioComponent1, &audioUnit1)) {
			OSStatus status = noErr;
        // Set audio unit input/output stream format to processing format.
			if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit1, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
      if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit1, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
        // Set audio unit render callback.
			if (noErr == status) {
				AURenderCallbackStruct renderCallbackStruct;
				renderCallbackStruct.inputProc = AU_RenderCallback;
				renderCallbackStruct.inputProcRefCon = (void *)tap;
				status = AudioUnitSetProperty(audioUnit1, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
			}
        // Set audio unit maximum frames per slice to max frames.
			if (noErr == status) {
				UInt64 maximumFramesPerSlice = maxFrames;
				status = AudioUnitSetProperty(audioUnit1, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
			}
        // Initialize audio unit.
			if (noErr == status) {
				status = AudioUnitInitialize(audioUnit1);
			} else {
				AudioComponentInstanceDispose(audioUnit1);
				audioUnit1 = NULL;
			}
			context->audioUnit1 = audioUnit1;
		}
	}
  
	AudioUnit audioUnit2;
	AudioComponentDescription audioComponentDescription2;
	audioComponentDescription2.componentType = kAudioUnitType_Effect;
	audioComponentDescription2.componentSubType = kAudioUnitSubType_Distortion;
	audioComponentDescription2.componentManufacturer = kAudioUnitManufacturer_Apple;
	audioComponentDescription2.componentFlags = 0;
	audioComponentDescription2.componentFlagsMask = 0;
	AudioComponent audioComponent2 = AudioComponentFindNext(NULL, &audioComponentDescription2);
	if (audioComponent2) {
		if (noErr == AudioComponentInstanceNew(audioComponent2, &audioUnit2)) {
			OSStatus status = noErr;
        // Set audio unit input/output stream format to processing format.
			if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit2, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
      if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit2, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
        // Set audio unit render callback.
			if (noErr == status) {
				AURenderCallbackStruct renderCallbackStruct;
				renderCallbackStruct.inputProc = AU_RenderCallback;
				renderCallbackStruct.inputProcRefCon = (void *)tap;
				status = AudioUnitSetProperty(audioUnit2, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
			}
        // Set audio unit maximum frames per slice to max frames.
			if (noErr == status) {
				UInt64 maximumFramesPerSlice = maxFrames;
				status = AudioUnitSetProperty(audioUnit2, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
			}
        // Initialize audio unit.
			if (noErr == status) {
				status = AudioUnitInitialize(audioUnit2);
			} else {
				AudioComponentInstanceDispose(audioUnit2);
				audioUnit2 = NULL;
			}
			context->audioUnit2 = audioUnit2;
		}
	}
  
	AudioUnit audioUnit3;
	AudioComponentDescription audioComponentDescription3;
	audioComponentDescription3.componentType = kAudioUnitType_Effect;
	audioComponentDescription3.componentSubType = kAudioUnitSubType_Delay;
	audioComponentDescription3.componentManufacturer = kAudioUnitManufacturer_Apple;
	audioComponentDescription3.componentFlags = 0;
	audioComponentDescription3.componentFlagsMask = 0;
	AudioComponent audioComponent3 = AudioComponentFindNext(NULL, &audioComponentDescription3);
	if (audioComponent3) {
		if (noErr == AudioComponentInstanceNew(audioComponent3, &audioUnit3)) {
			OSStatus status = noErr;
        // Set audio unit input/output stream format to processing format.
			if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit3, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
      if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit3, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
        // Set audio unit render callback.
			if (noErr == status) {
				AURenderCallbackStruct renderCallbackStruct;
				renderCallbackStruct.inputProc = AU_RenderCallback;
				renderCallbackStruct.inputProcRefCon = (void *)tap;
				status = AudioUnitSetProperty(audioUnit3, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
			}
        // Set audio unit maximum frames per slice to max frames.
			if (noErr == status) {
				UInt64 maximumFramesPerSlice = maxFrames;
				status = AudioUnitSetProperty(audioUnit3, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
			}
        // Initialize audio unit.
			if (noErr == status) {
				status = AudioUnitInitialize(audioUnit3);
			} else {
				AudioComponentInstanceDispose(audioUnit3);
				audioUnit3 = NULL;
			}
			context->audioUnit3 = audioUnit3;
		}
	}
  
  AudioUnit audioUnit4;
	AudioComponentDescription audioComponentDescription4;
	audioComponentDescription4.componentType = kAudioUnitType_Effect;
	audioComponentDescription4.componentSubType = kAudioUnitSubType_BandPassFilter;
  audioComponentDescription4.componentManufacturer = kAudioUnitManufacturer_Apple;
	audioComponentDescription4.componentFlags = 0;
	audioComponentDescription4.componentFlagsMask = 0;
	AudioComponent audioComponent4 = AudioComponentFindNext(NULL, &audioComponentDescription4);
	if (audioComponent4) {
		if (noErr == AudioComponentInstanceNew(audioComponent4, &audioUnit4)) {
			OSStatus status = noErr;
        // Set audio unit input/output stream format to processing format.
			if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit4, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
      if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit4, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
        // Set audio unit render callback.
			if (noErr == status) {
				AURenderCallbackStruct renderCallbackStruct;
				renderCallbackStruct.inputProc = AU_RenderCallback;
				renderCallbackStruct.inputProcRefCon = (void *)tap;
				status = AudioUnitSetProperty(audioUnit4, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
			}
        // Set audio unit maximum frames per slice to max frames.
			if (noErr == status) {
				UInt64 maximumFramesPerSlice = maxFrames;
				status = AudioUnitSetProperty(audioUnit4, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
			}
        // Initialize audio unit.
			if (noErr == status) {
				status = AudioUnitInitialize(audioUnit4);
			} else {
				AudioComponentInstanceDispose(audioUnit4);
				audioUnit4 = NULL;
			}
			context->audioUnit4 = audioUnit4;
		}
	}
  
	AudioUnit audioUnit5;
	AudioComponentDescription audioComponentDescription5;
	audioComponentDescription5.componentType = kAudioUnitType_Effect;
	audioComponentDescription5.componentSubType = kAudioUnitSubType_ParametricEQ;
  audioComponentDescription5.componentManufacturer = kAudioUnitManufacturer_Apple;
	audioComponentDescription5.componentFlags = 0;
	audioComponentDescription5.componentFlagsMask = 0;
	AudioComponent audioComponent5 = AudioComponentFindNext(NULL, &audioComponentDescription5);
	if (audioComponent5) {
		if (noErr == AudioComponentInstanceNew(audioComponent5, &audioUnit5)) {
			OSStatus status = noErr;
        // Set audio unit input/output stream format to processing format.
			if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit5, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
      if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit5, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
			}
        // Set audio unit render callback.
			if (noErr == status) {
				AURenderCallbackStruct renderCallbackStruct;
				renderCallbackStruct.inputProc = AU_RenderCallback;
				renderCallbackStruct.inputProcRefCon = (void *)tap;
				status = AudioUnitSetProperty(audioUnit5, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
			}
        // Set audio unit maximum frames per slice to max frames.
			if (noErr == status) {
				UInt64 maximumFramesPerSlice = maxFrames;
				status = AudioUnitSetProperty(audioUnit5, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
			}
      
        // Set audio unit preset
      if (noErr == status ) {
        NSLog(@"preset5 being called");
        NSURL *presetURL5 = [NSURL URLWithString:@"file:///Users/bennettslin/Documents/AudioPeeps/extreme.aupreset"];
        CFPropertyListRef propertyList = loadPresetForAudioUnit(audioUnit5, presetURL5);
        
        status = AudioUnitSetProperty(audioUnit5,
                             kAudioUnitProperty_ClassInfo,
                             kAudioUnitScope_Global,
                             0,
                             &propertyList,
                             sizeof(CFPropertyListRef));
        
        CFRelease(propertyList);
        NSLog(@"preset loaded");
      }
      
        // Initialize audio unit.
			if (noErr == status) {
				status = AudioUnitInitialize(audioUnit5);
			} else {
				AudioComponentInstanceDispose(audioUnit5);
				audioUnit5 = NULL;
			}
			context->audioUnit5 = audioUnit5;
		}
	}
}

static void tap_UnprepareCallback(MTAudioProcessingTapRef tap) {
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	/* Release bandpass filter Audio Unit */
	if (context->audioUnit1) {
		AudioUnitUninitialize(context->audioUnit1);
		AudioComponentInstanceDispose(context->audioUnit1);
		context->audioUnit1 = NULL;
	}
  if (context->audioUnit2) {
		AudioUnitUninitialize(context->audioUnit2);
		AudioComponentInstanceDispose(context->audioUnit2);
		context->audioUnit2 = NULL;
	}
  if (context->audioUnit3) {
		AudioUnitUninitialize(context->audioUnit3);
		AudioComponentInstanceDispose(context->audioUnit3);
		context->audioUnit3 = NULL;
	}
  if (context->audioUnit4) {
		AudioUnitUninitialize(context->audioUnit4);
		AudioComponentInstanceDispose(context->audioUnit4);
		context->audioUnit4 = NULL;
	}
  if (context->audioUnit5) {
		AudioUnitUninitialize(context->audioUnit5);
		AudioComponentInstanceDispose(context->audioUnit5);
		context->audioUnit5 = NULL;
	}
  
}
static void tap_ProcessCallback(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut) {
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	
	OSStatus status;
    // Skip processing when format not supported.
	if (!context->supportedTapProcessingFormat) {
		NSLog(@"Unsupported tap processing format.");
		return;
	}
	
	PSAudioTapProcessor *self = ((__bridge PSAudioTapProcessor *)context->self);
  
	if (self.isMixInput1Enabled || self.isMixInput2Enabled || self.isMixInput3Enabled ||
      self.isMixInput4Enabled || self.isMixInput5Enabled) {
    if (self.isMixInput1Enabled) {
      AudioUnit audioUnit = context->audioUnit1;
      if (audioUnit) {
//        NSLog(@"mix input 1 on");
        AudioTimeStamp audioTimeStamp;
        audioTimeStamp.mSampleTime = context->sampleCount;
        audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        
        status = AudioUnitRender(audioUnit, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
        if (noErr != status) {
          NSLog(@"AudioUnitRender(): %d", (int)status);
          return;
        }
          // Increment sample count for audio unit.
        context->sampleCount += numberFrames;
          // Set number of frames out.
        *numberFramesOut = numberFrames;
      }
    }
    if (self.isMixInput2Enabled) {
      AudioUnit audioUnit = context->audioUnit2;
      if (audioUnit) {
//        NSLog(@"mix input 2 on");
        AudioTimeStamp audioTimeStamp;
        audioTimeStamp.mSampleTime = context->sampleCount;
        audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        
        status = AudioUnitRender(audioUnit, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
        if (noErr != status) {
          NSLog(@"AudioUnitRender(): %d", (int)status);
          return;
        }
          // Increment sample count for audio unit.
        context->sampleCount += numberFrames;
          // Set number of frames out.
        *numberFramesOut = numberFrames;
      }
    }
    if (self.isMixInput3Enabled) {
//      NSLog(@"mix input 3 on");
      AudioUnit audioUnit = context->audioUnit3;
      if (audioUnit) {
        AudioTimeStamp audioTimeStamp;
        audioTimeStamp.mSampleTime = context->sampleCount;
        audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        
        status = AudioUnitRender(audioUnit, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
        if (noErr != status) {
          NSLog(@"AudioUnitRender(): %d", (int)status);
          return;
        }
          // Increment sample count for audio unit.
        context->sampleCount += numberFrames;
          // Set number of frames out.
        *numberFramesOut = numberFrames;
      }
    }
    if (self.isMixInput4Enabled) {
      AudioUnit audioUnit = context->audioUnit4;
      if (audioUnit) {
//        NSLog(@"mix input 4 on");
        AudioTimeStamp audioTimeStamp;
        audioTimeStamp.mSampleTime = context->sampleCount;
        audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        
        status = AudioUnitRender(audioUnit, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
        if (noErr != status) {
          NSLog(@"AudioUnitRender(): %d", (int)status);
          return;
        }
          // Increment sample count for audio unit.
        context->sampleCount += numberFrames;
          // Set number of frames out.
        *numberFramesOut = numberFrames;
      }
    }
    if (self.isMixInput5Enabled) {
      AudioUnit audioUnit = context->audioUnit5;
      if (audioUnit) {
//        NSLog(@"mix input 5 on");
        AudioTimeStamp audioTimeStamp;
        audioTimeStamp.mSampleTime = context->sampleCount;
        audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        
        status = AudioUnitRender(audioUnit, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
        if (noErr != status) {
          NSLog(@"AudioUnitRender(): %d", (int)status);
          return;
        }
          // Increment sample count for audio unit.
        context->sampleCount += numberFrames;
          // Set number of frames out.
        *numberFramesOut = numberFrames;
      }
    }
	} else {
      // Get actual audio buffers from MTAudioProcessingTap (AudioUnitRender() will fill bufferListInOut otherwise).
		status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);
		if (noErr != status) {
			NSLog(@"MTAudioProcessingTapGetSourceAudio: %d", (int)status);
			return;
		}
	}
}

#pragma mark - Audio Unit callbacks

OSStatus AU_RenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    // Just return audio buffers from MTAudioProcessingTap.
	return MTAudioProcessingTapGetSourceAudio(inRefCon, inNumberFrames, ioData, NULL, NULL, NULL);
}

CFPropertyListRef loadPresetForAudioUnit(AudioUnit audioUnit, NSURL *presetUrl) {
  CFDataRef dataRef = (CFDataRef) [NSData dataWithContentsOfURL:presetUrl];
  CFPropertyListRef presetPropertyList = 0;
  presetPropertyList = CFPropertyListCreateWithData(kCFAllocatorDefault,
                                                    dataRef,
                                                    kCFPropertyListImmutable,
                                                    NULL,
                                                    NULL);
  return presetPropertyList;
}