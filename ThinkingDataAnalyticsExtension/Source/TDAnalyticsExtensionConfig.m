//
//  TDAnalyticsExtensionConfig.m
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/9/13.
//

#import "TDAnalyticsExtensionConfig.h"
#import "NSString+TDAnalyticsExtension.h"

@implementation TDAnalyticsExtensionConfig

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
