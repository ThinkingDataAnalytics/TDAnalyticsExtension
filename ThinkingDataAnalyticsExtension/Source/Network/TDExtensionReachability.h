//
//  TDExtensionReachability.h
//  ThinkingDataPushExtension
//
//  Created by 杨雄 on 2023/7/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TDExtensionReachability : NSObject

+ (instancetype)shareInstance;

- (NSString *)networkState;

@end

NS_ASSUME_NONNULL_END
