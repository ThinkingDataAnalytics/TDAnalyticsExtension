//
//  TDAnalyticsExtensionSendService.m
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/9/13.
//

#import "TDAnalyticsExtensionSendService.h"
#import "TDExtensionNetwork.h"
#import "TDExtensionDeviceInfo.h"

static NSUInteger const K_BUFFER_SIZE = 0;
static const char * K_TD_ANALYTICS_NETWORK_QUEUE = "cn.thinkingdata.TDAnalyticsExtensionExtension.network";
static dispatch_queue_t g_network_queue = nil;

@interface TDAnalyticsExtensionSendService ()
@property (nonatomic, assign) TDMode sdkMode;
@property (nonatomic, assign) NSInteger bufferSize;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *receiverUrl;
@property (nonatomic, strong) TDExtensionNetwork *network;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *buffer;
@property (nonatomic, assign) dispatch_queue_t trackQueue;

@end

@implementation TDAnalyticsExtensionSendService

+ (void)initialize {
    static dispatch_once_t ThinkingOnceToken;
    dispatch_once(&ThinkingOnceToken, ^{
        g_network_queue = dispatch_queue_create(K_TD_ANALYTICS_NETWORK_QUEUE, DISPATCH_QUEUE_SERIAL);
    });
}

- (instancetype)initWithAppId:(NSString *)appId receiverUrl:(NSString *)receiverUrl {
    if (self = [self init]) {
        self.appId = appId;
        self.receiverUrl = receiverUrl;
        self.sdkMode = TDModeNormal;
        self.bufferSize = K_BUFFER_SIZE;
        self.network = [[TDExtensionNetwork alloc] init];
        self.buffer = [[NSMutableArray alloc] init];
    }
    return self;
}

//MARK: - Public

- (void)setupSDKMode:(TDMode)mode {
    self.sdkMode = mode;
}

- (void)setupBufferSize:(NSInteger)bufferSize {
    if (bufferSize > 0) {
        self.bufferSize = bufferSize;
    }
}

- (void)setupTrackQueue:(dispatch_queue_t)trackQueue {
    self.trackQueue = trackQueue;
}

- (void)closeService {
    [self flush];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_sync(g_network_queue, ^{});
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)));
}

- (void)flush {
    NSArray *events = [self.buffer copy];
    [self.buffer removeAllObjects];
    [self sendNetwork:events completion:^(BOOL result) {
        if (result) {
            // Request success.
        } else {
            // Failed. Restore data to buffer
        }
    }];
}

- (void)sendEvent:(NSDictionary *)event {
    TDMode mode = self.sdkMode;
    if (mode == TDModeDebugOnly || mode == TDModeDebug) {
        dispatch_async(g_network_queue, ^{
            [self flushDebugEvent:event];
        });
        return;
    } else {
        NSLog(@"[ThinkingData] Enqueue data: %@", event);
        [self.buffer addObject:event];
    }
    NSInteger count = self.buffer.count;
    if (count >= self.bufferSize) {
        NSLog(@"[ThinkingData] Flush data when the cache is full. count: %ld, bufferSize: %ld", count, self.bufferSize);
        [self flush];
    }
}

- (void)flushDebugEvent:(NSDictionary *)event {
    // This feature is not available at this time
    NSString *deviceId = @"";
    
    int debugResult = [self.network flushDebugEvent:event withAppId:self.appId receiverUrl:self.receiverUrl deviceId:deviceId];
    if (debugResult == -1) {
        // Downgrade
        if (self.sdkMode == TDModeDebug) {
            dispatch_async(self.trackQueue, ^{
                [self.buffer addObject:event];
            });
            self.sdkMode = TDModeNormal;
        } else if (self.sdkMode == TDModeDebugOnly) {
            NSLog(@"[ThinkingData] The data will be discarded due to this device is not allowed to debug:%@", event);
        }
    }
    else if (debugResult == -2) {
        NSLog(@"[ThinkingData] Exception occurred when sending message to Server:%@", event);
        if (self.sdkMode == TDModeDebug) {
            dispatch_async(self.trackQueue, ^{
                [self.buffer addObject:event];
            });
        }
    }
}

/// Synchronize data asynchronously (synchronize data in the local database to TE)
/// Need to add this event to the serialQueue queue
/// In some scenarios, event warehousing and sending network requests happen at the same time. Event storage is performed in serialQueue, and data reporting is performed in networkQueue. To ensure that events are stored first, you need to add the reported data operation to serialQueue
- (void)sendNetwork:(NSArray *)events completion:(void(^)(BOOL result))completion {
    dispatch_async(g_network_queue, ^{
        BOOL result = [self.network flushEvents:events withAppId:self.appId receiverUrl:self.receiverUrl];
        if (completion) {
            completion(result);
        }
    });
}

@end
