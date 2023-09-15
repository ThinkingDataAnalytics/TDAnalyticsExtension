//
//  TDAnalyticsConfig.m
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/9/13.
//

#import "TDAnalyticsConfig.h"
#import "NSString+TDAnalytics.h"

@implementation TDAnalyticsConfig

//MARK: - setter

- (void)setAppId:(NSString *)appId {
    NSString *keyName = @"appId";
    
    [self willChangeValueForKey:keyName];
    _appId = [appId td_trim];
    [self didChangeValueForKey:keyName];
}

- (void)setServerUrl:(NSString *)serverUrl {
    NSString *keyName = @"serverUrl";
    
    [self willChangeValueForKey:keyName];
    _serverUrl = [serverUrl td_trim];
    [self didChangeValueForKey:keyName];
}

@end
