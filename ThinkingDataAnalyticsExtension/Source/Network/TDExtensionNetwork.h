//
//  TDExtensionNetwork.h
//  ThinkingDataPushExtension
//
//  Created by 杨雄 on 2023/7/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TDExtensionNetwork : NSObject

+ (instancetype)shareInstance;

- (BOOL)flushEvents:(NSArray<NSDictionary *> *)recordArray withAppId:(NSString *)appId receiverUrl:(NSString *)receiverUrl;

- (int)flushDebugEvent:(NSDictionary *)record withAppId:(NSString *)appId receiverUrl:(NSString *)receiverUrl deviceId:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END
