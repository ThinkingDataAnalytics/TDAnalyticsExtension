//
//  TDAnalyticsExtensionConfig.h
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/9/13.
//

#import <Foundation/Foundation.h>

#if __has_include(<ThinkingDataAnalyticsExtension/TDAnalyticsExtensionConstPublic.h>)
#import <ThinkingDataAnalyticsExtension/TDAnalyticsExtensionConstPublic.h>
#else
#import "TDAnalyticsExtensionConstPublic.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface TDAnalyticsExtensionConfig : NSObject
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *serverUrl;
/// 0 is Disable automatic flushing.
@property (nonatomic, assign) NSTimeInterval flushTimeInterval;
@property (nonatomic, assign) NSInteger bufferSize;

@end

NS_ASSUME_NONNULL_END
