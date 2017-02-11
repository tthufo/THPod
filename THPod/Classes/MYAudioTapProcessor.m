/*
     File: MYAudioTapProcessor.m
 Abstract: Audio tap processor using MTAudioProcessingTap for audio visualization and processing.
  Version: 1.0.1
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "MYAudioTapProcessor.h"


typedef struct AVAudioTapProcessorContext {
	Boolean supportedTapProcessingFormat;
	Boolean isNonInterleaved;
	Float64 sampleRate;
	AudioUnit audioUnit;
    AudioUnit audioVerb;
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

@interface MYAudioTapProcessor ()
{
	AVAudioMix *_audioMix;
}

@property (readwrite) Float64   graphSampleRate;
//@property (readwrite) AUGraph   processingGraph;
//@property (readwrite) AudioUnit samplerUnit;
//@property (readwrite) AudioUnit ioUnit;
//@property (readwrite) AudioUnit rvUnit;
//@property (readwrite) AudioUnit eqUnit;
@property (readonly, nonatomic, getter=iPodEQPresetsArray) CFArrayRef mEQPresetsArray;

@end

@implementation MYAudioTapProcessor

@synthesize graphSampleRate     = _graphSampleRate;
//@synthesize samplerUnit         = _samplerUnit;
@synthesize ioUnit              = _ioUnit;
@synthesize rvUnit              = _rvUnit;
@synthesize processingGraph     = _processingGraph;
@synthesize mEQPresetsArray;

- (id)initWithAudioAssetTrack:(AVAssetTrack *)audioAssetTrack
{
	NSParameterAssert(audioAssetTrack && [audioAssetTrack.mediaType isEqualToString:AVMediaTypeAudio]);
	
	self = [super init];
	
	if (self)
	{
		_audioAssetTrack = audioAssetTrack;
		_centerFrequency = (4980.0f / 23980.0f); // equals 5000 Hz (assuming sample rate is 48k)
		_bandwidth = (500.0f / 11900.0f); // equals 600 Cents
	}
	
	return self;
}

#pragma mark - Properties

- (AVAudioMix *)audioMix
{
	if (!_audioMix)
	{
		AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
		if (audioMix)
		{
			AVMutableAudioMixInputParameters *audioMixInputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:self.audioAssetTrack];
			if (audioMixInputParameters)
			{
				MTAudioProcessingTapCallbacks callbacks;
				
				callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
				callbacks.clientInfo = (__bridge void *)self,
				callbacks.init = tap_InitCallback;
				callbacks.finalize = tap_FinalizeCallback;
				callbacks.prepare = tap_PrepareCallback;
				callbacks.unprepare = tap_UnprepareCallback;
				callbacks.process = tap_ProcessCallback;
				
				MTAudioProcessingTapRef audioProcessingTap;
				if (noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &audioProcessingTap))
				{
					audioMixInputParameters.audioTapProcessor = audioProcessingTap;
					
					CFRelease(audioProcessingTap);
					
					audioMix.inputParameters = @[audioMixInputParameters];
					
					_audioMix = audioMix;
				}
			}
		}
	}
	
	return _audioMix;
}

- (void)setCenterFrequency:(float)centerFrequency
{
	if (_centerFrequency != centerFrequency)
	{
		_centerFrequency = centerFrequency;
		
		AVAudioMix *audioMix = self.audioMix;
		if (audioMix)
		{
			// Get pointer to Audio Unit stored in MTAudioProcessingTap context.
			MTAudioProcessingTapRef audioProcessingTap = ((AVMutableAudioMixInputParameters *)audioMix.inputParameters[0]).audioTapProcessor;
			AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(audioProcessingTap);
			AudioUnit audioUnit = context->audioUnit;
			if (audioUnit)
			{
				// Update center frequency of bandpass filter Audio Unit.
				Float32 newCenterFrequency = (20.0f + ((context->sampleRate * 0.5f) - 20.0f) * self.centerFrequency); // Global, Hz, 20->(SampleRate/2), 5000
				OSStatus status = AudioUnitSetParameter(audioUnit, kBandpassParam_CenterFrequency, kAudioUnitScope_Global, 0, newCenterFrequency, 0);
				if (noErr != status)
					NSLog(@"AudioUnitSetParameter(kBandpassParam_CenterFrequency): %d", (int)status);
			}
		}
	}
}

- (void)setBandwidth:(float)bandwidth
{
	if (_bandwidth != bandwidth)
	{
		_bandwidth = bandwidth;
		
		AVAudioMix *audioMix = self.audioMix;
		if (audioMix)
		{
			MTAudioProcessingTapRef audioProcessingTap = ((AVMutableAudioMixInputParameters *)audioMix.inputParameters[0]).audioTapProcessor;
			AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(audioProcessingTap);
			AudioUnit audioUnit = context->audioUnit;
			if (audioUnit)
			{
				Float32 newBandwidth = (100.0f + 11900.0f * self.bandwidth);
                
				OSStatus status = AudioUnitSetParameter(audioUnit, 4001, kAudioUnitScope_Global, 0, newBandwidth, 0);
                
				if (noErr != status)
					NSLog(@"AudioUnitSetParameter(kBandpassParam_Bandwidth): %d", (int)status);
			}
		}
	}
}

- (void)setReverb:(AudioUnitParameterValue)gain
{
    AVAudioMix *audioMix = self.audioMix;
    
    if (audioMix)
    {
        MTAudioProcessingTapRef audioProcessingTap = ((AVMutableAudioMixInputParameters *)audioMix.inputParameters[0]).audioTapProcessor;
        AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(audioProcessingTap);
        AudioUnit audioVerb = context->audioVerb;
        
        if (audioVerb && self.isReverbFilterEnabled)
        {
            OSStatus status =   AudioUnitSetParameter(audioVerb,
                                                      kReverb2Param_DryWetMix,
                                                      kAudioUnitScope_Global,
                                                      0,
                                                      gain,
                                                      0);
            if (noErr != status)
                NSLog(@"AudioUnitSetParameter(kBandpassParam_Bandwidth): %d", (int)status);
        }
    }
}

- (void)setGain:(AudioUnitParameterValue)gain forBandAtPosition:(NSUInteger)bandPosition
{
    AudioUnitParameterID parameterID = kAUNBandEQParam_Gain + bandPosition;
    
    AVAudioMix *audioMix = self.audioMix;
    
    if (audioMix && self.isBandpassFilterEnabled)
    {
        MTAudioProcessingTapRef audioProcessingTap = ((AVMutableAudioMixInputParameters *)audioMix.inputParameters[0]).audioTapProcessor;
        AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(audioProcessingTap);
        AudioUnit audioUnit = context->audioUnit;
        if (audioUnit)
        {
                 OSStatus status =  AudioUnitSetParameter(audioUnit,
                                         parameterID,
                                         kAudioUnitScope_Global,
                                         0,
                                         gain,
                          0);
            if (noErr != status)
                NSLog(@"AudioUnitSetParameter(kBandpassParam_Bandwidth): %d", (int)status);
        }
    }
}

#pragma mark -

- (void)updateLeftChannelVolume:(float)leftChannelVolume rightChannelVolume:(float)rightChannelVolume
{
	@autoreleasepool
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			// Forward left and right channel volume to delegate.
			if (self.delegate && [self.delegate respondsToSelector:@selector(audioTabProcessor:hasNewLeftChannelValue:rightChannelValue:)])
				[self.delegate audioTabProcessor:self hasNewLeftChannelValue:leftChannelVolume rightChannelValue:rightChannelVolume];
		});
	}
}

#pragma mark - Graph

- (AudioUnit)selfAudioUnit
{
    MTAudioProcessingTapRef audioProcessingTap = ((AVMutableAudioMixInputParameters *)self.audioMix.inputParameters[0]).audioTapProcessor;
    AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(audioProcessingTap);
    AudioUnit audioUnit = context->audioUnit;
    return audioUnit;
}

- (BOOL)createAUGraph:(AudioUnit)audioUnit
{
    OSStatus result = noErr;
    AUNode ioNode, rvNode, eqNote;

    AudioComponentDescription cd = {};
    cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
    cd.componentFlags            = 0;
    cd.componentFlagsMask        = 0;
    
    result = NewAUGraph (&_processingGraph);
    NSCAssert (result == noErr, @"Unable to create an AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    cd.componentType = kAudioUnitType_Effect ;
    cd.componentSubType = kAudioUnitSubType_NBandEQ ;

//    cd.componentSubType = kAudioUnitSubType_AUiPodEQ ;
//    // Add the Reverb unit node to the graph
    result = AUGraphAddNode (self.processingGraph, &cd, &eqNote);
    NSCAssert (result == noErr, @"Unable to add the EQ unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    cd.componentType = kAudioUnitType_Effect ;
    cd.componentSubType = kAudioUnitSubType_Reverb2 ;
    // Add the EQ unit node to the graph
    result = AUGraphAddNode (self.processingGraph, &cd, &rvNode);
    NSCAssert (result == noErr, @"Unable to add the reverb unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    cd.componentType = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
    // Add the Output unit node to the graph
    result = AUGraphAddNode (self.processingGraph, &cd, &ioNode);
    NSCAssert (result == noErr, @"Unable to add the Output unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    

    
    // Open the graph
    result = AUGraphOpen (self.processingGraph);
    NSCAssert (result == noErr, @"Unable to open the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result = AUGraphConnectNodeInput (self.processingGraph, eqNote, 0, rvNode, 0);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result = AUGraphConnectNodeInput (self.processingGraph, rvNode, 0, ioNode, 0);
    NSCAssert (result == noErr, @"Unable to interconnect Reverb the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    
    result = AUGraphNodeInfo (self.processingGraph, eqNote, 0, &audioUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Reverb unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    result = AUGraphNodeInfo (self.processingGraph, rvNode, 0, &_rvUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Reverb unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
        result = AUGraphNodeInfo (self.processingGraph, ioNode, 0, &_ioUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    return YES;
}

- (void) configureAndStartAudioProcessingGraph: (AUGraph) graph
{
    
    OSStatus result = noErr;
    UInt32 framesPerSlice = 0;
    UInt32 framesPerSlicePropertySize = sizeof (framesPerSlice);
    UInt32 sampleRatePropertySize = sizeof (self.graphSampleRate);
    
    result = AudioUnitInitialize (self.ioUnit);
    NSCAssert (result == noErr, @"Unable to initialize the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Set the I/O unit's output sample rate.
    result =    AudioUnitSetProperty (
                                      self.ioUnit,
                                      kAudioUnitProperty_SampleRate,
                                      kAudioUnitScope_Output,
                                      0,
                                      &_graphSampleRate,
                                      sampleRatePropertySize
                                      );
    
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Obtain the value of the maximum-frames-per-slice from the I/O unit.
    result =    AudioUnitGetProperty (
                                      self.ioUnit,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &framesPerSlice,
                                      &framesPerSlicePropertySize
                                      );
    
    NSCAssert (result == noErr, @"Unable to retrieve the maximum frames per slice property from the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
//    // Set the Sampler unit's output sample rate.
//    result =    AudioUnitSetProperty (
//                                      self.samplerUnit,
//                                      kAudioUnitProperty_SampleRate,
//                                      kAudioUnitScope_Output,
//                                      0,
//                                      &_graphSampleRate,
//                                      sampleRatePropertySize
//                                      );
//    
//    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
//    result =    AudioUnitSetProperty (
//                                      self.samplerUnit,
//                                      kAudioUnitProperty_MaximumFramesPerSlice,
//                                      kAudioUnitScope_Global,
//                                      0,
//                                      &framesPerSlice,
//                                      framesPerSlicePropertySize
//                                      );
//
//    NSAssert( result == noErr, @"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d '%.4s'", (int) result, (const char *)&result);

    
//    UInt32 size = sizeof(mEQPresetsArray);
//    result = AudioUnitGetProperty(_eqUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &mEQPresetsArray, &size);
//    if (result) { printf("AudioUnitGetProperty result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; }
//    
//    printf("iPodEQ Factory Preset List:\n");
//    UInt8 count = CFArrayGetCount(mEQPresetsArray);
//    for (int i = 0; i < count; ++i) {
//        AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(mEQPresetsArray, i);
//        CFShow(aPreset->presetName);
//    }
    
    
    if (graph) {
        
        // Initialize the audio processing graph.
        result = AUGraphInitialize (graph);
        NSAssert (result == noErr, @"Unable to initialze AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Start the graph
        result = AUGraphStart (graph);
        NSAssert (result == noErr, @"Unable to start audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Print out the graph to the console
        CAShow (graph); 
    }
    
    [self configureAudioUnit:_rvUnit Parameter:kReverb2Param_DryWetMix withValue:100];
}

- (BOOL) setupAudioSession {
    
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [mySession setDelegate: self];
    
    // Assign the Playback category to the audio session. This category supports
    //    audio output with the Ring/Silent switch in the Silent position.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayAndRecord error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting audio session category."); return NO;}
    
    // Request a desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    
    [mySession setPreferredHardwareSampleRate: self.graphSampleRate error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting preferred hardware sample rate."); return NO;}
    
    // Activate the audio session
    [mySession setActive: YES error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error activating the audio session."); return NO;}
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    self.graphSampleRate = [mySession currentHardwareSampleRate];
    
    return YES;
}

// Stop the audio processing graph
- (void) stopAudioProcessingGraph {
    
    OSStatus result = noErr;
    if (self.processingGraph) result = AUGraphStop(self.processingGraph);
    NSAssert (result == noErr, @"Unable to stop the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

// Restart the audio processing graph
- (void) restartAudioProcessingGraph {
    
    OSStatus result = noErr;
    if (self.processingGraph) result = AUGraphStart (self.processingGraph);
    NSAssert (result == noErr, @"Unable to restart the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

//- (void)selectEQPreset:(NSInteger)value;
//{
//    AUPreset *aPreset = (AUPreset*)CFArrayGetValueAtIndex(mEQPresetsArray, value);
//    OSStatus result = AudioUnitSetProperty(_eqUnit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, aPreset, sizeof(AUPreset));
//    if (result) { printf("AudioUnitSetProperty result %ld %08X %4.4s\n", result, (unsigned int)result, (char*)&result); return; };
//    
//    printf("SET EQ PRESET %d ", value);
//    CFShow(aPreset->presetName);
//}

- (void) configureAudioUnit:(AudioUnit)audioUnit Parameter:(int)param withValue:(float)value
{
    AudioUnitSetParameter(_rvUnit,
                          kAudioUnitScope_Global,
                          0,
                          param,
                          value,
                          0.0);
    
}

#pragma mark - End Graph


@end

#pragma mark - MTAudioProcessingTap Callbacks

static void tap_InitCallback(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut)
{
	AVAudioTapProcessorContext *context = calloc(1, sizeof(AVAudioTapProcessorContext));
	
	context->supportedTapProcessingFormat = false;
	context->isNonInterleaved = false;
	context->sampleRate = NAN;
	context->audioUnit = NULL;
	context->sampleCount = 0.0f;
	context->leftChannelVolume = 0.0f;
	context->rightChannelVolume = 0.0f;
	context->self = clientInfo;
	
	*tapStorageOut = context;
}

static void tap_FinalizeCallback(MTAudioProcessingTapRef tap)
{
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	
	context->self = NULL;
    
	free(context);
}

static void tap_PrepareCallback(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat)
{
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
    
    MYAudioTapProcessor *self = ((__bridge MYAudioTapProcessor *)context->self);
    
	// Store sample rate for -setCenterFrequency:.
	context->sampleRate = processingFormat->mSampleRate;
	
	/* Verify processing format (this is not needed for Audio Unit, but for RMS calculation). */
	
	context->supportedTapProcessingFormat = true;
	
	if (processingFormat->mFormatID != kAudioFormatLinearPCM)
	{
		NSLog(@"Unsupported audio format ID for audioProcessingTap. LinearPCM only.");
		context->supportedTapProcessingFormat = false;
	}
	
	if (!(processingFormat->mFormatFlags & kAudioFormatFlagIsFloat))
	{
		NSLog(@"Unsupported audio format flag for audioProcessingTap. Float only.");
		context->supportedTapProcessingFormat = false;
	}
	
	if (processingFormat->mFormatFlags & kAudioFormatFlagIsNonInterleaved)
	{
		context->isNonInterleaved = true;
	}
    
	/* Create bandpass filter Audio Unit */
	
    AudioUnit audioUnit ;
	
	AudioComponentDescription audioComponentDescription;
	audioComponentDescription.componentFlags = 0;
	audioComponentDescription.componentFlagsMask = 0;
    
    audioComponentDescription.componentType = kAudioUnitType_Effect ;
    audioComponentDescription.componentSubType = kAudioUnitSubType_NBandEQ ;

    audioComponentDescription.componentManufacturer=kAudioUnitManufacturer_Apple;
	
	AudioComponent audioComponent = AudioComponentFindNext(NULL, &audioComponentDescription);
	if (audioComponent)
	{
		if (noErr == AudioComponentInstanceNew(audioComponent, &audioUnit))
		{
			OSStatus status = noErr;
			
			// Set audio unit input/output stream format to processing format.
			if (noErr == status)
			{
				status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, processingFormat, sizeof(AudioStreamBasicDescription));
			}
			if (noErr == status)
			{
				status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, processingFormat, sizeof(AudioStreamBasicDescription));
			}
			
			// Set audio unit render callback.
			if (noErr == status)
			{
				AURenderCallbackStruct renderCallbackStruct;
				renderCallbackStruct.inputProc = AU_RenderCallback;
                renderCallbackStruct.inputProcRefCon = (void *)tap;
				status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
			}
			
			// Set audio unit maximum frames per slice to max frames.
			if (noErr == status)
			{
				UInt32 maximumFramesPerSlice = maxFrames;
				status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
			}
			
			// Initialize audio unit.
			if (noErr == status)
			{
				status = AudioUnitInitialize(audioUnit);
			}
			
			if (noErr != status)
			{
				AudioComponentInstanceDispose(audioUnit);
				audioUnit = NULL;
			}
            
            context->audioUnit = audioUnit;
            
            if(audioUnit)
            {
                NSArray *eqFrequencies = @[ @32, @64, @125, @250, @500, @1000, @2000, @4000, @8000, @16000 ];
                
                NSArray *eqBypass = @[@0, @0, @0, @0, @0, @0, @0, @0, @0, @0];
                
                UInt32 noBands = [eqFrequencies count];
                
                // Set the number of bands first
                
                AudioUnitSetProperty(audioUnit,
                                     kAUNBandEQProperty_NumberOfBands,
                                     kAudioUnitScope_Global,
                                     0,
                                     &noBands,
                                     sizeof(noBands));
                
                // Set the frequencies
                
                for (NSUInteger i=0; i< [eqFrequencies count]; i++) {
                    AudioUnitSetParameter(audioUnit,
                                          kAUNBandEQParam_Frequency+i,
                                          kAudioUnitScope_Global,
                                          0,
                                          (AudioUnitParameterValue)[[eqFrequencies objectAtIndex:i] floatValue],
                                          0);
                }
                
                // Set the bypass
                
                for (NSUInteger i=0; i< [eqFrequencies count]; i++) {
                    AudioUnitSetParameter(audioUnit,
                                          kAUNBandEQParam_BypassBand+i,
                                          kAudioUnitScope_Global,
                                          0,
                                          (AudioUnitParameterValue)[[eqBypass objectAtIndex:i] intValue],
                                          0);
                }
            }
		}
	}
    
    
    AudioUnit audioVerb ;
    
    AudioComponentDescription ad;
    ad.componentFlags = 0;
    ad.componentFlagsMask = 0;
    
    ad.componentType = kAudioUnitType_Effect ;
    ad.componentSubType = kAudioUnitSubType_Reverb2;
    ad.componentManufacturer=kAudioUnitManufacturer_Apple;
    
    AudioComponent ac = AudioComponentFindNext(NULL, &ad);
    if (ac)
    {
        if (noErr == AudioComponentInstanceNew(ac, &audioVerb))
        {
            OSStatus status = noErr;
            
            // Set audio unit input/output stream format to processing format.
            if (noErr == status)
            {
                status = AudioUnitSetProperty(audioVerb, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, processingFormat, sizeof(AudioStreamBasicDescription));
            }
            if (noErr == status)
            {
                status = AudioUnitSetProperty(audioVerb, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, processingFormat, sizeof(AudioStreamBasicDescription));
            }
            
            // Set audio unit render callback.
            if (noErr == status)
            {
                AURenderCallbackStruct renderCallbackStruct;
                renderCallbackStruct.inputProc = AU_RenderCallback;
                renderCallbackStruct.inputProcRefCon = (void *)tap;
                status = AudioUnitSetProperty(audioVerb, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
            }
            
            // Set audio unit maximum frames per slice to max frames.
            if (noErr == status)
            {
                UInt32 maximumFramesPerSlice = maxFrames;
                status = AudioUnitSetProperty(audioVerb, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
            }
            
            // Initialize audio unit.
            if (noErr == status)
            {
                status = AudioUnitInitialize(audioVerb);
            }
            
            if (noErr != status)
            {
                AudioComponentInstanceDispose(audioVerb);
                audioVerb = NULL;
            }
            
            context->audioVerb = audioVerb;
            
            if(audioVerb)
            {
                AudioUnitSetParameter(audioVerb,
                                      kReverb2Param_DryWetMix,
                                      kAudioUnitScope_Global,
                                      0,
                                      0,
                                      0);
            }
        }
    }

}

static void tap_UnprepareCallback(MTAudioProcessingTapRef tap)
{
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	
	/* Release bandpass filter Audio Unit */
    
	if (context->audioUnit)
	{
		AudioUnitUninitialize(context->audioUnit);
		AudioComponentInstanceDispose(context->audioUnit);
		context->audioUnit = NULL;
        context->self = NULL;
	}
}

static void tap_ProcessCallback(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut)
{
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	
	OSStatus status;
	
	// Skip processing when format not supported.
	if (!context->supportedTapProcessingFormat)
	{
		NSLog(@"Unsupported tap processing format.");
		return;
	}
    
    if(!context)
    {
        NSLog(@"%@", context->self);
        
        return;
    }
	
	MYAudioTapProcessor * yo = ((__bridge MYAudioTapProcessor *)context->self);
    
	if (yo.isBandpassFilterEnabled)
	{
		// Apply bandpass filter Audio Unit.
		AudioUnit audioUnit = context->audioUnit;
		if (audioUnit)
		{
			AudioTimeStamp audioTimeStamp;
			audioTimeStamp.mSampleTime = context->sampleCount;
			audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
			
            
            AudioBufferList *bufferList;
            bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer));
            bufferList->mNumberBuffers = 0;
            bufferList->mBuffers[0].mNumberChannels = 1;
            bufferList->mBuffers[0].mDataByteSize = 1024 * 2;
            bufferList->mBuffers[0].mData = calloc(1024, 2);
            
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
	else if(yo.isReverbFilterEnabled)
	{
        AudioUnit audioVerb = context->audioVerb;
        if (audioVerb)
        {
            AudioTimeStamp audioTimeStamp;
            audioTimeStamp.mSampleTime = context->sampleCount;
            audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
            
            
            AudioBufferList *bufferList;
            bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer));
            bufferList->mNumberBuffers = 0;
            bufferList->mBuffers[0].mNumberChannels = 1;
            bufferList->mBuffers[0].mDataByteSize = 1024 * 2;
            bufferList->mBuffers[0].mData = calloc(1024, 2);
            
            status = AudioUnitRender(audioVerb, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
            
            if (noErr != status)
            {
                NSLog(@"AudioUnitRender(): %d", (int)status);
                return;
            }
            
            // Increment sample count for audio unit.
            context->sampleCount += numberFrames ;
            
            // Set number of frames out.
            *numberFramesOut = numberFrames;
        }
    }
    else
    {
        // Get actual audio buffers from MTAudioProcessingTap (AudioUnitRender() will fill bufferListInOut otherwise).
        status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);
        if (noErr != status)
        {
            NSLog(@"MTAudioProcessingTapGetSourceAudio: %d", (int)status);
            return;
        }
    }
	
	// Calculate root mean square (RMS) for left and right audio channel.
//	for (UInt32 i = 0; i < bufferListInOut->mNumberBuffers; i++)
//	{
//		AudioBuffer *pBuffer = &bufferListInOut->mBuffers[i];
//		UInt32 cSamples = numberFrames * (context->isNonInterleaved ? 1 : pBuffer->mNumberChannels);
//        
//		float *pData = (float *)pBuffer->mData;
//		
//		float rms = 0.0f;
//		for (UInt32 j = 0; j < cSamples; j++)
//		{
//			rms += pData[j] * pData[j];
//		}
//		if (cSamples > 0)
//		{
//			rms = sqrtf(rms / cSamples);
//		}
//		
//		if (0 == i)
//		{
//			context->leftChannelVolume = rms;
//		}
//		if (1 == i || (0 == i && 1 == bufferListInOut->mNumberBuffers))
//		{
//			context->rightChannelVolume = rms;
//		}
//	}
	
	// Pass calculated left and right channel volume to VU meters.
//	[self updateLeftChannelVolume:context->leftChannelVolume rightChannelVolume:context->rightChannelVolume];
}

#pragma mark - Audio Unit Callbacks

OSStatus AU_RenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
	return MTAudioProcessingTapGetSourceAudio(inRefCon, inNumberFrames, ioData, NULL, NULL, NULL);
}
