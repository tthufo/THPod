//
//  CircularSliderView.h
//  CircularSlider
//
//  Created by Thomas Finch on 4/9/13.
//  Copyright (c) 2013 Thomas Finch. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum __sliderState
{
    touchDown,
    touchMove,
    touchEnd,
}SliderState;

@class CircularSliderView;

typedef void (^CSCompletion)(SliderState type, float sliderValue, CircularSliderView * slider);

@interface CircularSliderView : UIView

@property (nonatomic,copy) CSCompletion completion;

- (void)completion:(CSCompletion)_completion;

- (id)initWithMinValue:(float)minValue maxValue:(float)maxValue initialValue:(float)initialValue;

- (void)setSliderValue:(float)minimumValue maxValue:(float)maximumValue initialValue:(float)initialValue;

- (void)setSliderValue:(float)value;

- (void)setTintColor:(UIColor*)minColor andMax:(UIColor*)maxColor;

- (void)cleanUpSlider;

- (float)value;

@end
