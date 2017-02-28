/*
     File: MYAudioTapProcessor.h
 Abstract: Audio tap processor using MTAudioProcessingTap for audio visualization and processing.
  Version: 1.0.1
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

@class AVAudioMix;

@class AVAssetTrack;

@protocol MYAudioTabProcessorDelegate;

@interface MYAudioTapProcessor : NSObject
{

}

+ (MYAudioTapProcessor*)shareInstance;

- (void)releaseMix;

- (void)withAssetTrack:(AVAssetTrack *)audioAssetTrack;

- (id)initWithAudioAssetTrack:(AVAssetTrack *)audioAssetTrack;

- (void)setGain:(AudioUnitParameterValue)gain forBandAtPosition:(NSUInteger)bandPosition;

- (void)setReverb:(AudioUnitParameterValue)gain;

@property (readonly, nonatomic) AVAssetTrack *audioAssetTrack;
@property (readonly, nonatomic) AVAudioMix *audioMix;
@property (weak, nonatomic) id <MYAudioTabProcessorDelegate> delegate;
@property (nonatomic, getter = isBandpassFilterEnabled) BOOL enableBandpassFilter;
@property (nonatomic, getter = isReverbFilterEnabled) BOOL enableReverbFilter;

@property (nonatomic) float centerFrequency; // [0 .. 1]
@property (nonatomic) float bandwidth; // [0 .. 1]

@end

#pragma mark - Protocols

@protocol MYAudioTabProcessorDelegate <NSObject>

- (void)audioTabProcessor:(MYAudioTapProcessor *)audioTabProcessor hasNewLeftChannelValue:(float)leftChannelValue rightChannelValue:(float)rightChannelValue;

@end
