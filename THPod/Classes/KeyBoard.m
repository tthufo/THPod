//
//  KeyboardViewController.m
//  Pods
//
//  Created by thanhhaitran on 6/29/16.
//
//

#import "KeyBoard.h"

#import "NSObject+Category.h"

static KeyBoard * instance = nil;

@interface KeyBoard ()
{
    BOOL isOn;
}

@end

@implementation KeyBoard

@synthesize event;

+ (KeyBoard*)shareInstance
{
    if(!instance)
    {
        instance = [KeyBoard new];
    }
    return instance;
}

- (KeyBoard*)keyboardOn:(KeyBoardEvents)kbEvent
{
    [self registerForKeyboardNotifications:YES andSelector:@[@"keyboardWasShown:",@"keyboardWillBeHidden:"]];
    
    event = kbEvent;
    
    return self;
}

- (void)keyboardOff
{
    [self registerForKeyboardNotifications:NO andSelector:@[@"keyboardWasShown:",@"keyboardWillBeHidden:"]];
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    if(!isOn)
        event(keyboardSize.height, YES);
    isOn = YES;
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    if(isOn)
        event(keyboardSize.height, NO);
    isOn = NO;
}

@end
