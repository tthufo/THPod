//
//  PopUpMenu.h
//  btCustomPopUP
//
//  Created by Balram Tiwari on 02/06/14.
//  Copyright (c) 2014 Balram Tiwari. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>

typedef NS_ENUM(NSInteger, BTPopUpStyle) {
    BTPopUpStyleDefault,
    BTPopUpStyleMinimalRoundedCorner
};

typedef NS_ENUM(NSInteger, BTPopUpAnimation) {
    BTPopUPAnimateWithFade,
    BTPopUPAnimateNone
};

typedef NS_ENUM(NSInteger, BTPopUpBorderStyle) {
    BTPopUpBorderStyleDefaultNone,
    BTPopUpBorderStyleLightContent,
    BTPopUpBorderStyleDarkContent
};


@class PopUpMenu;

typedef void (^completion)(BOOL success);

typedef void (^PopUpCompletion)(int indexButton, id object);

@protocol PopUpMenuDelegate <NSObject>

@optional

- (void)PopUpMenu:(PopUpMenu *)popUp didSelectItemAtIndex:(NSInteger)index;

- (void)PopUpMenu:(PopUpMenu *)popUp;
;
@end

@interface PopUpMenu : UIView <UIScrollViewDelegate>{
    UIImageView *backGroundBlurr;
    UIView *contentView;
    CGSize itemSize;
    UIColor *itemColor, *itemTextColor, *highlightColor, *backgroundColor;
    UIFont *itemFont;
    NSArray *popItems;
    UIScrollView *scrollView;
    UIPageControl * pageControl;
    PopUpCompletion completionBlock;
}
@property (nonatomic, assign) BTPopUpStyle popUpStyle;
@property (nonatomic, assign) BTPopUpBorderStyle popUpBorderStyle;
@property (nonatomic, assign) UIColor *popUpBackgroundColor;
@property (nonatomic, assign) BTPopUpAnimation animationStyle;
@property(nonatomic, weak) id <PopUpMenuDelegate> delegate;
@property (nonatomic) BOOL setShowRipples;

+ (PopUpMenu*)shareInstance;

- (PopUpMenu*)didPopUpWithInfo:(NSDictionary*)dict andCompletion:(PopUpCompletion)completion;

-(instancetype)initWithItemImage:(NSArray *)items andActionArray:(NSArray *)actionArray addToViewController:(UIViewController*)sender;
-(instancetype)initWithItemImage:(NSArray *)items andTitles:(NSArray *)titleArray andActionArray:(NSArray *)actionArray addToViewController:(UIViewController*)sender;

-(instancetype)initWithItemImage:(NSArray *)items andTitles:(NSArray *)titleArray addToViewController:(UIViewController*)sender;

-(void)setPopUpBackgroundColor:(UIColor *)popUpBackgroundColor;
-(void)show:(BTPopUpAnimation)animation;
-(void)dismiss;
@end


@interface UIView (bt_screenshot)
- (UIImage *)screenshot;

@end

@interface UIImage (bt_blurrEffect)
- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor;
@end