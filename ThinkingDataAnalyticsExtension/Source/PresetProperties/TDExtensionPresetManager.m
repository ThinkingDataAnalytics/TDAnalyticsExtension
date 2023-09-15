//
//  TDExtensionPresetManager.m
//  ThinkingDataPushExtension
//
//  Created by 杨雄 on 2023/7/4.
//

#import "TDExtensionPresetManager.h"
#import "TDExtensionPresetConst.h"

@interface TDExtensionPresetManager ()
@property (nonatomic, assign) BOOL disableInstallTime;
@property (nonatomic, assign) BOOL disableLib;
@property (nonatomic, assign) BOOL disableLibVersion;
@property (nonatomic, assign) BOOL disableRAM;
@property (nonatomic, assign) BOOL disableSystemLanguage;
@property (nonatomic, assign) BOOL disableZoneOffset;
@property (nonatomic, assign) BOOL disableDeviceId;
@property (nonatomic, assign) BOOL disableAppVersion;
@property (nonatomic, assign) BOOL disableSimulator;
@property (nonatomic, assign) BOOL disableDisk;
@property (nonatomic, assign) BOOL disableOS;
@property (nonatomic, assign) BOOL disableOSVersion;
@property (nonatomic, assign) BOOL disableScreenWidth;
@property (nonatomic, assign) BOOL disableCarrier;
@property (nonatomic, assign) BOOL disableNetworkType;
@property (nonatomic, assign) BOOL disableDeviceModel;
@property (nonatomic, assign) BOOL disableDeviceType;
@property (nonatomic, assign) BOOL disableScreenHeight;
@property (nonatomic, assign) BOOL disableBundleId;
@property (nonatomic, assign) BOOL disableManufacturer;

@end

@implementation TDExtensionPresetManager

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static TDExtensionPresetManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[TDExtensionPresetManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self readSwitchStateFromPlist];
    }
    return self;
}

- (void)readSwitchStateFromPlist {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *disPresetProperties = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ThinkingData"][@"TDDisPresetProperties"];
        if (disPresetProperties && [disPresetProperties.class isKindOfClass:[NSArray<NSString *> class]] && disPresetProperties.count) {
            self.disableInstallTime = [disPresetProperties containsObject:kTDExtensionPresetInstallTime];
            self.disableLib = [disPresetProperties containsObject:kTDExtensionPresetLib];
            self.disableLibVersion = [disPresetProperties containsObject:kTDExtensionPresetLibVersion];
            self.disableRAM = [disPresetProperties containsObject:kTDExtensionPresetRAM];
            self.disableSystemLanguage = [disPresetProperties containsObject:kTDExtensionPresetSystemLanguage];
            self.disableZoneOffset = [disPresetProperties containsObject:kTDExtensionPresetZoneOffset];
            self.disableDeviceId = [disPresetProperties containsObject:kTDExtensionPresetDeviceId];
            self.disableAppVersion = [disPresetProperties containsObject:kTDExtensionPresetAppVersion];
            self.disableSimulator = [disPresetProperties containsObject:kTDExtensionPresetSimulator];
            self.disableDisk = [disPresetProperties containsObject:kTDExtensionPresetDisk];
            self.disableOS = [disPresetProperties containsObject:kTDExtensionPresetOS];
            self.disableOSVersion = [disPresetProperties containsObject:kTDExtensionPresetOSVersion];
            self.disableScreenWidth = [disPresetProperties containsObject:kTDExtensionPresetScreenWidth];
            self.disableCarrier = [disPresetProperties containsObject:kTDExtensionPresetCarrier];
            self.disableNetworkType = [disPresetProperties containsObject:kTDExtensionPresetNetwork];
            self.disableDeviceModel = [disPresetProperties containsObject:kTDExtensionPresetDeviceModel];
            self.disableDeviceType = [disPresetProperties containsObject:kTDExtensionPresetDeviceType];
            self.disableScreenHeight = [disPresetProperties containsObject:kTDExtensionPresetScreenHeight];
            self.disableBundleId = [disPresetProperties containsObject:kTDExtensionPresetBundleId];
            self.disableManufacturer = [disPresetProperties containsObject:kTDExtensionPresetManufacturer];
        }
    });
}

@end
