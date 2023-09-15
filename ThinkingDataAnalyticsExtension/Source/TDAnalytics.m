//
//  TDAnalytics.m
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/9/13.
//

#import "TDAnalytics.h"
#import "TDAnalyticsConfig.h"
#import "TDAnalyticsSendService.h"
#import "TDExtensionDeviceInfo.h"

@interface TDAnalytics ()
@property (nonatomic, strong) TDAnalyticsConfig *config;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) TDAnalyticsSendService *sendService;
@property (nonatomic, copy) NSString *accountId;
@property (nonatomic, copy) NSString *distinctId;

@end

static NSMutableDictionary<NSString *, TDAnalytics *> * g_SDK_instances = nil;
static dispatch_queue_t g_track_queue = nil;

static const char * K_TD_ANALYTICS_TRACK_QUEUE = "cn.thinkingdata.TDAnalyticsExtension.track";

@implementation TDAnalytics

/**
 Set the distinct ID to replace the default UUID distinct ID.
 @param distinctId distinctId
 */
+ (void)setDistinctId:(NSString *)distinctId {
    TDAnalytics *analytics = [TDAnalytics defaultInstance];
    analytics.distinctId = distinctId;
}

/**
 Get distinct ID: The #distinct_id value in the reported data.
 
 @return distinctId
 */
+ (NSString *)getDistinctId {
    TDAnalytics *analytics = [TDAnalytics defaultInstance];
    return analytics.distinctId;
}

/**
 Set the account ID. Each setting overrides the previous value. Login events will not be uploaded.
 @param accountId accountId
 */
+ (void)login:(NSString *)accountId {
    TDAnalytics *analytics = [TDAnalytics defaultInstance];
    analytics.accountId = accountId;
}

/**
 Clearing the account ID will not upload user logout events.
 */
+ (void)logout {
    TDAnalytics *analytics = [TDAnalytics defaultInstance];
    analytics.accountId = nil;
}

+ (void)startWithAppId:(NSString *)appId serverUrl:(NSString *)serverUrl {
    TDAnalyticsConfig *config = [[TDAnalyticsConfig alloc] init];
    config.appId = appId;
    config.serverUrl = serverUrl;
    config.flushTimeInterval = 0;
    
    [self startWithConfig:config];
}

+ (void)startWithConfig:(TDAnalyticsConfig *)config {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_SDK_instances = [NSMutableDictionary dictionary];
        g_track_queue = dispatch_queue_create(K_TD_ANALYTICS_TRACK_QUEUE, DISPATCH_QUEUE_SERIAL);
    });
    
    NSString *appId = config.appId;
    NSString *receiverUrl = config.serverUrl;
    
    BOOL validateAppId = appId && [appId isKindOfClass:NSString.class] && appId.length;
    BOOL validateReceiverUrl = receiverUrl && [receiverUrl isKindOfClass:NSString.class] && receiverUrl.length;
    if (!(validateAppId && validateReceiverUrl)) {
        NSString *msg = @"[ThinkingData][Error] appId, serverUrl is con't be nil.";
        NSAssert(NO, msg);
        NSLog(@"%@", msg);
        return;
    }
    
    TDAnalytics *analytics = [TDAnalytics instanceWithAppID:config.appId];
    if (analytics) {
        return;
    }
    analytics = [[TDAnalytics alloc] init];
    g_SDK_instances[config.appId] = analytics;
    
    analytics.config = config;
    
    TDAnalyticsSendService *sendService = [[TDAnalyticsSendService alloc] initWithAppId:config.appId receiverUrl:config.serverUrl];
    [sendService setupSDKMode:TDModeNormal];
    [sendService setupBufferSize:config.bufferSize];
    [sendService setupTrackQueue:g_track_queue];
    analytics.sendService = sendService;
    
    if (config.flushTimeInterval > 0) {
        __weak typeof(analytics) weakInstance = analytics;
        NSTimer *timer = [NSTimer timerWithTimeInterval:config.flushTimeInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
            [weakInstance innerFlush];
        }];
        analytics.timer = timer;
    }
}

+ (void)track:(NSString *)eventName properties:(NSDictionary *)properties {
    TDAnalytics *analytics = [TDAnalytics defaultInstance];
    if (eventName && [eventName isKindOfClass:NSString.class] && eventName.length > 0) {
        [analytics innerTrackEvent:eventName type:@"track" properties:properties];
    } else {
        NSLog(@"[ThinkingData][Error] Event name is unavailable");
    }
}

+ (void)close {
    TDAnalytics *analytics = [TDAnalytics defaultInstance];
    [analytics.timer invalidate];
    [analytics innerClose];
}

//MARK: - Action

- (void)timerAction:(NSTimer *)timer {
    [self innerFlush];
}

//MARK: - Private methods

+ (void)flush {
    TDAnalytics *analytics = [TDAnalytics defaultInstance];
    [analytics innerFlush];
}

+ (TDAnalytics * _Nullable)defaultInstance {
    return [TDAnalytics instanceWithAppID:nil];
}

+ (TDAnalytics * _Nullable)instanceWithAppID:(NSString * _Nullable)appId {
    if (!appId) {
        NSArray<NSString *> *allKeys = g_SDK_instances.allKeys;
        return [g_SDK_instances objectForKey:allKeys.firstObject];
    }
    return g_SDK_instances[appId];
}

- (void)innerTrackEvent:(NSString *)eventName type:(NSString *)type properties:(NSDictionary *)properties {
    NSMutableDictionary *eventDict = [NSMutableDictionary dictionary];
    
    if (self.accountId.length || self.distinctId.length) {
        if (self.accountId) {
            eventDict[@"#account_id"] = self.accountId;
        }
        if (self.distinctId) {
            eventDict[@"#distinct_id"] = self.distinctId;
        }
    } else {
        NSString *errMsg = @"'accountId' and 'distinctId' cannot be empty at the same time.";
        NSAssert(NO, errMsg);
        NSLog(@"[ThinkingData][Error] %@", errMsg);
        return;
    }
    eventDict[@"#event_name"] = eventName;
    NSDictionary *presetProperties = [TDExtensionDeviceInfo presetInfo];
    NSMutableDictionary *customProperties = [NSMutableDictionary dictionaryWithDictionary:presetProperties];
    [customProperties addEntriesFromDictionary:properties];

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    eventDict[@"#time"] = [fmt stringFromDate:[NSDate date]];
    eventDict[@"#uuid"] = [NSUUID UUID].UUIDString;
    eventDict[@"#type"] = type;
    eventDict[@"properties"] = customProperties;
    
    dispatch_async(g_track_queue, ^{
        [self.sendService sendEvent:eventDict];
    });
}

- (void)innerFlush {
    dispatch_async(g_track_queue, ^{
        [self.sendService flush];
    });
}

- (void)innerClose {
    dispatch_async(g_track_queue, ^{
        [self.sendService closeService];
    });
}

@end
