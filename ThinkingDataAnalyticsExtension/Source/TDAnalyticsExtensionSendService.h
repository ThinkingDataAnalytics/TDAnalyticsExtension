//
//  TDAnalyticsExtensionSendService.h
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/9/13.
//

#import <Foundation/Foundation.h>
#import "TDAnalyticsExtensionConstPublic.h"

NS_ASSUME_NONNULL_BEGIN

@interface TDAnalyticsExtensionSendService : NSObject

- (instancetype)initWithAppId:(NSString *)appId receiverUrl:(NSString *)receiverUrl;

- (void)setupSDKMode:(TDMode)mode;
- (void)setupBufferSize:(NSInteger)bufferSize;
- (void)setupTrackQueue:(dispatch_queue_t)trackQueue;

- (void)sendEvent:(NSDictionary *)event;

- (void)flush;

- (void)closeService;

@end

NS_ASSUME_NONNULL_END
