//
//  TDExtensionDeviceInfo.m
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/7/3.
//

#import "TDExtensionDeviceInfo.h"
#import <ThinkingDataCore/ThinkingDataCore.h>
#import "TDExtensionPresetConst.h"
#import "TDAnalyticsExtensionConstPublic.h"

@interface TDExtensionDeviceInfo ()

@end

@implementation TDExtensionDeviceInfo

//MARK: - public methods

+ (NSDictionary *)presetInfo {
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];

    if (!TDCorePresetDisableConfig.disableLib) {
        mutableDict[kTDExtensionPresetLib] = TD_LIB_NAME;
    }
    
    if (!TDCorePresetDisableConfig.disableLibVersion) {
        mutableDict[kTDExtensionPresetLibVersion] = TD_LIB_VERSION;
    }
    
    mutableDict[kTDExtensionPresetZoneOffset] = @([self timeZoneOffset]);
    
    NSDictionary *corePreset = [TDCorePresetProperty allPresetProperties];
    if ([corePreset isKindOfClass:NSDictionary.class]) {
        [mutableDict addEntriesFromDictionary:corePreset];
    }
    return mutableDict;
}

+ (NSInteger)timeZoneOffset {
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSInteger sourceGMTOffset = [timeZone secondsFromGMTForDate:[NSDate date]];
    return sourceGMTOffset / 3600;
}

@end
