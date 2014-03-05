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
      if (noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &audioProcessingTap)) {
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

#pragma mark - MTAudioProcessingTap Callbacks

static void tap_InitCallback(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut) {
	AVAudioTapProcessorContext *context = calloc(1, sizeof(AVAudioTapProcessorContext));
    // Initialize MTAudioProcessingTap context.
	context->supportedTapProcessingFormat = false;
	context->isNonInterleaved = false;
	context->sampleRate = NAN;
	context->audioUnit1 = NULL;
  context->audioUnit2 = NULL;
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
static void tap_PrepareCallback(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat) {
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	
    // Store sample rate for -setCenterFrequency:.
	context->sampleRate = processingFormat->mSampleRate;
	
	/* Verify processing format (this is not needed for Audio Unit, but for RMS calculation). */
	context->supportedTapProcessingFormat = true;
	
	if (processingFormat->mFormatID != kAudioFormatLinearPCM) {
		NSLog(@"Unsupported audio format ID for audioProcessingTap. LinearPCM only.");
		context->supportedTapProcessingFormat = false;
	}
	
	if (!(processingFormat->mFormatFlags & kAudioFormatFlagIsFloat)) {
		NSLog(@"Unsupported audio format flag for audioProcessingTap. Float only.");
		context->supportedTapProcessingFormat = false;
	}
	
	if (processingFormat->mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
		context->isNonInterleaved = true;
	}
	
	AudioUnit parametricEQUnit;
	AudioComponentDescription audioComponentDescription1;
	audioComponentDescription1.componentType = kAudioUnitType_Effect;
	audioComponentDescription1.componentSubType = kAudioUnitSubType_BandPassFilter; // change to parametric EQ
	audioComponentDescription1.componentManufacturer = kAudioUnitManufacturer_Apple;
	audioComponentDescription1.componentFlags = 0;
	audioComponentDescription1.componentFlagsMask = 0;
	
	AudioComponent audioComponent1 = AudioComponentFindNext(NULL, &audioComponentDescription1);
	if (audioComponent1) {
		if (noErr == AudioComponentInstanceNew(audioComponent1, &parametricEQUnit)) {
			OSStatus status = noErr;
			
        // Set audio unit input/output stream format to processing format.
			if (noErr == status) {
				status = AudioUnitSetProperty(parametricEQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, processingFormat, sizeof(AudioStreamBasicDescription));
			}
			
      if (noErr == status) {
				status = AudioUnitSetProperty(parametricEQUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, processingFormat, sizeof(AudioStreamBasicDescription));
			}
			
        // Set audio unit render callback.
			if (noErr == status) {
				AURenderCallbackStruct renderCallbackStruct;
				renderCallbackStruct.inputProc = AU_RenderCallback;
				renderCallbackStruct.inputProcRefCon = (void *)tap;
				status = AudioUnitSetProperty(parametricEQUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
			}
			
        // Set audio unit maximum frames per slice to max frames.
			if (noErr == status) {
				UInt64 maximumFramesPerSlice = maxFrames;
				status = AudioUnitSetProperty(parametricEQUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
			}
			
        // Initialize audio unit.
			if (noErr == status) {
				status = AudioUnitInitialize(parametricEQUnit);
			} else {
				AudioComponentInstanceDispose(parametricEQUnit);
				parametricEQUnit = NULL;
			}
			
			context->audioUnit1 = parametricEQUnit;
		}
	}
  
	/* Create bandpass filter Audio Unit */
	AudioUnit bandpassFilterUnit;
	AudioComponentDescription audioComponentDescription2;
	audioComponentDescription2.componentType = kAudioUnitType_Effect;
	audioComponentDescription2.componentSubType = kAudioUnitSubType_Distortion;
	audioComponentDescription2.componentManufacturer = kAudioUnitManufacturer_Apple;
	audioComponentDescription2.componentFlags = 0;
	audioComponentDescription2.componentFlagsMask = 0;
	
	AudioComponent audioComponent2 = AudioComponentFindNext(NULL, &audioComponentDescription2);
	if (audioComponent2) {
		if (noErr == AudioComponentInstanceNew(audioComponent2, &bandpassFilterUnit)) {
			OSStatus status = noErr;
			
        // Set audio unit input/output stream format to processing format.
			if (noErr == status) {
				status = AudioUnitSetProperty(bandpassFilterUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, processingFormat, sizeof(AudioStreamBasicDescription));
			}
			
      if (noErr == status) {
				status = AudioUnitSetProperty(bandpassFilterUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, processingFormat, sizeof(AudioStreamBasicDescription));
			}
			
        // Set audio unit render callback.
			if (noErr == status) {
				AURenderCallbackStruct renderCallbackStruct;
				renderCallbackStruct.inputProc = AU_RenderCallback;
				renderCallbackStruct.inputProcRefCon = (void *)tap;
				status = AudioUnitSetProperty(bandpassFilterUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
			}
			
        // Set audio unit maximum frames per slice to max frames.
			if (noErr == status) {
				UInt64 maximumFramesPerSlice = maxFrames;
				status = AudioUnitSetProperty(bandpassFilterUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
			}
			
        // Initialize audio unit.
			if (noErr == status) {
				status = AudioUnitInitialize(bandpassFilterUnit);
			} else {
				AudioComponentInstanceDispose(bandpassFilterUnit);
				bandpassFilterUnit = NULL;
			}
			
			context->audioUnit2 = bandpassFilterUnit;
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
  
	if (self.isMixInput1Enabled || self.isMixInput2Enabled) {
  
    if (self.isMixInput1Enabled) {
      AudioUnit audioUnit = context->audioUnit1;
      if (audioUnit) {
        AudioTimeStamp audioTimeStamp;
        audioTimeStamp.mSampleTime = context->sampleCount;
        audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        
        status = AudioUnitRender(audioUnit, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
        if (noErr != status)
        {
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
        AudioTimeStamp audioTimeStamp;
        audioTimeStamp.mSampleTime = context->sampleCount;
        audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        
        status = AudioUnitRender(audioUnit, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
        if (noErr != status)
        {
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
	
    // Calculate root mean square (RMS) for left and right audio channel.
	for (UInt32 i = 0; i < bufferListInOut->mNumberBuffers; i++) {
		AudioBuffer *pBuffer = &bufferListInOut->mBuffers[i];
		UInt64 cSamples = numberFrames * (context->isNonInterleaved ? 1 : pBuffer->mNumberChannels);
		
		float *pData = (float *)pBuffer->mData;
		
		float rms = 0.0f;
		for (UInt32 j = 0; j < cSamples; j++) {
			rms += pData[j] * pData[j];
		}
		if (cSamples > 0) {
			rms = sqrtf(rms / cSamples);
		}
		
		if (0 == i) {
			context->leftChannelVolume = rms;
		}
    
		if (1 == i || (0 == i && 1 == bufferListInOut->mNumberBuffers)) {
			context->rightChannelVolume = rms;
		}
	}
}

#pragma mark - Audio Unit Callbacks

OSStatus AU_RenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    // Just return audio buffers from MTAudioProcessingTap.
	return MTAudioProcessingTapGetSourceAudio(inRefCon, inNumberFrames, ioData, NULL, NULL, NULL);
}