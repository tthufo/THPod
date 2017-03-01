//
//  GUIPlayerView.m
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 08/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import "GUIPlayerView.h"

#import "MYAudioTapProcessor.h"

#import "NSObject+Category.h"

@class TimeAll;

static TimeAll * shareTime = nil;

@interface TimeAll ()
{

}

@end

@implementation TimeAll

@synthesize timer;

+ (TimeAll*)shareIn
{
    if(!shareTime)
    {
        shareTime = [TimeAll new];
    }
    
    return shareTime;
}

- (void)cleanTime
{
    if(timer)
    {
        [timer invalidate];
        
        timer = nil;
    }
}

@end

@interface GUIPlayerView () <MYAudioTabProcessorDelegate, AVAssetResourceLoaderDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@property (strong, nonatomic) UIView *controllersView, *topView;
@property (strong, nonatomic) UIImageView* coverView;
@property (strong, nonatomic) UILabel *airPlayLabel;

@property (strong, nonatomic) MPVolumeView *volumeView;
@property (strong, nonatomic) GUISlider *progressIndicator;
@property (strong, nonatomic) UILabel *currentTimeLabel;
@property (strong, nonatomic) UILabel *remainingTimeLabel;
@property (strong, nonatomic) UILabel *liveLabel;

@property (strong, nonatomic) UIView *spacerView;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
//@property (strong, nonatomic) NSTimer *progressTimer;
@property (strong, nonatomic) NSTimer *controllersTimer;
@property (assign, nonatomic) BOOL seeking;
@property (assign, nonatomic) CGRect defaultFrame;
@property (strong, nonatomic) MYAudioTapProcessor *audioTapProcessor;

@end

@implementation GUIPlayerView

@synthesize player, playerLayer, currentItem, controlView;
@synthesize controllersView, airPlayLabel;
@synthesize playButton, fullscreenButton, volumeView, progressIndicator, currentTimeLabel, remainingTimeLabel, liveLabel, spacerView;
@synthesize activityIndicator, controllersTimer, seeking, fullscreen, defaultFrame;
@synthesize retryButton, topView, options, coverView;
@synthesize videoURL, controllersTimeoutPeriod, delegate, isRight;
@synthesize audioTapProcessor = _audioTapProcessor;
@synthesize onEvent, onAction;

#pragma mark - View Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    defaultFrame = frame;
    [self setup];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self setup];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame andInfo:(NSMutableDictionary*)info {
    self = [super initWithFrame:frame];
    defaultFrame = frame;
    options = info;
    [self setup];
    return self;
}

- (instancetype)initWithInfo:(NSDictionary*)info
{
    self = [super initWithFrame:[info[@"rect"] CGRectValue]];
    options = info;
    [self setup];
    return self;
}

- (GUIPlayerView*)andEventCompletion:(PlayerEvent)eventCompletion andActionCompletion:(PlayerAction)actionCompletion
{
    self.onAction = actionCompletion;
    
    self.onEvent = eventCompletion;
    
    return self;
}

#pragma mark EQ

- (MYAudioTapProcessor *)audioTapProcessor
{
    AVAssetTrack *firstAudioAssetTrack;
    
    for (AVAssetTrack *assetTrack in self.player.currentItem.asset.tracks)
    {
        if ([assetTrack.mediaType isEqualToString:AVMediaTypeAudio])
        {
            firstAudioAssetTrack = assetTrack;
            break;
        }
    }
    if (firstAudioAssetTrack)
    {
        _audioTapProcessor = [MYAudioTapProcessor shareInstance];
        
        [_audioTapProcessor withAssetTrack:firstAudioAssetTrack];
        
        _audioTapProcessor.delegate = self;
    }

    return _audioTapProcessor;
}

- (void)audioTabProcessor:(MYAudioTapProcessor *)audioTabProcessor hasNewLeftChannelValue:(float)leftChannelValue rightChannelValue:(float)rightChannelValue
{
    
}

- (void)turnOnEQ:(BOOL)isOn
{
    self.audioTapProcessor.enableBandpassFilter = isOn;
    
    self.audioTapProcessor.enableReverbFilter = !isOn;
}

- (void)turnOnReverb:(BOOL)isOn
{
    self.audioTapProcessor.enableReverbFilter = isOn;
    
    self.audioTapProcessor.enableBandpassFilter = !isOn;
}

- (void)turnOffAll
{
    self.audioTapProcessor.enableBandpassFilter = NO;
    
    self.audioTapProcessor.enableReverbFilter = NO;
}

- (void)adjustReverb:(float)value
{
    [[self audioTapProcessor] setReverb:value];
}

- (void)adjustEQ:(float)value andPosition:(int)position
{
    [[self audioTapProcessor] setGain:value forBandAtPosition:position];
}

#pragma End

- (void)setup {
    // Set up notification observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFailedToPlayToEnd:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStalled:)
                                                 name:AVPlayerItemPlaybackStalledNotification object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airPlayAvailabilityChanged:)
//                                                 name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airPlayActivityChanged:)
                                                 name:MPVolumeViewWirelessRouteActiveDidChangeNotification object:nil];
    
    [self setBackgroundColor:[UIColor blackColor]];
    
    NSArray *horizontalConstraints;
    NSArray *verticalConstraints;
    
    /** Container View **************************************************************************************************/
    
    if(options)
    {
        coverView = [UIImageView new];
        coverView.clipsToBounds = YES;
        coverView.contentMode = UIViewContentModeScaleAspectFill;
        
        [coverView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self addSubview:coverView];
        
        horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[CC]|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:@{@"CC" : coverView}];
        
        verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[CC]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"CC" : coverView}];
        [self addConstraints:horizontalConstraints];
        [self addConstraints:verticalConstraints];
        
        coverView.image = options[@"cover"] ? options[@"cover"] : [UIImage imageNamed:@""];
        
        
        topView = [UIView new];
        [topView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.45f]];
        [topView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self addSubview:topView];
        
        topView.alpha = [options[@"default"] boolValue];
        
        horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[T(40)]" options:0 metrics:nil views:@{@"T":topView}];
        
        verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[T(80)]" options:0 metrics:nil views:@{@"T":topView}];

        [self addConstraints:horizontalConstraints];
        [self addConstraints:verticalConstraints];
        
        
        UIButton * repeat = [UIButton buttonWithType:UIButtonTypeCustom];
        [repeat setTranslatesAutoresizingMaskIntoConstraints:NO];
        [repeat setImage:[UIImage imageNamed:[options[@"repeat"] isEqualToString:@"0"] ? @"none" : [options[@"repeat"] isEqualToString:@"1"] ? @"one" : @"all"] forState:UIControlStateNormal];
        
        [topView addSubview:repeat];
        
        
        UIButton * shuffle = [UIButton buttonWithType:UIButtonTypeCustom];
        [shuffle setTranslatesAutoresizingMaskIntoConstraints:NO];
        [shuffle setImage:[UIImage imageNamed:[options[@"shuffle"] isEqualToString:@"0"] ? @"shuffle_ac" : @"shuffle_in"] forState:UIControlStateNormal];
        
        [topView addSubview:shuffle];
        
        verticalConstraints = [NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|[RP(40)][SS(40)]|"
                               options:0
                               metrics:nil
                               views:@{@"RP" : repeat,@"SS": shuffle}];
        
        horizontalConstraints = [NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|[RP(40)][SS(40)]|"
                                 options:0
                                 metrics:nil
                                 views:@{@"RP" : repeat,@"SS": shuffle}];
        
        [topView addConstraints:verticalConstraints];
        
        [topView addConstraints:horizontalConstraints];
        
        [repeat addTarget:self action:@selector(didPressRepeat:) forControlEvents:UIControlEventTouchUpInside];
        
        [shuffle addTarget:self action:@selector(didPressShuffle:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if([options responseForKey:@"xib"])
    {
        controlView = [[NSBundle mainBundle] loadNibNamed:options[@"xib"] owner:self options:nil][0];
        
        controlView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        [self addSubview:controlView];
        
        [[self elementWithTag:11] setImage:[UIImage imageNamed:options[@"playpause"][0]] forState:UIControlStateNormal];
        
        [[self elementWithTag:11] setImage:[UIImage imageNamed:options[@"playpause"][1]] forState:UIControlStateSelected];
        
        [[self elementWithTag:11] addTarget:self action:@selector(togglePlay:) forControlEvents:UIControlEventTouchUpInside];
        
        [[self elementWithTag:1] setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.45f]];
        
        [self setSelector];
    }
    
    controllersView = [UIView new];
    [controllersView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [controllersView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.45f]];
    
    [self addSubview:controllersView];
    
    horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[CV]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"CV" : controllersView}];
    
    verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[CV(40)]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{@"CV" : controllersView}];
    [self addConstraints:horizontalConstraints];
    [self addConstraints:verticalConstraints];
    
    /** AirPlay View ****************************************************************************************************/
    
    airPlayLabel = [UILabel new];
    [airPlayLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [airPlayLabel setText:@"AirPlay is enabled"];
    [airPlayLabel setTextColor:[UIColor lightGrayColor]];
    [airPlayLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [airPlayLabel setTextAlignment:NSTextAlignmentCenter];
    [airPlayLabel setNumberOfLines:0];
    [airPlayLabel setHidden:YES];
    [self addSubview:airPlayLabel];
    
    horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[AP]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"AP" : airPlayLabel}];
    
    verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[AP]-40-|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{@"AP" : airPlayLabel}];
    [self addConstraints:horizontalConstraints];
    [self addConstraints:verticalConstraints];
    
    /** UI Controllers **************************************************************************************************/
    
    playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [playButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [playButton setImage:[UIImage imageNamed:@"gui_play"] forState:UIControlStateNormal];
    [playButton setImage:[UIImage imageNamed:@"gui_pause"] forState:UIControlStateSelected];
    
    volumeView = [MPVolumeView new];
    [volumeView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [volumeView setShowsRouteButton:YES];
    [volumeView setShowsVolumeSlider:NO];
    [volumeView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    fullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [fullscreenButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [fullscreenButton setImage:[UIImage imageNamed:@"gui_expand"] forState:UIControlStateNormal];
    [fullscreenButton setImage:[UIImage imageNamed:@"gui_shrink"] forState:UIControlStateSelected];
    
    currentTimeLabel = [UILabel new];
    [currentTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [currentTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [currentTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [currentTimeLabel setTextColor:[UIColor whiteColor]];
    
    remainingTimeLabel = [UILabel new];
    [remainingTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [remainingTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [remainingTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [remainingTimeLabel setTextColor:[UIColor whiteColor]];
    
    progressIndicator = [GUISlider new];
    [progressIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    progressIndicator.thickNess = @(0);
    [progressIndicator setContinuous:YES];
    progressIndicator.userInteractionEnabled = NO;
    
    liveLabel = [UILabel new];
    [liveLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [liveLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [liveLabel setTextAlignment:NSTextAlignmentCenter];
    [liveLabel setTextColor:[UIColor whiteColor]];
    [liveLabel setText:@"Try again"];
    [liveLabel setHidden:YES];
    
    
    spacerView = [UIView new];
    [spacerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    if([options[@"default"] boolValue])
    {
        [controllersView addSubview:playButton];
    }
    
    [controllersView addSubview:fullscreenButton];
    [controllersView addSubview:volumeView];
    [controllersView addSubview:currentTimeLabel];
    [controllersView addSubview:progressIndicator];
    [controllersView addSubview:remainingTimeLabel];
    [controllersView addSubview:liveLabel];
    [controllersView addSubview:spacerView];
    
    
    if(![options[@"default"] boolValue])
    {
        horizontalConstraints = [NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|-5-[S(10)][C]-5-[I]-5-[R][F(40)][V(40)]|"
                                 options:0
                                 metrics:nil
                                 views:@{
                                         @"S" : spacerView,
                                         @"C" : currentTimeLabel,
                                         @"I" : progressIndicator,
                                         @"R" : remainingTimeLabel,
                                         @"V" : volumeView,
                                         @"F" : fullscreenButton}];
    }
    else
    {
        horizontalConstraints = [NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|[P(40)][S(10)][C]-5-[I]-5-[R][F(40)][V(40)]|"
                                 options:0
                                 metrics:nil
                                 views:@{@"P" : playButton,
                                         @"S" : spacerView,
                                         @"C" : currentTimeLabel,
                                         @"I" : progressIndicator,
                                         @"R" : remainingTimeLabel,
                                         @"V" : volumeView,
                                         @"F" : fullscreenButton}];
    }
    
    [controllersView addConstraints:horizontalConstraints];
    
    [volumeView hideByWidth:YES];
    [spacerView hideByWidth:YES];
    
    horizontalConstraints = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|-5-[L]-5-|"
                             options:0
                             metrics:nil
                             views:@{@"L" : liveLabel}];
    
    [controllersView addConstraints:horizontalConstraints];
    
    for (UIView *view in [controllersView subviews]) {
        verticalConstraints = [NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-0-[V(40)]"
                               options:NSLayoutFormatAlignAllCenterY
                               metrics:nil
                               views:@{@"V" : view}];
        [controllersView addConstraints:verticalConstraints];
    }
    
    /** Loading Indicator ***********************************************************************************************/
    
    activityIndicator = [UIActivityIndicatorView new];
    
    [activityIndicator stopAnimating];
    
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    [activityIndicator setFrame:frame];
    
    [self addSubview:activityIndicator];
    
    /** Actions Setup ***************************************************************************************************/
    
    [playButton addTarget:self action:@selector(togglePlay:) forControlEvents:UIControlEventTouchUpInside];
    [fullscreenButton addTarget:self action:@selector(toggleFullscreen:) forControlEvents:UIControlEventTouchUpInside];
    
    [progressIndicator addTarget:self action:@selector(seek:) forControlEvents:UIControlEventValueChanged];
    [progressIndicator addTarget:self action:@selector(pauseRefreshing) forControlEvents:UIControlEventTouchDown];
    [progressIndicator addTarget:self action:@selector(resumeRefreshing) forControlEvents:UIControlEventTouchUpInside|
     UIControlEventTouchUpOutside | UIControlEventTouchDragInside | UIControlEventTouchDragOutside];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControllers)]];
    
    ///////// new added
    
    if(options[@"currentTime"])
    {
        [(UILabel*)options[@"currentTime"] setText:@""];
    }
    
    if(options[@"remainTime"])
    {
        [(UILabel*)options[@"remainTime"] setText:@""];
    }
    
    if(options[@"thumb"])
    {
        [progressIndicator setThumbImage:options[@"thumb"] forState:UIControlStateNormal];
        
        [progressIndicator setThumbImage:options[@"thumb"] forState:UIControlStateHighlighted];
    }
    
    if(options[@"slider"])
    {
        [options[@"slider"] addTarget:self action:@selector(seek:) forControlEvents:UIControlEventValueChanged];
        [options[@"slider"] addTarget:self action:@selector(pauseRefreshing) forControlEvents:UIControlEventTouchDown];
        [options[@"slider"] addTarget:self action:@selector(resumeRefreshing) forControlEvents:UIControlEventTouchUpInside|
         UIControlEventTouchUpOutside | UIControlEventTouchDragInside | UIControlEventTouchDragOutside];
    }
    
    if(options[@"multi"])
    {
        for(NSDictionary * dict in options[@"multi"])
        {
            [dict[@"slider"] addTarget:self action:@selector(seek:) forControlEvents:UIControlEventValueChanged];
            [dict[@"slider"] addTarget:self action:@selector(pauseRefreshing) forControlEvents:UIControlEventTouchDown];
            [dict[@"slider"] addTarget:self action:@selector(resumeRefreshing) forControlEvents:UIControlEventTouchUpInside|
             UIControlEventTouchUpOutside | UIControlEventTouchDragInside | UIControlEventTouchDragOutside];
            
            if(dict[@"currentTime"])
            {
                [(UILabel*)dict[@"currentTime"] setText:@""];
            }
            
            if(dict[@"remainTime"])
            {
                [(UILabel*)dict[@"remainTime"] setText:@""];
            }
        }
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        [controlView setAlpha:1.0f];
        [controllersView setAlpha:1.0f];
        [topView setAlpha:[options[@"default"] boolValue]];
    } completion:^(BOOL finished) {
        [controllersTimer invalidate];
        
        if (controllersTimeoutPeriod > 0) {
            controllersTimer = [NSTimer scheduledTimerWithTimeInterval:controllersTimeoutPeriod
                                                                target:self
                                                              selector:@selector(hideControllers)
                                                              userInfo:nil
                                                               repeats:NO];
        }
    }];
    
    controllersTimeoutPeriod = 3;
}

- (void)setSelector
{
    for(UIView * v in ((UIView*)[self elementWithTag:1]).subviews)
    {
        if([v isKindOfClass:[UIButton class]])
        {
            [(UIButton*)v addTarget:self action:@selector(didPressObject:) forControlEvents:UIControlEventTouchUpInside];
            
            if([options responseForKey:@"init"])
            {
                for(NSString * tagNo in ((NSDictionary*)options[@"init"]).allKeys)
                {
                    if([[NSString stringWithFormat:@"%i", v.tag] isEqualToString: tagNo])
                    {
                        [(UIButton*)v setImage:[UIImage imageNamed:options[@"init"][tagNo]] forState:UIControlStateNormal];
                        
                        break;
                    }
                }
            }
        }
    }
}

- (void)didPressObject:(UIButton*)object
{
    if ([delegate respondsToSelector:@selector(playerDidPressSelector:)])
    {
        [delegate playerDidPressSelector:@{@"object":object}];
    }
    else
    {
        if(self.onEvent)
        {
            self.onEvent(4, @{@"object":object});
        }
    }
}

- (id)elementWithTag:(int)tag
{
    return [self withView:controlView tag:tag];
}

#pragma mark - UI Customization

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    
    [progressIndicator setTintColor:tintColor];
}

- (void)setBufferTintColor:(UIColor *)tintColor {
    [progressIndicator setSecondaryTintColor:tintColor];
}

- (void)setLiveStreamText:(NSString *)text {
    [liveLabel setText:text];
}

- (void)setAirPlayText:(NSString *)text {
    [airPlayLabel setText:text];
}

#pragma mark - Actions

- (void)didPressRepeat:(UIButton*)sender
{
    if(options)
    {
        int option = [options[@"repeat"] intValue] == 0 ? 1 : [options[@"repeat"] intValue] == 1 ? 2 : 0 ;
        options[@"repeat"] = [NSString stringWithFormat:@"%i", option];
        [sender setImage:[UIImage imageNamed:[options[@"repeat"] isEqualToString:@"0"] ? @"none" : [options[@"repeat"] isEqualToString:@"1"] ? @"one" : @"all"] forState:UIControlStateNormal];
    }
}

- (void)didPressShuffle:(UIButton*)sender
{
    if(options)
    {
        int option = [options[@"shuffle"] intValue] == 0 ? 1 : 0;
        options[@"shuffle"] = [NSString stringWithFormat:@"%i", option];
        [sender setImage:[UIImage imageNamed:[options[@"shuffle"] isEqualToString:@"0"] ? @"shuffle_ac" : @"shuffle_in"] forState:UIControlStateNormal];
    }
}

- (void)togglePlay:(UIButton *)button {
    if ([button isSelected]) {
        [button setSelected:NO];
        [player pause];
        
        if ([delegate respondsToSelector:@selector(playerDidPause)])
        {
            [delegate playerDidPause];
        }
        else
        {
            if(self.onAction)
            {
                self.onAction(0, @{});
            }
        }
    } else {
        [button setSelected:YES];
        
        [self play];
        
        if ([delegate respondsToSelector:@selector(playerDidResume)])
        {
            [delegate playerDidResume];
        }
        else
        {
            if(self.onAction)
            {
                self.onAction(1, @{});
            }
        }
    }
    
    [self showControllers];
}

- (void)toggleFullscreen:(UIButton *)button {
    if (fullscreen) {
        if ([delegate respondsToSelector:@selector(playerWillLeaveFullscreen)])
        {
            [delegate playerWillLeaveFullscreen];
        }
        else
        {
            if(self.onAction)
            {
                self.onAction(4, @{});
            }
        }
        
        [UIView animateWithDuration:0.2f animations:^{
            [self setTransform:CGAffineTransformMakeRotation(0)];
            [self setFrame:defaultFrame];
            
            CGRect frame = defaultFrame;
            frame.origin = CGPointZero;
            [playerLayer setFrame:frame];
            [activityIndicator setFrame:frame];
        } completion:^(BOOL finished) {
            fullscreen = NO;
            
            if ([delegate respondsToSelector:@selector(playerDidLeaveFullscreen)])
            {
                [delegate playerDidLeaveFullscreen];
            }
            else
            {
                if(self.onAction)
                {
                    self.onAction(6, @{});
                }
            }
        }];
        
        [button setSelected:NO];
    } else {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = [[UIScreen mainScreen] bounds].size.height;
        CGRect frame;
        
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            CGFloat aux = width;
            width = height;
            height = aux;
            frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
        }
        else
        {
            frame = CGRectMake(0, 0, width, height);
        }
        
        if ([delegate respondsToSelector:@selector(playerWillEnterFullscreen)])
        {
            [delegate playerWillEnterFullscreen];
        }
        else
        {
            if(self.onAction)
            {
                self.onAction(3, @{});
            }
        }
        [UIView animateWithDuration:0.2f animations:^{
            [self setFrame:frame];
            [playerLayer setFrame:CGRectMake(0, 0, width, height)];
            
            [activityIndicator setFrame:CGRectMake(0, 0, width, height)];
            if (UIInterfaceOrientationIsPortrait(orientation)) {
                [self setTransform:CGAffineTransformMakeRotation(M_PI_2 * (isRight ? -1 : 1))];
                [activityIndicator setTransform:CGAffineTransformMakeRotation(-M_PI_2 * (isRight ? -1 : 1))];
            }
            
        } completion:^(BOOL finished) {
            fullscreen = YES;
            
            if ([delegate respondsToSelector:@selector(playerDidEnterFullscreen)])
            {
                [delegate playerDidEnterFullscreen];
            }
            else
            {
                if(self.onAction)
                {
                    self.onAction(5, @{});
                }
            }
        }];
        
        [button setSelected:YES];
    }
    
    [self showControllers];
}

- (void)seekTo:(float)value
{
    int timescale = currentItem.asset.duration.timescale;
    float time = value * (currentItem.asset.duration.value / timescale);
    [player seekToTime:CMTimeMakeWithSeconds(time, timescale)];
}

- (void)seek:(UISlider *)slider
{
    int timescale = currentItem.asset.duration.timescale;
    float time = slider.value * (currentItem.asset.duration.value / timescale);
    
    [player seekToTime:CMTimeMakeWithSeconds(time, timescale)];
    
    [UIView animateWithDuration:0.2f animations:^{
        [controlView setAlpha:1.0f];
        [controllersView setAlpha:1.0f];
        [topView setAlpha:[options[@"default"] boolValue]];
    } completion:^(BOOL finished) {
        [controllersTimer invalidate];
        
        if (controllersTimeoutPeriod > 0) {
            controllersTimer = [NSTimer scheduledTimerWithTimeInterval:controllersTimeoutPeriod
                                                                target:self
                                                              selector:@selector(hideControllers)
                                                              userInfo:nil
                                                               repeats:NO];
        }
    }];
}

- (void)pauseRefreshing
{
    seeking = YES;
    
    [[TimeAll shareIn] cleanTime];
}

- (void)resumeRefreshing
{
    seeking = NO;
    
    [[TimeAll shareIn] cleanTime];
    
    [TimeAll shareIn].timer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                               target:self
                                                             selector:@selector(refreshProgressIndicator)
                                                             userInfo:nil
                                                              repeats:YES];
}

- (NSTimeInterval)availableDuration
{
    NSTimeInterval result = 0;
    NSArray *loadedTimeRanges = player.currentItem.loadedTimeRanges;
    
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        result = startSeconds + durationSeconds;
    }
    
    return result;
}

- (void)refreshProgressIndicator
{
    CGFloat duration = CMTimeGetSeconds(currentItem.asset.duration);
    
    if (duration == 0 || isnan(duration)) {
        // Video is a live stream
        [currentTimeLabel setText:nil];
        [remainingTimeLabel setText:nil];
        [progressIndicator setHidden:NO];
        [progressIndicator setEnabled:NO];
        [playButton setSelected:NO];
        [[self elementWithTag:11] setSelected:NO];
        
        if(fullscreen)
        {
            [self toggleFullscreen:nil];
        }
        
        [self hideControllers];
        
        if ([delegate respondsToSelector:@selector(playerError)])
        {
            [delegate playerError];
        }
        else
        {
            if(self.onEvent)
            {
                self.onEvent(3, @{});
            }
        }
        
        [[TimeAll shareIn] cleanTime];
    }
    
    else {
        CGFloat current = seeking ?
        progressIndicator.value * duration :         // If seeking, reflects the position of the slider
        CMTimeGetSeconds(player.currentTime); // Otherwise, use the actual video position
        
        [progressIndicator setValue:(current / duration)];
        [progressIndicator setSecondaryValue:([self availableDuration] / duration)];
                
        if(options[@"slider"])
        {
            CGFloat current = seeking ?
            
            ((GUISlider*)options[@"slider"]).value * duration : CMTimeGetSeconds(player.currentTime);
            
            [((GUISlider*)options[@"slider"]) setValue:(current / duration)];
            
            if([options[@"slider"] isKindOfClass:[GUISlider class]])
            {
                [((GUISlider*)options[@"slider"]) setSecondaryValue:([self availableDuration] / duration)];
            }
        }
        
        if(options[@"currentTime"])
        {
            [(UILabel*)options[@"currentTime"] setText:[self duration:current]];
        }
        
        if(options[@"remainTime"])
        {
            [(UILabel*)options[@"remainTime"] setText:[NSString stringWithFormat:@"-%@", [self duration:duration - current]]];
        }
        
        [currentTimeLabel setText:[self duration:current]];
        [remainingTimeLabel setText:[NSString stringWithFormat:@"-%@", [self duration:duration - current]]];
        
        if(options[@"multi"])
        {
            for(NSDictionary * dict in options[@"multi"])
            {
                CGFloat current = seeking ?
                
                ((GUISlider*)dict[@"slider"]).value * duration : CMTimeGetSeconds(player.currentTime);
                
                [((GUISlider*)dict[@"slider"]) setValue:(current / duration)];
                
                if([options[@"slider"] isKindOfClass:[GUISlider class]])
                {
                    [((GUISlider*)dict[@"slider"]) setSecondaryValue:([self availableDuration] / duration)];
                }
                
                if(dict[@"currentTime"])
                {
                    [(UILabel*)dict[@"currentTime"] setText:[self duration:current]];
                }
                
                if(dict[@"remainTime"])
                {
                    [(UILabel*)dict[@"remainTime"] setText:[NSString stringWithFormat:@"-%@", [self duration:duration - current]]];
                }
            }
        }

        if ([delegate respondsToSelector:@selector(playerTicking:)] && !seeking)
        {
            [delegate playerTicking:@{@"value":@(progressIndicator.value)}];
        }
        else
        {
            if(self.onEvent && !seeking)
            {
                self.onEvent(5, @{@"value":@(progressIndicator.value)});
            }
        }
        
        [progressIndicator setHidden:NO];
    }
}

- (void)showControllers {
    
    if(controllersView.alpha == 1)
    {
        [self hideControllers];
        
        return;
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        [controlView setAlpha:1.0f];
        [controllersView setAlpha:1.0f];
        [topView setAlpha:[options[@"default"] boolValue]];
    } completion:^(BOOL finished) {
        [controllersTimer invalidate];
        
        if (controllersTimeoutPeriod > 0) {
            controllersTimer = [NSTimer scheduledTimerWithTimeInterval:controllersTimeoutPeriod
                                                                target:self
                                                              selector:@selector(hideControllers)
                                                              userInfo:nil
                                                               repeats:NO];
        }
    }];
}

- (void)hideControllers {
    [UIView animateWithDuration:0.5f animations:^{
        [controlView setAlpha:0.0f];
        [controllersView setAlpha:0.0f];
        [topView setAlpha:0.0f];
    }];
}

#pragma mark - Public Methods

- (void)prepareAndPlayAutomatically:(BOOL)playAutomatically
{
    if(player)
    {
       [self end];
    }
    
    player = [[AVPlayer alloc] initWithPlayerItem:nil];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSArray *keys = [NSArray arrayWithObject:@"playable"];
    
    __weak typeof(self) weakSelf = self;
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        weakSelf.currentItem = [AVPlayerItem playerItemWithAsset:asset];
        [weakSelf.player replaceCurrentItemWithPlayerItem:weakSelf.currentItem];
        
        if (playAutomatically) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [weakSelf play];
            });
        }
    }];
    
    [player setAllowsExternalPlayback:YES];
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.layer addSublayer:playerLayer];
    defaultFrame = self.frame;
    
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    [playerLayer setFrame:frame];
    
    [self bringSubviewToFront:controlView];
    [self bringSubviewToFront:controllersView];
    [self bringSubviewToFront:topView];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    @try {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    
    @try {
        
        [audioSession setMode:AVAudioSessionModeVideoRecording error:nil];
        
    } @catch (NSException *exception) {
        
    } @finally {
        
    }

    [player addObserver:self forKeyPath:@"rate" options:0 context:nil];
    [currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    [player seekToTime:kCMTimeZero];
    [player setRate:0.0f];
    [playButton setSelected:YES];
    [[self elementWithTag:11] setSelected:YES];
    
    if (playAutomatically) {
        [activityIndicator startAnimating];
    }
}

- (void)clean
{
    if(controllersTimer)
    {
        [controllersTimer invalidate];
            
        controllersTimer = nil;
    }
    
    [[TimeAll shareIn] cleanTime];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPVolumeViewWirelessRouteActiveDidChangeNotification object:nil];
    
    [player setAllowsExternalPlayback:NO];
    [self end];
    [player removeObserver:self forKeyPath:@"rate"];
    @try
    {
        AVMutableAudioMixInputParameters *params = ((AVMutableAudioMixInputParameters*)((AVPlayerItem*)self.player.currentItem).audioMix.inputParameters[0]);
        
        MTAudioProcessingTapRef tap = params.audioTapProcessor;
        
        ((AVPlayerItem*)self.player.currentItem).audioMix = nil;
//        
//        [self.audioTapProcessor releaseMix];
//        
//        self.audioTapProcessor = nil;
//        
//        if(tap)
//        {
//            CFRelease(tap);
//        }

        [currentItem removeObserver:self forKeyPath:@"status"];
        
        currentItem = nil;
    }
    @catch(id anException)
    {
        
    }
    
    [self setPlayer:nil];
    [self.playerLayer removeFromSuperlayer];
    [self setPlayerLayer:nil];
    [self removeFromSuperview];
    options = nil;
}

- (void)resume
{
    if(!self.isPlaying)
    {
        if(self.onAction)
        {
            self.onAction(1, @{});
        }
    }
    
    [player play];
    
    [playButton setSelected:YES];
    
    [[self elementWithTag:11] setSelected:YES];
    
    [[TimeAll shareIn] cleanTime];
    
    [TimeAll shareIn].timer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                               target:self
                                                             selector:@selector(refreshProgressIndicator)
                                                             userInfo:nil
                                                              repeats:YES];
}

- (void)play
{
    if (player)
    {        
        [player play];
    }
    
    [playButton setSelected:YES];
    
    [[self elementWithTag:11] setSelected:YES];

    [[TimeAll shareIn] cleanTime];
    
    [TimeAll shareIn].timer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                     target:self
                                                   selector:@selector(refreshProgressIndicator)
                                                   userInfo:nil
                                                    repeats:YES];
}

- (void)pause
{
    [player pause];
    
    [playButton setSelected:NO];
    
    [[self elementWithTag:11] setSelected:NO];
    
    if ([delegate respondsToSelector:@selector(playerDidPause)])
    {
        [delegate playerDidPause];
    }
    else
    {
        if(self.onAction)
        {
            self.onAction(0, @{});
        }
    }
    
    [[TimeAll shareIn] cleanTime];
}

- (void)end
{
    if (player)
    {
        [player pause];
        
        [player seekToTime:kCMTimeZero];
        
        [playButton setSelected:NO];
        
        [[self elementWithTag:11] setSelected:NO];
    }
    
    [[TimeAll shareIn] cleanTime];
}

- (void)stop
{
    if (player)
    {
        [player pause];
        
        [player seekToTime:kCMTimeZero];
        
        [playButton setSelected:NO];
        
        [[self elementWithTag:11] setSelected:NO];
        
        if(self.onAction)
        {
            self.onAction(7, @{});
        }
    }
    
    [[TimeAll shareIn] cleanTime];
}

- (BOOL)isPlaying
{
    return [player rate] > 0.0f;
}

- (void)setVolume:(float)value
{
    [player setVolume:value];
}

- (float)getVolume
{
    return player.volume;
}

#pragma mark - AV Player Notifications and Observers

- (void)playerDidFinishPlaying:(NSNotification *)notification
{
    [self end];

    if (fullscreen)
    {
        [self toggleFullscreen:fullscreenButton];
    }
    
    if ([delegate respondsToSelector:@selector(playerDidEndPlaying)])
    {
        [delegate playerDidEndPlaying];
    }
    else
    {
        if(self.onAction)
        {
            self.onAction(2, @{});
        }
    }
}

- (void)playerFailedToPlayToEnd:(NSNotification *)notification
{
    [self end];
    
    if ([delegate respondsToSelector:@selector(playerFailedToPlayToEnd)])
    {
        [delegate playerFailedToPlayToEnd];
    }
    else
    {
        if(self.onEvent)
        {
            self.onEvent(1, @{});
        }
    }
}

- (void)playerStalled:(NSNotification *)notification
{
    [self togglePlay:playButton];
    
    [self togglePlay:[self elementWithTag:11]];
    
    if ([delegate respondsToSelector:@selector(playerStalled)])
    {
        [delegate playerStalled];
    }
    else
    {
        if(self.onEvent)
        {
            self.onEvent(2, @{});
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if (currentItem.status == AVPlayerItemStatusFailed) {
            if ([delegate respondsToSelector:@selector(playerFailedToPlayToEnd)])
            {
                [delegate playerFailedToPlayToEnd];
            }
            else
            {
                if(self.onEvent)
                {
                    self.onEvent(1, @{});
                }
            }
        }
        
        if (currentItem.status == AVPlayerItemStatusReadyToPlay) {
            if ([delegate respondsToSelector:@selector(playerReadyToPlay)])
            {
                [delegate playerReadyToPlay];
            }
            else
            {

            }
        }
    }
    
    if ([keyPath isEqualToString:@"rate"])
    {
        CGFloat rate = [player rate];
        if (rate > 0)
        {
            [activityIndicator stopAnimating];
            
            progressIndicator.userInteractionEnabled = YES;
            
            if ([delegate respondsToSelector:@selector(playerReadyToPlay)])
            {
                if(progressIndicator.value == 0)
                {
                    [delegate playerReadyToPlay];
                    
                    coverView.image = [UIImage imageNamed:@""];
                }
            }
            else
            {
                if(self.onEvent && progressIndicator.value == 0)
                {
                    AVPlayerItem *item = self.player.currentItem;
                    
                    AVURLAsset *asset = (AVURLAsset *)item.asset;
                    
                    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                    
                    if(audioTrack)
                    {
                        if(self.onEvent)
                        {
                            self.onEvent(0, @{@"track":audioTrack, @"item":self.player.currentItem});
                        }
                    }
                    else
                    {

                    }
                    
                    coverView.image = [UIImage imageNamed:@""];
                }
            }
        }
    }

    if([options responseForKey:@"EQ"])
    {
//        AVAudioMix *audioMix = self.audioTapProcessor.audioMix;
//        
//        if (audioMix)
//        {
//            self.player.currentItem.audioMix = audioMix;
//        }
    }
}

- (void)dealloc {
}

@end

