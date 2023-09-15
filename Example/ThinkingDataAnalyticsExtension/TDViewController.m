//
//  TDViewController.m
//  ThinkingDataAnalyticsExtension
//
//  Created by wangweilucky on 09/12/2023.
//  Copyright (c) 2023 wangweilucky. All rights reserved.
//

#import "TDViewController.h"
#import <ThinkingDataAnalyticsExtension/ThinkingDataAnalyticsExtension.h>

@interface TDViewController ()

@end

@implementation TDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSString *appId = @"appId";
    NSString *serverUrl = @"serverUrl";
    [TDAnalytics startWithAppId:appId serverUrl:serverUrl];
    
    [TDAnalytics login:@"user_login_id_1"];
    [TDAnalytics track:@"login" properties:@{@"key_1": @"value_1"}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
