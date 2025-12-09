//
//  TDAnalyticsExtensionConstPublic.h
//  Pods
//
//  Created by 杨雄 on 2023/9/13.
//

#ifndef TDAnalyticsExtensionConstPublic_h
#define TDAnalyticsExtensionConstPublic_h

#import <Foundation/Foundation.h>

static NSString * const TD_LIB_NAME = @"AppExtension";
static NSString * const TD_LIB_VERSION = @"1.1.2";

typedef NS_ENUM(NSUInteger, TDMode) {
    /// Send data to TE
    TDModeNormal = 0,

    /// Enable DebugOnly Mode, Data is not persisted
    TDModeDebugOnly = 1 << 0,
    
    /// Enable Debug Mode，Data will persist
    TDModeDebug = 1 << 1,
};

#endif /* TDAnalyticsExtensionConstPublic_h */
