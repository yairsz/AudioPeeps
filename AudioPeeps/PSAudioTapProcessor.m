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

  int audioUnitsArray[5] = {kAudioUnitSubType_PeakLimiter, kAudioUnitSubType_NBandEQ, kAudioUnitSubType_NBandEQ, kAudioUnitSubType_NBandEQ, kAudioUnitSubType_NBandEQ};
  NSArray *fileNamesArray = @[@"myPreset1", @"myPreset2", @"myPreset3", @"myPreset4", @"myPreset5"];
  
//  /*
  for (int i = 0; i < 5; i++) {
   	AudioUnit audioUnit;
    AudioComponentDescription audioComponentDescription;
    audioComponentDescription.componentType = kAudioUnitType_Effect;
    audioComponentDescription.componentSubType = audioUnitsArray[i];
    audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioComponentDescription.componentFlags = 0;
    audioComponentDescription.componentFlagsMask = 0;
    AudioComponent audioComponent = AudioComponentFindNext(NULL, &audioComponentDescription);
    if (audioComponent) {
      if (noErr == AudioComponentInstanceNew(audioComponent, &audioUnit)) {
        OSStatus status = noErr;
          // Set audio unit input/output stream format to processing format.
        if (noErr == status) {
          status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
        }
        if (noErr == status) {
          status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, streamBasicDescription, sizeof(AudioStreamBasicDescription));
        }
          // Set audio unit render callback.
        if (noErr == status) {
          AURenderCallbackStruct renderCallbackStruct;
          renderCallbackStruct.inputProc = AU_RenderCallback;
          renderCallbackStruct.inputProcRefCon = (void *)tap;
          status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
        }
          // Set audio unit maximum frames per slice to max frames.
        if (noErr == status) {
          UInt64 maximumFramesPerSlice = maxFrames;
          status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
        }
        
          // Set audio unit preset
        if (noErr == status) {
          NSString *urlString = [NSString stringWithFormat:@"file:///Users/bennettslin/Documents/AudioPeeps/%@.aupreset", [fileNamesArray objectAtIndex:i]];
          NSURL *presetURL = [NSURL URLWithString:urlString];
          CFPropertyListRef propertyList = loadPresetForAudioUnit(audioUnit, presetURL);
          
          status = AudioUnitSetProperty(audioUnit,
                                        kAudioUnitProperty_ClassInfo,
                                        kAudioUnitScope_Global,
                                        0,
                                        &propertyList,
                                        sizeof(CFPropertyListRef));
          CFRelease(propertyList);
        }
        
          // Initialize audio unit.
        if (noErr == status) {
          status = AudioUnitInitialize(audioUnit);
        } else {
          AudioComponentInstanceDispose(audioUnit);
          audioUnit = NULL;
        }
        
          // there must be a better way to do this...
        switch (i) {
          case 0:
            context->audioUnit1 = audioUnit;
            break;
          case 1:
            context->audioUnit2 = audioUnit;
            break;
          case 2:
            context->audioUnit3 = audioUnit;
            break;
          case 3:
            context->audioUnit4 = audioUnit;
            break;
          case 4:
            context->audioUnit5 = audioUnit;
            break;
          default:
            break;
        }
      }
    }
  }
//   */
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
  
  BOOL mixInputBoolsArray[5] = {self.isMixInput1Enabled, self.isMixInput2Enabled, self.isMixInput3Enabled, self.isMixInput4Enabled, self.isMixInput5Enabled};
  AudioUnit contextsArray[5] = {context->audioUnit1, context->audioUnit2, context->audioUnit3, context->audioUnit4, context->audioUnit5};
  BOOL atLeastOneMixInputEnabled = NO;
  for (int i = 0; i < 5; i++) {
    if (mixInputBoolsArray[i]) {
      atLeastOneMixInputEnabled = YES;
      AudioUnit audioUnit = contextsArray[i];
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
  }
  
  if (!atLeastOneMixInputEnabled) {
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