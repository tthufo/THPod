//
//  THViewController.m
//  THPod
//
//  Created by tthufo on 07/17/2016.
//  Copyright (c) 2016 tthufo. All rights reserved.
//

#import "THViewController.h"

#import "TH1ViewController.h"

@interface THViewController ()
{
    KeyBoard * kb;
    
    IBOutlet UIView * v;
}

@end

@implementation THViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [[LTRequest sharedInstance] didRequestInfo:@{@"CMD_CODE":@"getappinfo",
//                                                 @"host":self,
//                                                 @"overrideLoading":@(1),
//                                                 @"overrideAlert":@(1)
////                                                 @"overrideError":@(1)
//                                                 
//                                                 } withCache:^(NSString *cacheString) {
//                                                     
//    } andCompletion:^(NSString *responseString, NSString *errorCode, NSError *error, BOOL isValidated) {
//        
//        NSLog(@"%@ _ %@",responseString, errorCode);
//        
//    }];
    
//    NSLog(@"____%@",v);
//
//    v.frame = CGRectMake(0, 0, 100, 40);
//    
//    [self.view addSubview:v];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    kb = [[KeyBoard shareInstance] keyboardOn:@{@"bar":v, @"host":self} andCompletion:^(CGFloat kbHeight, BOOL isOn) {
        
    }];
}

- (IBAction)didPressDone:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)didPress:(id)sender
{
    [self.navigationController pushViewController:[TH1ViewController new] animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [kb keyboardOff];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
