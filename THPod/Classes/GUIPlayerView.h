//
//  GUIPlayerView.h
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 08/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

#import <MediaPlayer/MediaPlayer.h>

#import "GUISlider.h"

#import "UIView+UpdateAutoLayoutConstraints.h"

typedef enum __actionState
{
    didPause,//
    didResume,//
    didEndPlaying,//
    willEnterFullscreen,//
    willLeaveFullscreen,//
    didEnterFullscreen,//
    didLeaveFullscreen,//
    didStop,//
}ActionState;

typedef enum __eventState
{
    readyToPlay,//
    failedToPlayToEnd,//
    stalled,//
    error,//
    customAction,//
    ticking,//
}EventState;

@class TimeAll;

@interface TimeAll : NSTimer
{
    
}

+ (TimeAll*)shareIn;

- (void)cleanTime;

@property(nonatomic,weak) NSTimer * timer;


@end


@class GUIPlayerView;

typedef void (^PlayerAction)(ActionState actionState, NSDictionary * actionInfo);

typedef void (^PlayerEvent)(EventState eventState,NSDictionary * eventInfo);

@protocol GUIPlayerViewDelegate <NSObject>

@optional
- (void)playerDidPause;
- (void)playerDidResume;
- (void)playerDidEndPlaying;
- (void)playerWillEnterFullscreen;
- (void)playerDidEnterFullscreen;
- (void)playerWillLeaveFullscreen;
- (void)playerDidLeaveFullscreen;

- (void)playerReadyToPlay;
- (void)playerFailedToPlayToEnd;
- (void)playerStalled;
- (void)playerError;
- (void)playerDidPressSelector:(NSDictionary*)dict;
- (void)playerTicking:(NSDictionary*)dict;

@end

@interface GUIPlayerView : UIView

@property (strong, nonatomic) NSURL *videoURL;
@property (assign, nonatomic) NSInteger controllersTimeoutPeriod;
@property (weak, nonatomic) id<GUIPlayerViewDelegate> delegate;
@property (strong, nonatomic) UIButton * retryButton;
@property (strong, nonatomic) NSMutableDictionary * options;
@property (strong, nonatomic) UIButton *playButton;
@property (assign, nonatomic) BOOL fullscreen, isRight;
@property (strong, nonatomic) UIButton *fullscreenButton;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *currentItem;
@property (nonatomic, copy) PlayerAction onAction;
@property (nonatomic, copy) PlayerEvent onEvent;
@property (strong, nonatomic) UIView *controlView;

- (instancetype)initWithInfo:(NSDictionary*)info;

- (GUIPlayerView*)andEventCompletion:(PlayerEvent)eventCompletion andActionCompletion:(PlayerAction)actionCompletion;

- (instancetype)initWithFrame:(CGRect)frame andInfo:(NSMutableDictionary*)info;

- (void)prepareAndPlayAutomatically:(BOOL)playAutomatically;

- (void)clean;

- (void)play;

- (void)resume;

- (void)pause;

- (void)stop;

- (NSTimeInterval)availableDuration;

- (BOOL)isPlaying;

- (void)setTintColor:(UIColor *)tintColor;

- (void)setBufferTintColor:(UIColor *)tintColor;

- (void)setLiveStreamText:(NSString *)text;

- (void)setAirPlayText:(NSString *)text;

- (void)togglePlay:(UIButton *)button;

- (void)toggleFullscreen:(UIButton *)button;

- (void)hideControllers;

- (void)showControllers;

- (void)seekTo:(float)value;

- (void)pauseRefreshing;

- (void)resumeRefreshing;

- (void)setVolume:(float)value;

- (float)getVolume;

- (void)turnOnEQ:(BOOL)isOn;

- (void)turnOnReverb:(BOOL)isOn;

- (void)turnOffAll;

- (void)adjustEQ:(float)value andPosition:(int)position;

- (void)adjustReverb:(float)value;

@end
