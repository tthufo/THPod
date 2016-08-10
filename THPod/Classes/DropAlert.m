//
//  DropAlert.m
//  Pods
//
//  Created by thanhhaitran on 2/27/16.
//
//

#import "DropAlert.h"

#import "JSONKit.h"

#import "NSObject+Category.h"

static DropAlert * __shareInstance = nil;

@interface DropAlert () <UIAlertViewDelegate, UIActionSheetDelegate, UITextFieldDelegate>
{
    DropAlertCompletion completionBlock;
}

@end

@implementation DropAlert

+ (DropAlert*)shareInstance
{
    if(!__shareInstance)
    {
        __shareInstance = [DropAlert new];
    }
    
    return __shareInstance;
}

- (void)actionSheetWithInfo:(NSDictionary*)dict andCompletion:(DropAlertCompletion)completion
{
    completionBlock = completion;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:dict[@"title"]
                                                             delegate:self
                                                    cancelButtonTitle:dict[@"cancel"]
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    for( NSString *title in dict[@"buttons"])
    {
        [actionSheet addButtonWithTitle:title];
    }
    
    [actionSheet showInView:((UIViewController*)dict[@"host"]).view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    completionBlock(buttonIndex, nil);
}

- (void)alertWithInfor:(NSDictionary*)dict andCompletion:(DropAlertCompletion)completion
{
    completionBlock = completion;
    
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:dict[@"title"] message:dict[@"message"] delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    
    alertView.accessibilityLabel = [dict bv_jsonStringWithPrettyPrint:NO];
    
    for( NSString *title in dict[@"buttons"])
    {
        [alertView addButtonWithTitle:title];
    }
    
    [alertView addButtonWithTitle:dict[@"cancel"]];
    
    if([dict responseForKey:@"option"])
    {
        alertView.alertViewStyle = ![dict[@"option"] boolValue] ? UIAlertViewStylePlainTextInput : UIAlertViewStyleLoginAndPasswordInput;
        
        if(alertView.alertViewStyle == UIAlertViewStylePlainTextInput)
        {
            ((UITextField*)[alertView textFieldAtIndex:0]).text = dict[@"text"];
            
            ((UITextField*)[alertView textFieldAtIndex:0]).delegate = self;
        }
        else
        {
            ((UITextField*)[alertView textFieldAtIndex:0]).delegate = self;
            
            ((UITextField*)[alertView textFieldAtIndex:1]).delegate = self;
        }
    }
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSDictionary * info = [alertView.accessibilityLabel objectFromJSONString];
    
    if([info responseForKey:@"option"])
    {
        if([info[@"option"] boolValue])
        {
            completionBlock(buttonIndex, @{@"uName":[alertView textFieldAtIndex:0].text,@"pWord":[alertView textFieldAtIndex:1].text});
        }
        else
        {
            completionBlock(buttonIndex, @{@"uName":[alertView textFieldAtIndex:0].text});
        }
    }
    else
    {
        completionBlock(buttonIndex, nil);
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return NO;
}

@end
