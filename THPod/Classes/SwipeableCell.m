//
//  SwipeableCell.m
//  SwipeableTableCell
//
//  Created by Ellen Shapiro on 1/5/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

#import "SwipeableCell.h"

@interface SwipeableCell() <UIGestureRecognizerDelegate>
{
    NSString * widthRange;
    
    int indexing, section;
    
    BOOL isEnable;
}

@property (nonatomic, weak) IBOutlet UIView * myContentView;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, assign) CGPoint panStartPoint;
@property (nonatomic, assign) CGFloat startingRightLayoutConstraintConstant;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewRightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewLeftConstraint;

@end

static CGFloat const kBounceValue = 0.0f;

@implementation SwipeableCell

@synthesize onSwipeEvent;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panThisCell:)];
    
    self.panRecognizer.delegate = self;
    
    [self.myContentView addGestureRecognizer:self.panRecognizer];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self resetConstraintContstantsToZero:NO notifyDelegateDidClose:NO];
}

- (void)setEnableTouch:(BOOL)isEnable_
{
    isEnable = isEnable_;
}

- (void)didConfigureCell:(NSDictionary*)dict andCompletion:(SwipeAction)swipeEvent
{
    self.onSwipeEvent = swipeEvent;
    
    widthRange = dict[@"range"];
    
    indexing = [dict[@"index"] intValue];
    
    section = [dict[@"section"] intValue];
    
    for(UIButton * button in dict[@"buttons"])
    {
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    isEnable = [dict[@"enable"] boolValue];
}

- (void)closeCell
{
    [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
}

- (void)openCell
{
    [self setConstraintsToShowAllButtons:NO notifyDelegateDidOpen:NO];
}

- (IBAction)buttonClicked:(UIButton*)sender
{
    if(self.onSwipeEvent)
    {
        self.onSwipeEvent(2, @{@"tag":@(sender.tag),@"index":@(indexing),@"section":@(section),@"host":self});
    }
}

- (UIView*)cellContentView
{
    return self.myContentView;
}

- (CGFloat)buttonTotalWidth
{
    return [widthRange floatValue];
}

- (BOOL)isOpen
{
    return self.contentViewRightConstraint.constant == [widthRange floatValue];
}

//- (void)panThisCell:(UIPanGestureRecognizer *)recognizer
//{
//    if(!isEnable)
//    {
//        return;
//    }
//    
//    float limit = self.contentView.frame.origin.x;
//    
//    switch (recognizer.state) {
//        case UIGestureRecognizerStateBegan:
//            self.panStartPoint = [recognizer translationInView:self.myContentView];
//            self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
//            break;
//            
//        case UIGestureRecognizerStateChanged: {
//            self.onSwipeEvent(4, @{@"index":@(indexing),@"section":@(section),@"host":self});
//            CGPoint currentPoint = [recognizer translationInView:self.myContentView];
//            CGFloat deltaX = currentPoint.x - self.panStartPoint.x;
//            
//            if(deltaX > -70)
//            {
//                return;
//            }
//            
//            BOOL panningLeft = NO;
//            if (currentPoint.x < self.panStartPoint.x) {  //1
//                panningLeft = YES;
//            }
//        
//            if (self.startingRightLayoutConstraintConstant == 0) { //2
//                //The cell was closed and is now opening
//                if (!panningLeft) {
//                    CGFloat constant = MAX(-deltaX, 0); //3
//                    if (constant == 0) { //4
//                        [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES]; //5
//                    } else {
//                        self.contentViewRightConstraint.constant = constant; //6
//                    }
//                } else {
//                    CGFloat constant = MIN(-deltaX, [self buttonTotalWidth]); //7
//                    if (constant == [self buttonTotalWidth]) { //8
//                        [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES]; //9
//                    } else {
//                        self.contentViewRightConstraint.constant = constant; //10
//                    }
//                }
//            }else {
//                //The cell was at least partially open.
//                CGFloat adjustment = self.startingRightLayoutConstraintConstant - deltaX; //11
//
//                if (!panningLeft) {
//                    CGFloat constant = MAX(adjustment, 0); //12
//                    if (constant == 0) { //13
//                        [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES]; //14
//                    } else {
//                        self.contentViewRightConstraint.constant = constant; //15
//                    }
//                } else {
//                    CGFloat constant = MIN(adjustment, [self buttonTotalWidth]); //16
//                    if (constant == [self buttonTotalWidth]) { //17
//                        [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES]; //18
//                    } else {
//                        self.contentViewRightConstraint.constant = constant;//19
//                    }
//                }
//            }
//            
//                self.contentViewLeftConstraint.constant = -self.contentViewRightConstraint.constant; //20
//        }
//            break;
//            
//        case UIGestureRecognizerStateEnded:
//            if (self.startingRightLayoutConstraintConstant == 0) { //1
//                //We were opening
//                CGFloat halfOfButtonOne = [widthRange floatValue] / 2; //2
//                if (self.contentViewRightConstraint.constant >= halfOfButtonOne) { //3
//                    //Open all the way
//                    [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES];
//                } else {
//                    //Re-close
//                    [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
//                }
//                
//            } else {
//                //We were closing
//                CGFloat buttonOnePlusHalfOfButton2 = ([widthRange floatValue] / 2); //4
//                if (self.contentViewRightConstraint.constant >= buttonOnePlusHalfOfButton2) { //5
//                    //Re-open all the way
//                    [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES];
//                } else {
//                    //Close
//                    [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
//                }
//            }
//            self.onSwipeEvent(5, @{@"index":@(indexing),@"section":@(section),@"host":self});
//            break;
//            
//        case UIGestureRecognizerStateCancelled:
//            if (self.startingRightLayoutConstraintConstant == 0) {
//                //We were closed - reset everything to 0
//                [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
//            } else {
//                //We were open - reset to the open state
//                [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES];
//            }
//            self.onSwipeEvent(5, @{@"index":@(indexing),@"section":@(section),@"host":self});
//            break;
//            
//            
//        default:
//            break;
//    }
//}

- (void)panThisCell:(UIPanGestureRecognizer *)recognizer
{
    if(!isEnable)
    {
        return;
    }
    
    float limit = self.contentView.frame.origin.x;

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.panStartPoint = [recognizer translationInView:self.myContentView];
            self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
            break;

        case UIGestureRecognizerStateChanged: {
            CGPoint currentPoint = [recognizer translationInView:self.myContentView];
            CGFloat deltaX = currentPoint.x - self.panStartPoint.x;
            
            if(deltaX > -70)
            {
                return;
            }
            
            BOOL panningLeft = NO;
            if (currentPoint.x < self.panStartPoint.x) {  //1
                panningLeft = YES;
            }
            
            if(!panningLeft)
            {
                return;
            }
            
            
            
            
            
            
            
            
            if (self.startingRightLayoutConstraintConstant == 0) { //2
                //The cell was closed and is now opening
//                if (!panningLeft) {
//                    CGFloat constant = MAX(-deltaX, 0); //3
//                    if (constant == 0) { //4
//                        [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES]; //5
//                    } else {
//                        self.contentViewRightConstraint.constant = constant; //6
//                    }
//                } else
                {
                    CGFloat constant = MIN(-deltaX, [self buttonTotalWidth]); //7
                    if (constant == [self buttonTotalWidth]) { //8
                        [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES]; //9
                    } else {
//                        self.contentViewRightConstraint.constant = constant; //10
                    }
                }
            }else {
                //The cell was at least partially open.
//                CGFloat adjustment = self.startingRightLayoutConstraintConstant - deltaX; //11
//                
//                if (!panningLeft) {
//                    CGFloat constant = MAX(adjustment, 0); //12
//                    if (constant == 0) { //13
//                        [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES]; //14
//                    } else {
//                        self.contentViewRightConstraint.constant = constant; //15
//                    }
//                } else {
//                    CGFloat constant = MIN(adjustment, [self buttonTotalWidth]); //16
//                    if (constant == [self buttonTotalWidth]) { //17
//                        [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES]; //18
//                    } else {
//                        self.contentViewRightConstraint.constant = constant;//19
//                    }
//                }
            }
            
//            self.contentViewLeftConstraint.constant = -self.contentViewRightConstraint.constant; //20
        }
            break;

        case UIGestureRecognizerStateEnded:
            if (self.startingRightLayoutConstraintConstant == 0) { //1
                //We were opening
                CGFloat halfOfButtonOne = [widthRange floatValue] / 2; //2
                if (self.contentViewRightConstraint.constant >= halfOfButtonOne) { //3
                    //Open all the way
                    [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES];
                } else {
                    //Re-close
                    //[self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
                }
                
            } else {
                //We were closing
//                CGFloat buttonOnePlusHalfOfButton2 = ([widthRange floatValue] / 2); //4
//                if (self.contentViewRightConstraint.constant >= buttonOnePlusHalfOfButton2) { //5
//                    //Re-open all the way
//                    [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES];
//                } else {
//                    //Close
//                    [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
//                }
            }
            
            if(self.onSwipeEvent)
            {
                self.onSwipeEvent(5, @{@"index":@(indexing),@"section":@(section),@"host":self});
            }
            break;

        case UIGestureRecognizerStateCancelled:
            if (self.startingRightLayoutConstraintConstant == 0) {
                //We were closed - reset everything to 0
//                [self resetConstraintContstantsToZero:YES notifyDelegateDidClose:YES];
            } else {
                //We were open - reset to the open state
//                [self setConstraintsToShowAllButtons:YES notifyDelegateDidOpen:YES];
            }
            
            if(self.onSwipeEvent)
            {
                self.onSwipeEvent(5, @{@"index":@(indexing),@"section":@(section),@"host":self});
            }
            break;
            
            
        default:
            break;
    }
}

- (void)updateConstraintsIfNeeded:(BOOL)animated completion:(void (^)(BOOL finished))completion;
{
    float duration = 0;
    
    if (animated)
    {
        duration = 0.3;
    }
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self layoutIfNeeded];
    } completion:completion];
}


- (void)resetConstraintContstantsToZero:(BOOL)animated notifyDelegateDidClose:(BOOL)notifyDelegate
{
    if (notifyDelegate) {
        if(self.onSwipeEvent)
        {
            self.onSwipeEvent(1, @{@"index":@(indexing),@"section":@(section),@"host":self});
        }
    }
    
    if (self.startingRightLayoutConstraintConstant == 0 &&
        self.contentViewRightConstraint.constant == 0) {
        return;
    }
    
    self.contentViewRightConstraint.constant = -kBounceValue;
    self.contentViewLeftConstraint.constant = kBounceValue;
    
    [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
        self.contentViewRightConstraint.constant = 0;
        self.contentViewLeftConstraint.constant = 0;

        [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
            self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
            if(self.onSwipeEvent)
            {
                self.onSwipeEvent(1, @{@"index":@(indexing),@"section":@(section),@"host":self});
            }
        }];
    }];
}


- (void)setConstraintsToShowAllButtons:(BOOL)animated notifyDelegateDidOpen:(BOOL)notifyDelegate
{
    if (notifyDelegate) {
        if(self.onSwipeEvent)
        {
            self.onSwipeEvent(0, @{@"index":@(indexing),@"section":@(section),@"host":self});
        }
    }
    //1
    if (self.startingRightLayoutConstraintConstant == [self buttonTotalWidth] &&
        self.contentViewRightConstraint.constant == [self buttonTotalWidth]) {
        return;
    }
    //2
    self.contentViewLeftConstraint.constant = -[self buttonTotalWidth] - kBounceValue;
    self.contentViewRightConstraint.constant = [self buttonTotalWidth] + kBounceValue;
    
    [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
        //3
        self.contentViewLeftConstraint.constant = -[self buttonTotalWidth];
        self.contentViewRightConstraint.constant = [self buttonTotalWidth];
        
        [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
            //4
            self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
            if(self.onSwipeEvent)
            {
                self.onSwipeEvent(0, @{@"index":@(indexing),@"section":@(section),@"host":self});
            }
        }];
    }];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
