//
//  GUISlider.m
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 08/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import "GUISlider.h"

@interface GUISlider ()

@property (strong, nonatomic) UIProgressView *progressView;

@end

@implementation GUISlider

@synthesize progressView;

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  [self setup];
  return self;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    return CGRectMake(0, (self.frame.size.height - [self.thick floatValue]) / 2, self.frame.size.width, [self.thick floatValue]);
}

- (void)setup {
  [self setMaximumTrackTintColor:[UIColor clearColor]];
  
  progressView = [UIProgressView new];
    
  CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 2.0f);
  progressView.transform = transform;
    
  [progressView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [progressView setClipsToBounds:YES];
  [[progressView layer] setCornerRadius:2.0f];
  
  CGFloat hue, sat, bri;
  [[self tintColor] getHue:&hue saturation:&sat brightness:&bri alpha:nil];
  [progressView setTintColor:[UIColor colorWithHue:hue saturation:(sat * 0.6f) brightness:bri alpha:1]];
  
  [self addSubview:progressView];
  
  NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[PV]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"PV" : progressView}];
  
  [self addConstraints:constraints];
  
  constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(20)-[PV]"
                                                        options:0
                                                        metrics:nil
                                                          views:@{@"PV" : progressView}];
  
  [self addConstraints:constraints];  
}

- (void)setSecondaryValue:(float)value {
  [progressView setProgress:value];
}

- (void)setTintColor:(UIColor *)tintColor {
  [super setTintColor:tintColor];
  
  CGFloat hue, sat, bri;
  [[self tintColor] getHue:&hue saturation:&sat brightness:&bri alpha:nil];
  [progressView setTintColor:[UIColor colorWithHue:hue saturation:(sat * 0.6f) brightness:bri alpha:1]];
}

- (void)setSecondaryTintColor:(UIColor *)tintColor {
  [progressView setTintColor:tintColor];
}

@end

@implementation GUISlider (extra)

- (void)setThickNess:(NSNumber *)thickNess
{
    self.thick = thickNess;
}

- (NSNumber*)thickNess
{
    return self.thick;
}

@end
