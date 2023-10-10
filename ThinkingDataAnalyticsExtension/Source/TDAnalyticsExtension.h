//
//  TDAnalyticsExtension.h
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/9/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TDAnalyticsExtension : NSObject

/// Init SDK
/// @param appId appId in TE
/// @param serverUrl serverUrl in TE
+ (void)startWithAppId:(NSString *)appId serverUrl:(NSString *)serverUrl;

/// Set the distinct ID
/// @param distinctId distinctId
+ (void)setDistinctId:(NSString *)distinctId;

/// Set the account ID. Each setting overrides the previous value. Login events will not be uploaded.
/// @param accountId accountId
+ (void)login:(NSString *)accountId;

/// Track Events
/// @param eventName event name
/// @param properties properties
+ (void)track:(NSString *)eventName properties:(nullable NSDictionary *)properties;

/// Close SDK
+ (void)close;

@end

NS_ASSUME_NONNULL_END
