//
//  TDAnalyticsExtension.m
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/9/13.
//

#import "TDAnalyticsExtension.h"
#import "TDAnalyticsExtensionConfig.h"
#import "TDAnalyticsExtensionSendService.h"
#import "TDExtensionDeviceInfo.h"
#import "NSString+TDAnalyticsExtension.h"
#import <ThinkingDataCore/ThinkingDataCore.h>

@interface TDAnalyticsExtension ()
@property (nonatomic, strong) TDAnalyticsExtensionConfig *config;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) TDAnalyticsExtensionSendService *sendService;
@property (atomic, copy) NSString *accountId;
@property (atomic, copy) NSString *distinctId;

@end

static NSMutableDictionary<NSString *, TDAnalyticsExtension *> * g_SDK_instances = nil;
static dispatch_queue_t g_track_queue = nil;

static const char * K_TD_ANALYTICS_TRACK_QUEUE = "cn.thinkingdata.TDAnalyticsExtensionExtension.track";

@implementation TDAnalyticsExtension

/**
 Set the distinct ID to replace the default UUID distinct ID.
 @param distinctId distinctId
 */
+ (void)setDistinctId:(NSString *)distinctId {
    TDAnalyticsExtension *analytics = [TDAnalyticsExtension defaultInstance];
    if ([distinctId isKindOfClass:NSString.class] && distinctId.length > 0) {
        analytics.distinctId = distinctId;
        [TDAnalyticsExtension storeDistinctId:distinctId appId:analytics.config.appId];
    } else {
        NSLog(@"[ThinkingData] distinct id con't be nil");
    }
}

/**
 Get distinct ID: The #distinct_id value in the reported data.
 
 @return distinctId
 */
+ (NSString *)getDistinctId {
    TDAnalyticsExtension *analytics = [TDAnalyticsExtension defaultInstance];
    return analytics.distinctId;
}

/**
 Set the account ID. Each setting overrides the previous value. Login events will not be uploaded.
 @param accountId accountId
 */
+ (void)login:(NSString *)accountId {
    TDAnalyticsExtension *analytics = [TDAnalyticsExtension defaultInstance];
    analytics.accountId = accountId;
    [TDAnalyticsExtension storeDistinctId:accountId appId:analytics.config.appId];
}

/**
 Clearing the account ID will not upload user logout events.
 */
+ (void)logout {
    TDAnalyticsExtension *analytics = [TDAnalyticsExtension defaultInstance];
    analytics.accountId = nil;
    [TDAnalyticsExtension storeDistinctId:nil appId:analytics.config.appId];
}

+ (void)startWithAppId:(NSString *)appId serverUrl:(NSString *)serverUrl {
    TDAnalyticsExtensionConfig *config = [[TDAnalyticsExtensionConfig alloc] init];
    config.appId = appId;
    config.serverUrl = serverUrl;
    config.flushTimeInterval = 0;
    
    [self startWithConfig:config];
}

+ (void)startWithConfig:(TDAnalyticsExtensionConfig *)config {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_SDK_instances = [NSMutableDictionary dictionary];
        g_track_queue = dispatch_queue_create(K_TD_ANALYTICS_TRACK_QUEUE, DISPATCH_QUEUE_SERIAL);
    });
    
    NSString *appId = config.appId;
    NSString *receiverUrl = config.serverUrl;
    
    if ([appId isKindOfClass:NSString.class] && [receiverUrl isKindOfClass:NSString.class]) {
        appId = [appId td_trim];
        receiverUrl = [receiverUrl td_formatUrlString];
    } else {
        NSString *msg = @"[ThinkingData][Error] appId, serverUrl is con't be nil.";
        NSAssert(NO, msg);
        NSLog(@"%@", msg);
        return;
    }
    
    if (!(appId.length > 0 && receiverUrl.length > 0)) {
        NSString *msg = @"[ThinkingData][Error] appId, serverUrl format is error.";
        NSAssert(NO, msg);
        NSLog(@"%@", msg);
        return;
    }
    config.appId = appId;
    config.serverUrl = receiverUrl;
    
    TDAnalyticsExtension *analytics = [TDAnalyticsExtension instanceWithAppID:config.appId];
    if (analytics) {
        return;
    }
    analytics = [[TDAnalyticsExtension alloc] init];
    
    NSString *distinctId = [TDAnalyticsExtension distinctIdInStoreWithAppId:appId];
    if (!distinctId) {
        distinctId = [TDCoreDeviceInfo deviceId];
        [TDAnalyticsExtension storeDistinctId:distinctId appId:appId];
    }    
    analytics.distinctId = distinctId;
    
    dispatch_sync(g_track_queue, ^{
        g_SDK_instances[config.appId] = analytics;
    });
    
    analytics.config = config;
    
    TDAnalyticsExtensionSendService *sendService = [[TDAnalyticsExtensionSendService alloc] initWithAppId:config.appId receiverUrl:config.serverUrl];
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
    TDAnalyticsExtension *analytics = [TDAnalyticsExtension defaultInstance];
    if (eventName && [eventName isKindOfClass:NSString.class] && eventName.length > 0) {
        [analytics innerTrackEvent:eventName type:@"track" properties:properties];
    } else {
        NSLog(@"[ThinkingData][Error] Event name is unavailable");
    }
}

+ (void)close {
    TDAnalyticsExtension *analytics = [TDAnalyticsExtension defaultInstance];
    [analytics.timer invalidate];
    [analytics innerClose];
}

//MARK: - Action

- (void)timerAction:(NSTimer *)timer {
    [self innerFlush];
}

//MARK: - Private methods

+ (void)flush {
    TDAnalyticsExtension *analytics = [TDAnalyticsExtension defaultInstance];
    [analytics innerFlush];
}

+ (TDAnalyticsExtension * _Nullable)defaultInstance {
    return [TDAnalyticsExtension instanceWithAppID:nil];
}

+ (TDAnalyticsExtension * _Nullable)instanceWithAppID:(NSString * _Nullable)appId {
    __block TDAnalyticsExtension *analytics = nil;
    
    void(^block)(void) = ^{
        if (appId) {
            analytics = g_SDK_instances[appId];
        } else {
            NSArray<NSString *> *allKeys = g_SDK_instances.allKeys;
            analytics = [g_SDK_instances objectForKey:allKeys.firstObject];
        }
    };
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(g_track_queue)) {
        block();
    } else {
        dispatch_sync(g_track_queue, block);
    }
    
    return analytics;
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

    eventDict[@"#time"] = [NSDate date];
    eventDict[@"#uuid"] = [NSUUID UUID].UUIDString;
    eventDict[@"#type"] = type;
    eventDict[@"properties"] = customProperties;
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    fmt.timeZone = [NSTimeZone localTimeZone];
    fmt.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    eventDict = [TDJSONUtil formatDateWithFormatter:fmt dict:eventDict];

    
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

+ (void)storeAccountId:(NSString *)accountId appId:(NSString *)appId {
    @synchronized (TDAnalyticsExtension.class) {
        if ([appId isKindOfClass:NSString.class]) {
            NSString *key = [NSString stringWithFormat:@"%@_account_id", appId];
            if (accountId == nil) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
            } else {
                [[NSUserDefaults standardUserDefaults] setObject:accountId forKey:key];
            }
        }
    }
}

+ (void)storeDistinctId:(NSString *)distinctId appId:(NSString *)appId {
    @synchronized (TDAnalyticsExtension.class) {
        if ([appId isKindOfClass:NSString.class]) {
            NSString *key = [NSString stringWithFormat:@"%@_distinct_id", appId];
            if (distinctId == nil) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
            } else {
                [[NSUserDefaults standardUserDefaults] setObject:distinctId forKey:key];
            }
        }
    }
}

+ (nullable NSString *)accountIdInStoreWithAppId:(NSString *)appId {
    NSString *value = nil;
    @synchronized (TDAnalyticsExtension.class) {
        if ([appId isKindOfClass:NSString.class]) {
            NSString *key = [NSString stringWithFormat:@"%@_account_id", appId];
            value = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        }
    }
    return value;
}

+ (nullable NSString *)distinctIdInStoreWithAppId:(NSString *)appId {
    NSString *value = nil;
    @synchronized (TDAnalyticsExtension.class) {
        if ([appId isKindOfClass:NSString.class]) {
            NSString *key = [NSString stringWithFormat:@"%@_distinct_id", appId];
            value = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        }
    }
    return value;
}

@end
