//
//  THViewController.m
//  THPod
//
//  Created by tthufo on 07/17/2016.
//  Copyright (c) 2016 tthufo. All rights reserved.
//

#import "THViewController.h"

#import "TH1ViewController.h"

//#import "IFTweetLabel.h"


@interface THViewController ()<GUIPlayerViewDelegate>
{
    KeyBoard * kb;
    
    IBOutlet UIView * v;
    
    int kk;
    
    IBOutlet UILabel * name;
}

@property(nonatomic, retain) GUIPlayerView * playerView;

@end

@implementation THViewController

@synthesize playerView = _playerView;

- (IBAction)didPressT:(id)sender
{
//    [[FB shareInstance] startLoginTwitterWithCompletion:^(NSString * responseString, id object, int errorCode, NSString *description, NSError * error){
//        
//        NSLog(@"%@", object);
//        
//    }];
    
    NSArray * dict = [self arrayWithPlist:@"EQ"];
    
    name.text = dict[kk][@"name"];
    
    for(UIView * k in self.view.subviews)
    {
        if([k isKindOfClass:[UISlider class]])
        {
            [((UISlider*)k) setValue:[[dict[kk][@"fc"] componentsSeparatedByString:@","][k.tag] floatValue] animated:YES];
            
            NSLog(@"%f", [[dict[kk][@"fc"] componentsSeparatedByString:@","][k.tag] floatValue]);
            
            [_playerView adjustEQ:(((UISlider*)k)).value andPosition:(((UISlider*)k)).tag];
        }
    }
    
    kk+=1;
    
    if(kk == dict.count - 1)
    {
        kk = 0;
    }
}

- (IBAction)play:(id)sender
{
//    if(![self.playerView isPlaying])
    {
        [self.playerView play];
    }
}

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
    
//    [System addValue:@"1" andKey:@"key"];
    
//    NSLog(@"%@", ((System*)[[System getAll] lastObject]).key);
    
//    [[LTRequest sharedInstance] askGallery:^(CamPermisionType type){
//        switch (type) {
//            case authorized:
//                NSLog(@"%@", @"granted");
//                break;
//            case denied:
//                NSLog(@"%@", @"denied");
//                break;
//            case per_granted:
//                NSLog(@"%@", @"Just granted");
//                break;
//            case per_denied:
//                NSLog(@"%@", @"Just denied");
//                break;
//            case restricted:
//                NSLog(@"%@", @"restricted setting");
//                break;
//            default:
//                break;
//        }
//    }];
//    
//    
//    [[LTRequest sharedInstance] askMicrophone:^(MicPermisionType type){
//        
//        switch (type) {
//            case mGranted:
//                NSLog(@"%@", @"granted");
//                break;
//            case mDined:
//                NSLog(@"%@", @"denied");
//                break;
//            case mPer_granted:
//                NSLog(@"%@", @"Just granted");
//                break;
//            case mPer_denied:
//                NSLog(@"%@", @"Just denied");
//                break;
//            default:
//                break;
//        }
//        
//    }];
    
//    [[Pemission sharedInstance] initLocation:NO andCompletion:^(LocationPermisionType type) {
//        switch (type) {
//            case lAlways:
//                NSLog(@"%@", @"granted always");
//                break;
//            case lDenied:
//                NSLog(@"%@", @"denied");
//                break;
//            case lRestricted:
//                NSLog(@"%@", @"restricted");
//                break;
//            case lWhenUse:
//                NSLog(@"%@", @"when in use");
//                break;
//            case lNotSure:
//                NSLog(@"%@", @"not determined");
//                break;
//            default:
//                break;
//        }
//    }];
    
    [self didPlayingWithUrl:[NSURL URLWithString:@"https://hearthis.at/allindiandjsclub/nashe-si-chad-gayi-dj-shouki-dj-ashmac-remix/listen/?s=gV7"]];
}

- (IBAction)switches:(UISwitch*)sender
{
    [_playerView configureEQ:sender.isOn];
}

- (IBAction)sliderChange:(UISlider*)sender
{
    NSLog(@"%ld:%f",(long)sender.tag,sender.value);
    
    [_playerView adjustEQ:sender.value andPosition:sender.tag];
}

- (void)didPlayingWithUrl:(NSURL*)uri
{
    if(_playerView)
    {
        [_playerView clean];
        
        _playerView = nil;
    }
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    _playerView = [[GUIPlayerView alloc] initWithFrame:CGRectMake(0, 64, width, width * 9.0f / 16.0f)];
    
    [_playerView setDelegate:self];
    
    
    if(uri)
    {
        [_playerView setVideoURL:uri];
        
        [_playerView prepareAndPlayAutomatically:YES];
    }
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
