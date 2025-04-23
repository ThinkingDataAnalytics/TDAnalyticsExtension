//
//  TDExtensionReachability.m
//  ThinkingDataPushExtension
//
//  Created by 杨雄 on 2023/7/4.
//

#import "TDExtensionReachability.h"
//#import <SystemConfiguration/SystemConfiguration.h>

#if TARGET_OS_IOS

#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#endif

@interface TDExtensionReachability ()
#if TARGET_OS_IOS
//@property (atomic, assign) SCNetworkReachabilityRef reachability;
#endif
@property (nonatomic, assign) BOOL isWifi;
@property (nonatomic, assign) BOOL isWwan;

@end


@implementation TDExtensionReachability

//MARK: - Public Methods

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static TDExtensionReachability *reachability = nil;
    dispatch_once(&onceToken, ^{
        reachability = [[TDExtensionReachability alloc] init];
    });
    return reachability;
}

//#if TARGET_OS_IOS

- (NSString *)networkState {
//    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL,"thinkingdata.cn");
//    self.reachability = reachability;
//    
//    if (self.reachability != NULL) {
//        SCNetworkReachabilityFlags flags;
//        BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(self.reachability, &flags);
//        if (didRetrieveFlags) {
//            self.isWifi = (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsIsWWAN);
//            self.isWwan = (flags & kSCNetworkReachabilityFlagsIsWWAN);
//        }
//    }
    
    if (self.isWifi) {
        return @"WIFI";
    }
//    else if (self.isWwan) {
//        return [self currentRadio];
//    }
    else {
        return @"NULL";
    }
}

////MARK: - Private Methods
//
//- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags {
//    self.isWifi = (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsIsWWAN);
//    self.isWwan = (flags & kSCNetworkReachabilityFlagsIsWWAN);
//}
//
//- (NSString *)currentRadio {
//    NSString *networkType = @"NULL";
//    @try {
//        static CTTelephonyNetworkInfo *info = nil;
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            info = [[CTTelephonyNetworkInfo alloc] init];
//        });
//        NSString *currentRadio = nil;
//#ifdef __IPHONE_12_0
//        if (@available(iOS 12.0, *)) {
//            NSDictionary *serviceCurrentRadio = [info serviceCurrentRadioAccessTechnology];
//            if ([serviceCurrentRadio isKindOfClass:[NSDictionary class]] && serviceCurrentRadio.allValues.count>0) {
//                currentRadio = serviceCurrentRadio.allValues[0];
//            }
//        }
//#endif
//        if (currentRadio == nil && [info.currentRadioAccessTechnology isKindOfClass:[NSString class]]) {
//            currentRadio = info.currentRadioAccessTechnology;
//        }
//        
//        if ([currentRadio isEqualToString:CTRadioAccessTechnologyLTE]) {
//            networkType = @"4G";
//        } else if ([currentRadio isEqualToString:CTRadioAccessTechnologyeHRPD] ||
//                   [currentRadio isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] ||
//                   [currentRadio isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
//                   [currentRadio isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
//                   [currentRadio isEqualToString:CTRadioAccessTechnologyCDMA1x] ||
//                   [currentRadio isEqualToString:CTRadioAccessTechnologyHSUPA] ||
//                   [currentRadio isEqualToString:CTRadioAccessTechnologyHSDPA] ||
//                   [currentRadio isEqualToString:CTRadioAccessTechnologyWCDMA]) {
//            networkType = @"3G";
//        } else if ([currentRadio isEqualToString:CTRadioAccessTechnologyEdge] ||
//                   [currentRadio isEqualToString:CTRadioAccessTechnologyGPRS]) {
//            networkType = @"2G";
//        }
//#ifdef __IPHONE_14_1
//        else if (@available(iOS 14.1, *)) {
//            if ([currentRadio isKindOfClass:[NSString class]]) {
//                if([currentRadio isEqualToString:CTRadioAccessTechnologyNRNSA] ||
//                   [currentRadio isEqualToString:CTRadioAccessTechnologyNR]) {
//                    networkType = @"5G";
//                }
//            }
//        }
//#endif
//    } @catch (NSException *exception) {
//
//    }
//    
//    return networkType;
//}
//
//#elif TARGET_OS_OSX
//
//+ (ThinkingNetworkType)convertNetworkType:(NSString *)networkType {
//    return ThinkingNetworkTypeWIFI;
//}
//
//- (void)startMonitoring {
//}
//
//- (void)stopMonitoring {
//}
//
//- (NSString *)currentRadio {
//    return @"WIFI";
//}
//
//- (NSString *)networkState {
//    return @"WIFI";
//}
//
//#endif

@end
