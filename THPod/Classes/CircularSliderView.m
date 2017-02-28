//
//  CircularSliderView.m
//  CircularSlider
//
//  Created by Thomas Finch on 4/9/13.
//  Copyright (c) 2013 Thomas Finch. All rights reserved.
//

#import "CircularSliderView.h"

#define MIN_ANGLE -M_PI/3 - 0
#define MAX_ANGLE (4*M_PI)/3 - 0

@interface CircularSliderView ()
{
    UIColor * minColor, * maxColor;
}

@end

@implementation CircularSliderView

@synthesize completion;

static CGPoint barCenter, knobCenter;
static float barRadius, knobRadius = 10, knobAngle, minValue, maxValue;
static bool isKnobBeingTouched = false;

- (void)completion:(CSCompletion)_completion
{
    self.completion = _completion;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
   // [self setup];
}

- (void)setTintColor:(UIColor*)minColor_ andMax:(UIColor*)maxColor_
{
    minColor = minColor_;
    
    maxColor = maxColor_;
}

- (void)setup
{
    [self setBackgroundColor:[UIColor clearColor]];

    knobAngle = 0;
    
    maxValue = 1;
    
    minValue = 0;
    
    knobAngle = MIN_ANGLE+(0*(MAX_ANGLE-MIN_ANGLE));
    
    CGAffineTransform translate = CGAffineTransformMakeRotation(-90 * M_PI/180);
    
    CGAffineTransform scale = CGAffineTransformMakeScale(1.0, -1.0);
    
    CGAffineTransform transform =  CGAffineTransformConcat(translate, scale);
    
    self.transform = transform;
    
    minColor = [UIColor lightGrayColor];
    
    maxColor = [UIColor blueColor];
}

- (void)setSliderValue:(float)minimumValue maxValue:(float)maximumValue initialValue:(float)initialValue
{
    maxValue = maximumValue;
    minValue = minimumValue;
    
    float percentDone = 1-(initialValue/(maxValue - minValue));
    knobAngle = MIN_ANGLE+(percentDone*(MAX_ANGLE-MIN_ANGLE));
}

- (id)initWithMinValue:(float)minimumValue maxValue:(float)maximumValue initialValue:(float)initialValue
{
    self = [super init];
    if (self)
    {
        [self setBackgroundColor:[UIColor clearColor]];

        maxValue = maximumValue;
        minValue = minimumValue;
        
        //calclulate initial angle from initial value
        float percentDone = 1-(initialValue/(maxValue - minValue));
        knobAngle = MIN_ANGLE+(percentDone*(MAX_ANGLE-MIN_ANGLE));
        
        CGAffineTransform translate = CGAffineTransformMakeRotation(-90 * M_PI/180);
        
        CGAffineTransform scale = CGAffineTransformMakeScale(1.0, -1.0);
        
        CGAffineTransform transform =  CGAffineTransformConcat(translate, scale);
        
        self.transform = transform;
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count > 1)
        return;
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    isKnobBeingTouched = false;
    CGFloat xDist = touchLocation.x - knobCenter.x;
    CGFloat yDist = touchLocation.y - knobCenter.y;
    if (sqrt((xDist*xDist)+(yDist*yDist)) <= knobRadius) //if the touch is within the slider knob
    {
        isKnobBeingTouched = true;
        
        if(self.completion && isKnobBeingTouched)
        {
            self.completion(0, [self value] < 0 ? 0 : [self value], self);
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isKnobBeingTouched)
    {
        CGPoint touchLocation = [[touches anyObject] locationInView:self];
        float touchVector[2] = {touchLocation.x-knobCenter.x, touchLocation.y-knobCenter.y}; //gets the vector of the difference between the touch location and the knob center
        float tangentVector[2] = {knobCenter.y-barCenter.y, barCenter.x-knobCenter.x}; //gets a vector tangent to the circle at the center of the knob
        float scalarProj = (touchVector[0]*tangentVector[0] + touchVector[1]*tangentVector[1])/sqrt((tangentVector[0]*tangentVector[0])+(tangentVector[1]*tangentVector[1])); //calculates the scalar projection of the touch vector onto the tangent vector
        knobAngle += scalarProj/barRadius;
        
        if (knobAngle > MAX_ANGLE) //ensure knob is always on the bar
            knobAngle = MAX_ANGLE;
        if (knobAngle < MIN_ANGLE)
            knobAngle = MIN_ANGLE;
        
        knobAngle = fmodf(knobAngle, 2*M_PI); //ensures knobAngle is always between 0 and 2*Pi
        
        if(self.completion && isKnobBeingTouched)
        {
            self.completion(1, [self value] < 0 ? 0 : [self value], self);
        }
        
        if([self value] <= 0)
        {
            return;
        }
        
        [self setNeedsDisplay];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(self.completion && isKnobBeingTouched)
    {
        self.completion(2, [self value] < 0 ? 0 : [self value], self);
    }
    
    isKnobBeingTouched = false;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isKnobBeingTouched = false;
}

- (void)cleanUpSlider
{
    for(UIView * v in self.subviews)
    {
        [v removeFromSuperview];
    }
}

- (void)setSliderValue:(float)value
{
    float percentDone = 1-(value/(maxValue - minValue));
    knobAngle = MIN_ANGLE+(percentDone*(MAX_ANGLE-MIN_ANGLE));
    
    if (knobAngle > MAX_ANGLE)
        knobAngle = MAX_ANGLE;
    if (knobAngle < MIN_ANGLE)
        knobAngle = MIN_ANGLE;

    knobAngle = fmodf(knobAngle, 2*M_PI);
    
    if([self value] <= 0 )
    {
        return;
    }

    [self setNeedsDisplay];
}

- (float)value
{
    float percentDone = 1.0 - ((knobAngle-MIN_ANGLE)/(MAX_ANGLE-MIN_ANGLE));
    
    return percentDone*(maxValue-minValue);
}

- (void)drawRect:(CGRect)rect
{
    //gets bar and knob coordinates based on the rectangle they're being drawn in
    barCenter.x = CGRectGetMidX(rect);
    barCenter.y = CGRectGetMidY(rect);
    barRadius = (CGRectGetHeight(rect) <= CGRectGetWidth(rect))?CGRectGetHeight(rect)/2:CGRectGetWidth(rect)/2; //gets the width or height, whichever is smallest, and stores it in radius
    barRadius = barRadius*.9;
    
    
    //finds the center of the knob by converting from polar to cartesian coordinates
    knobCenter.x = barCenter.x+(barRadius*cosf(knobAngle));
    knobCenter.y = barCenter.y-(barRadius*sinf(knobAngle));
    
    CGContextRef context = UIGraphicsGetCurrentContext();
        
    //draw the slider bar
    CGContextSetLineWidth(context, 3.0);
    
    CGContextSetStrokeColorWithColor(context, minColor.CGColor);
    
    CGContextAddArc(context,barCenter.x,barCenter.y,barRadius,fmodf(MIN_ANGLE+M_PI, 2*M_PI),fmodf(MAX_ANGLE+M_PI, 2*M_PI),0);

    CGContextDrawPath(context, kCGPathStroke);

    UIGraphicsPushContext(context);
    CGContextBeginPath(context);
    
    CGContextSetStrokeColorWithColor(context, maxColor.CGColor);

    CGContextAddArc(context,barCenter.x,barCenter.y,barRadius,fmodf(MIN_ANGLE+M_PI, 2*M_PI), fmodf(-knobAngle, 2*M_PI),0);

//    CGPoint arcEndPoint = CGContextGetPathCurrentPoint(context);
    
    CGContextStrokePath(context);
    UIGraphicsPopContext();
    
    CGContextDrawPath(context, kCGPathStroke);
    
    //draw the knobC5B5B6
    CGContextSetLineWidth(context, 2.0);
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextAddArc(context, knobCenter.x, knobCenter.y, knobRadius, 0, 2*M_PI, 1);
    
    //draw gradient in the knob
    CGContextClip(context);
    CGPoint knobTop = {knobCenter.x, knobCenter.y-knobRadius}, knobBottom = {knobCenter.x, knobCenter.y+knobRadius};
    CGFloat locations[2] = {0.0 ,1.0};
    CFArrayRef colors = (__bridge CFArrayRef) [NSArray arrayWithObjects:[UIColor lightGrayColor].CGColor, [UIColor whiteColor].CGColor, nil];
    CGColorSpaceRef colorSpc = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpc, colors, locations);
    
    CGContextDrawLinearGradient(context, gradient, knobTop, knobBottom, 0);
    //CGContextDrawRadialGradient(context, gradient, knobCenter, knobRadius*.5, knobCenter, knobRadius, 0);
     
    CGContextDrawPath(context, kCGPathStroke);
    //CGContextDrawPath(context, kCGPathFill);
}


@end
