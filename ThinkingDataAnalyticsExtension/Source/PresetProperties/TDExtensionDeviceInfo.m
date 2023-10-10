//
//  TDExtensionDeviceInfo.m
//  ThinkingDataAnalyticsExtension
//
//  Created by 杨雄 on 2023/7/3.
//

#import <UIKit/UIKit.h>
#import "TDExtensionDeviceInfo.h"
#import "TDAnalyticsExtensionConstPublic.h"
#import "TDExtensionPresetManager.h"
#import "TDExtensionPresetConst.h"
#import "TDExtensionReachability.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <sys/utsname.h>
#include <mach/mach.h>
#import <sys/sysctl.h>

#define TD_PM_UNIT_KB 1024.0
#define TD_PM_UNIT_MB (1024.0 * TD_PM_UNIT_KB)
#define TD_PM_UNIT_GB (1024.0 * TD_PM_UNIT_MB)

#if TARGET_OS_IOS
static CTTelephonyNetworkInfo *__td_TelephonyNetworkInfo;
#endif

@interface TDExtensionDeviceInfo ()

@end

@implementation TDExtensionDeviceInfo

+ (void)load {
#if TARGET_OS_IOS
    __td_TelephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
#endif
}

//MARK: - public methods

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static TDExtensionDeviceInfo *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[TDExtensionDeviceInfo alloc] init];
    });
    return instance;
}

+ (NSDictionary *)presetInfo {
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];

    TDExtensionPresetManager *presetManager = [TDExtensionPresetManager shareInstance];
    
    if (!presetManager.disableLib) {
        mutableDict[kTDExtensionPresetLib] = TD_LIB_NAME;
    }
    
    if (!presetManager.disableAppVersion) {
        mutableDict[kTDExtensionPresetAppVersion] = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    }
    
    if (!presetManager.disableBundleId) {
        mutableDict[kTDExtensionPresetBundleId] = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    }
    
    if (!presetManager.disableLibVersion) {
        mutableDict[kTDExtensionPresetLibVersion] = TD_LIB_VERSION;
    }
    NSString *installTime = [self installTime];
    if (!presetManager.disableInstallTime && installTime) {
        mutableDict[kTDExtensionPresetInstallTime] = installTime;
    }
    if (!presetManager.disableZoneOffset) {
        mutableDict[kTDExtensionPresetZoneOffset] = @([self timeZoneOffset]);
    }
    if (!presetManager.disableNetworkType) {
        mutableDict[kTDExtensionPresetNetwork] = [TDExtensionReachability shareInstance].networkState;
    }
  
#if TARGET_OS_IOS
    if (!presetManager.disableCarrier) {
        CTCarrier *carrier = nil;
        NSString *carrierName = @"";
    #ifdef __IPHONE_12_0
            if (@available(iOS 12.1, *)) {
                NSArray *carrierKeysArray = [__td_TelephonyNetworkInfo.serviceSubscriberCellularProviders.allKeys sortedArrayUsingSelector:@selector(compare:)];
                carrier = __td_TelephonyNetworkInfo.serviceSubscriberCellularProviders[carrierKeysArray.firstObject];
                if (!carrier.mobileNetworkCode) {
                    carrier = __td_TelephonyNetworkInfo.serviceSubscriberCellularProviders[carrierKeysArray.lastObject];
                }
            }
    #endif
        
        if (!carrier) {
            carrier = [__td_TelephonyNetworkInfo subscriberCellularProvider];
        }
        
        // System characteristics, when the SIM is not installed, the carrierName also has a value, here additionally add the judgment of whether MCC and MNC have values
        // MCC, MNC, and isoCountryCode are nil when no SIM card is installed and not within the cellular service range
        if (carrier.carrierName &&
            carrier.carrierName.length > 0 &&
            carrier.mobileNetworkCode &&
            carrier.mobileNetworkCode.length > 0) {
            carrierName = carrier.carrierName;
        }
        mutableDict[kTDExtensionPresetCarrier] = carrierName;
    }
#endif
    
    if (!presetManager.disableManufacturer) {
        mutableDict[kTDExtensionPresetManufacturer] = @"Apple";
    }
   

#if TARGET_OS_IOS
    if (!presetManager.disableDeviceModel) {
        mutableDict[kTDExtensionPresetDeviceModel] = [self deviceModelName];        
    }
    
    if (!presetManager.disableOS) {
        mutableDict[kTDExtensionPresetOS] = @"iOS";
    }
    
    if (!presetManager.disableOSVersion) {
        UIDevice *device = [UIDevice currentDevice];
        mutableDict[kTDExtensionPresetOSVersion] = [device systemVersion];
    }
    
    if (!presetManager.disableScreenWidth) {
        CGSize size = [UIScreen mainScreen].bounds.size;
        mutableDict[kTDExtensionPresetScreenWidth] = @((NSInteger)size.width);
    }
    
    if (!presetManager.disableScreenHeight) {
        CGSize size = [UIScreen mainScreen].bounds.size;
        mutableDict[kTDExtensionPresetScreenHeight] = @((NSInteger)size.height);
    }
    
    if (!presetManager.disableDeviceType) {
        NSString *name = @"unknown";
        switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
            case UIUserInterfaceIdiomPad: {
                name = @"iPad";
            } break;
            case UIUserInterfaceIdiomPhone: {
                name = @"iPhone";
            } break;
            case UIUserInterfaceIdiomMac: {
                name = @"Mac";
            } break;
            default:
                break;
        }
        mutableDict[kTDExtensionPresetDeviceType] = name;
    }
#endif
    if (!presetManager.disableSystemLanguage) {
        NSString *preferredLanguages = [[NSLocale preferredLanguages] firstObject];
        if (preferredLanguages && preferredLanguages.length > 0) {
            mutableDict[kTDExtensionPresetSystemLanguage] = [[preferredLanguages componentsSeparatedByString:@"-"] firstObject];;
        }
    }
    
    if (!presetManager.disableRAM) {
        NSString *ram = [NSString stringWithFormat:@"%.1f/%.1f",
                         [self td_pm_func_getFreeMemory] * 1.0 / TD_PM_UNIT_GB,
                         [self td_pm_func_getRamSize] * 1.0 / TD_PM_UNIT_GB];
        if (ram && ram.length) {
            mutableDict[kTDExtensionPresetRAM] = ram;
        }
    }
    
    if (!presetManager.disableDisk) {
        NSString *disk = [NSString stringWithFormat:@"%.1f/%.1f",
                          [self td_get_disk_free_size]*1.0/TD_PM_UNIT_GB,
                          [self td_get_storage_size]*1.0/TD_PM_UNIT_GB];
        if (disk && disk.length) {
            mutableDict[kTDExtensionPresetDisk] = disk;
        }
    }
    
    if (!presetManager.disableSimulator) {
        
#ifdef TARGET_OS_IPHONE
    #if TARGET_IPHONE_SIMULATOR
        mutableDict[kTDExtensionPresetSimulator] = @(YES);
    #elif TARGET_OS_SIMULATOR
        mutableDict[kTDExtensionPresetSimulator] = @(YES);
    #else
        mutableDict[kTDExtensionPresetSimulator] = @(NO);
    #endif
#else
        mutableDict[kTDExtensionPresetSimulator] = @(YES);
#endif
    }
    
    return mutableDict;
}

//MARK: - private methods

+ (NSString * _Nullable)installTime {
    NSURL *urlToDocumentsFolder = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    __autoreleasing NSError *error;
    NSDate *installDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:urlToDocumentsFolder.path error:&error] objectForKey:NSFileCreationDate];
    if (error) {
        return nil;
    }
    NSString *timeString = [self formatDate:installDate WithTimeZone:[NSTimeZone localTimeZone] formatString: @"yyyy-MM-dd HH:mm:ss.SSS"];
    if (timeString && [timeString isKindOfClass:[NSString class]] && timeString.length){
        return timeString;
    }
    return nil;
}

+ (NSString *)formatDate:(NSDate *)date WithTimeZone:(NSTimeZone *)timeZone formatString:(NSString *)formatString {
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = formatString;
    timeFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    timeFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    timeFormatter.timeZone = timeZone;
    return [timeFormatter stringFromDate:date];
}

+ (NSInteger)timeZoneOffset {
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSInteger sourceGMTOffset = [timeZone secondsFromGMTForDate:[NSDate date]];
    return sourceGMTOffset / 3600;
}

+ (NSString *)deviceModelName {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5";
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone 5c";
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone 5c";
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone 5s";
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone 5s";
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone 6s";
    if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone 6s Plus";
    if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhone SE";
    if ([platform isEqualToString:@"iPhone9,1"]) return @"iPhone 7";
    if ([platform isEqualToString:@"iPhone9,2"]) return @"iPhone 7 Plus";
    if ([platform isEqualToString:@"iPod1,1"])   return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])   return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])   return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])   return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])   return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad 1G";
    if ([platform isEqualToString:@"iPad2,1"])   return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,2"])   return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,3"])   return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,4"])   return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,5"])   return @"iPad Mini 1G";
    if ([platform isEqualToString:@"iPad2,6"])   return @"iPad Mini 1G";
    if ([platform isEqualToString:@"iPad2,7"])   return @"iPad Mini 1G";
    if ([platform isEqualToString:@"iPad3,1"])   return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,2"])   return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,3"])   return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,4"])   return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,5"])   return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,6"])   return @"iPad 4";
    if ([platform isEqualToString:@"iPad4,1"])   return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,2"])   return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,3"])   return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,4"])   return @"iPad Mini 2G";
    if ([platform isEqualToString:@"iPad4,5"])   return @"iPad Mini 2G";
    if ([platform isEqualToString:@"iPad4,6"])   return @"iPad Mini 2G";
    if ([platform isEqualToString:@"i386"])      return @"iPhone Simulator";
    if ([platform isEqualToString:@"x86_64"])    return @"iPhone Simulator";
    return platform;
}

#pragma mark - memory

+ (int64_t)td_pm_func_getFreeMemory {
    size_t length = 0;
    int mib[6] = {0};
    
    int pagesize = 0;
    mib[0] = CTL_HW;
    mib[1] = HW_PAGESIZE;
    length = sizeof(pagesize);
    if (sysctl(mib, 2, &pagesize, &length, NULL, 0) < 0){
        return -1;
    }
    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
    vm_statistics_data_t vmstat;
    if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmstat, &count) != KERN_SUCCESS){
        return -1;
    }
    
    int64_t freeMem = vmstat.free_count * pagesize;
    int64_t inactiveMem = vmstat.inactive_count * pagesize;
    return freeMem + inactiveMem;
}

+ (int64_t)td_pm_func_getRamSize{
    int mib[2];
    size_t length = 0;
    
    mib[0] = CTL_HW;
    mib[1] = HW_MEMSIZE;
    long ram;
    length = sizeof(ram);
    if (sysctl(mib, 2, &ram, &length, NULL, 0) < 0) {
        return -1;
    }
    return ram;
}

#pragma mark - disk

+ (NSDictionary *)td_pm_getFileAttributeDic {
    NSError *error;
    NSDictionary *directory = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) {
        return nil;
    }
    return directory;
}

+ (long long)td_get_disk_free_size {
    NSDictionary<NSFileAttributeKey, id> *directory = [self td_pm_getFileAttributeDic];
    if (directory) {
        return [[directory objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
    }
    return -1;
}

+ (long long)td_get_storage_size {
    NSDictionary<NSFileAttributeKey, id> *directory = [self td_pm_getFileAttributeDic];
    return directory ? ((NSNumber *)[directory objectForKey:NSFileSystemSize]).unsignedLongLongValue:-1;
}


@end
