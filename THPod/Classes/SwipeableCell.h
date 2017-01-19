//
//  SwipeableCell.h
//  SwipeableTableCell
//
//  Created by Ellen Shapiro on 1/5/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum __swipeState
{
    didOpen,//
    didClose,//
    didClick,
    didForceClose
}SwipeState;

typedef void (^SwipeAction)(SwipeState swipeState, NSDictionary * actionInfo);

@interface SwipeableCell : UITableViewCell

@property (nonatomic, copy) SwipeAction onSwipeEvent;

- (void)didConfigureCell:(NSDictionary*)dict andCompletion:(SwipeAction)swipeEvent;

- (UIView*)cellContentView;

- (void)setEnableTouch:(BOOL)isEnable_;

- (void)openCell;

- (void)closeCell;

@end
