//
//  TDExtensionPresetManager.h
//  ThinkingDataPushExtension
//
//  Created by 杨雄 on 2023/7/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TDExtensionPresetManager : NSObject

@property (nonatomic, assign, readonly) BOOL disableInstallTime;
@property (nonatomic, assign, readonly) BOOL disableLib;
@property (nonatomic, assign, readonly) BOOL disableLibVersion;
@property (nonatomic, assign, readonly) BOOL disableRAM;
@property (nonatomic, assign, readonly) BOOL disableSystemLanguage;
@property (nonatomic, assign, readonly) BOOL disableZoneOffset;
@property (nonatomic, assign, readonly) BOOL disableDeviceId;
@property (nonatomic, assign, readonly) BOOL disableAppVersion;
@property (nonatomic, assign, readonly) BOOL disableSimulator;
@property (nonatomic, assign, readonly) BOOL disableDisk;
@property (nonatomic, assign, readonly) BOOL disableOS;
@property (nonatomic, assign, readonly) BOOL disableOSVersion;
@property (nonatomic, assign, readonly) BOOL disableScreenWidth;
@property (nonatomic, assign, readonly) BOOL disableCarrier;
@property (nonatomic, assign, readonly) BOOL disableNetworkType;
@property (nonatomic, assign, readonly) BOOL disableDeviceModel;
@property (nonatomic, assign, readonly) BOOL disableDeviceType;
@property (nonatomic, assign, readonly) BOOL disableScreenHeight;
@property (nonatomic, assign, readonly) BOOL disableBundleId;
@property (nonatomic, assign, readonly) BOOL disableManufacturer;

+ (instancetype)shareInstance;

@end

NS_ASSUME_NONNULL_END
