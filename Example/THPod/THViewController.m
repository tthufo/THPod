//
//  THViewController.m
//  THPod
//
//  Created by tthufo on 07/17/2016.
//  Copyright (c) 2016 tthufo. All rights reserved.
//

#import "THViewController.h"

#import "FBPlugInHeader.h"

@interface THViewController ()

@end

@implementation THViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[LTRequest sharedInstance] didRequestInfo:@{@"CMD_CODE":@"getappinfo",
                                                 @"host":self,
                                                 @"overrideLoading":@(1),
                                                 @"overrideError":@(1)
                                                 
                                                 } withCache:^(NSString *cacheString) {
                                                     
    } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
        
        NSLog(@"%@",responseString);
        
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
