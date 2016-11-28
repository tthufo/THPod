#import <UIKit/UIKit.h>

@interface VerticalSlider : UISlider

@property (nonatomic, retain) NSNumber * thick;

@end

@interface VerticalSlider (xibRunTime)

@property(nonatomic, assign) NSNumber* thickNess;

@end