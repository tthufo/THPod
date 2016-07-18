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
    
    [[LTRequest sharedInstance] didRequestInfo:@{@"absoluteLink":@"http://pns.ising.vn/api/register?id=78cb9a5c06fccd1d4d27b2cb428a4fd862c2a7e19a4ffe07f32847c3d607d49a&appid=9",
                                                 @"host":self,
                                                 @"overrideLoading":@(1),
                                                 @"overrideError":@(1)
                                                 
                                                 } withCache:^(NSString *cacheString) {
                                                     
    } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
                
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
