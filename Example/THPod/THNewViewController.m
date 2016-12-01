//
//  THNewViewController.m
//  THPod
//
//  Created by Thanh Hai Tran on 11/29/16.
//  Copyright © 2016 tthufo. All rights reserved.
//

#import "THNewViewController.h"

@interface THNewViewController ()
{
    IBOutlet GUIPlayerView * playerView;
}
@end

@implementation THNewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self didPlayingWithUrl:[NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/VfE_html5.mp4"]];
}

- (void)didPlayingWithUrl:(NSURL*)uri
{
    if(playerView)
    {
        [playerView clean];
        
        playerView = nil;
    }
    
    NSMutableDictionary * playingData = [@{@"repeat":@"2", @"shuffle":@"0",@"thumb":[UIImage imageNamed:@"Untitled"]} mutableCopy];

    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    playerView = [[GUIPlayerView alloc] initWithFrame:CGRectMake(0, 64, width, width * 9.0f / 16.0f) andInfo:playingData];
    
    [playerView setDelegate:self];
    
    if(uri)
    {
        [playerView setVideoURL:uri];
        
        [playerView prepareAndPlayAutomatically:YES];
    }
    
    [self.view addSubview: playerView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
