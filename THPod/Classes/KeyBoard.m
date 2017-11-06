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
    
    NSMutableDictionary * keboardElement;
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

- (KeyBoard*)keyboardOn:(NSDictionary*)dict andCompletion:(KeyBoardEvents)kbEvent
{
    keboardElement = [[NSMutableDictionary alloc] initWithDictionary:dict];
    
    UIView * barView = (UIView*)keboardElement[@"bar"];
    
    UIViewController * host = (UIViewController*)keboardElement[@"host"];
    
    barView.frame = CGRectMake(0, [self screenHeight], [self screenWidth], barView.frame.size.height);
    
    [host.view addSubview:barView];
    
    
    
    [self registerForKeyboardNotifications:YES andSelector:@[@"keyboardWasShown:",@"keyboardWillBeHidden:"]];
    
    event = kbEvent;
    
    return self;
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
    
    [(UIView*)keboardElement[@"bar"] removeFromSuperview];
    
    keboardElement = nil;
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    if(!isOn)
    {
        CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

        CGRect rect = ((UIView*)keboardElement[@"bar"]).frame;
        
        rect.origin.y -= keyboardSize.height + rect.size.height;
        
        ((UIView*)keboardElement[@"bar"]).frame = rect;
        
        event(keyboardSize.height, YES);
            
        isOn = YES;
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    if(isOn)
    {
        CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

        CGRect rect = ((UIView*)keboardElement[@"bar"]).frame;
        
        rect.origin.y = [self screenHeight];
        
        ((UIView*)keboardElement[@"bar"]).frame = rect;
        
        event(keyboardSize.height, NO);
            
        isOn = NO;
    }
}

@end
