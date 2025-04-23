//
//  TDExtensionNetwork.m
//  ThinkingDataPushExtension
//
//  Created by 杨雄 on 2023/7/3.
//

#import "TDExtensionNetwork.h"
#import "TDAnalyticsExtensionConstPublic.h"
#import "TDExtensionSecurityPolicy.h"

#if __has_include(<ThinkingDataCore/ThinkingDataCore.h>)
#import <ThinkingDataCore/ThinkingDataCore.h>
#else
#import "ThinkingDataCore.h"
#endif

static NSString *kTAIntegrationType = @"TA-Integration-Type";
static NSString *kTAIntegrationVersion = @"TA-Integration-Version";
static NSString *kTAIntegrationCount = @"TA-Integration-Count";
static NSString *kTAIntegrationExtra = @"TA-Integration-Extra";
static NSString *kTADatasType = @"TA-Datas-Type";

@interface TDExtensionNetwork ()<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) TDExtensionSecurityPolicy *securityPolicy;

@end

@implementation TDExtensionNetwork

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static TDExtensionNetwork *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[TDExtensionNetwork alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.securityPolicy = [TDExtensionSecurityPolicy defaultPolicy];
        
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    return self;
}

- (NSString *)URLEncode:(NSString *)string {
    NSString *encodedString = [string stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"?!@#$^&%*+,:;='\"`<>()[]{}/\\| "] invertedSet]];
    return encodedString;
}

- (BOOL)flushEvents:(NSArray<NSDictionary *> *)recordArray withAppId:(NSString *)appId receiverUrl:(NSString *)receiverUrl {
    if (!(appId.length && receiverUrl.length)) {
        return NO;
    }
    
    receiverUrl = [NSString stringWithFormat:@"%@/sync", receiverUrl];
    
    __block BOOL flushSucc = YES;
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    NSDictionary *flushDic = @{
        @"data": recordArray,
        @"#app_id": appId,
        @"#flush_time": @(time),
    };
    
    NSString *jsonString = [TDJSONUtil JSONStringForObject:flushDic];
    NSMutableURLRequest *request = [self buildRequestWithJSONString:jsonString receiverUrl:receiverUrl];
    if (!request) return NO;
    
    [request addValue:TD_LIB_NAME forHTTPHeaderField:kTAIntegrationType];
    [request addValue:TD_LIB_VERSION forHTTPHeaderField:kTAIntegrationVersion];
    [request addValue:@(recordArray.count).stringValue forHTTPHeaderField:kTAIntegrationCount];
    [request addValue:@"iOS" forHTTPHeaderField:kTAIntegrationExtra];
 
    dispatch_semaphore_t flushSem = dispatch_semaphore_create(0);

    void (^block)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            flushSucc = NO;
            NSLog(@"[ThinkingData] Networking error:%@", error);
            [self callbackNetworkErrorWithRequest:jsonString error:error.debugDescription];
            dispatch_semaphore_signal(flushSem);
            return;
        }

        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        if ([urlResponse statusCode] == 200) {
            flushSucc = YES;
            NSLog(@"[ThinkingData] send data, count: %ld", recordArray.count);
            if (!data) {
                return;
            }
            id result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"[ThinkingData] send data, response: %@",result);
            
            @try {
                if ([result isKindOfClass:[NSDictionary class]]) {
                    if ([[(NSDictionary *)result objectForKey:@"code"] integerValue] != 0) {
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:NULL];
                        NSString *string = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        [self callbackNetworkErrorWithRequest:jsonString error:string];
                    }
                }
            } @catch (NSException *exception) {
                
            }

        } else {
            flushSucc = NO;
            NSString *urlResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"[ThinkingData] %@", urlResponse);
            [self callbackNetworkErrorWithRequest:jsonString error:urlResponse];
        }

        dispatch_semaphore_signal(flushSem);
    };

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:block];
    [task resume];
    dispatch_semaphore_wait(flushSem, DISPATCH_TIME_FOREVER);
    return flushSucc;
}

- (int)flushDebugEvent:(NSDictionary *)record withAppId:(NSString *)appId receiverUrl:(NSString *)receiverUrl deviceId:(NSString *)deviceId {
    if (!(appId.length && receiverUrl.length)) {
        return NO;
    }
    
    receiverUrl = [NSString stringWithFormat:@"%@/data_debug", receiverUrl];
    
    NSString *jsonString = [TDJSONUtil JSONStringForObject:record];
    
    NSLog(@"[ThinkingData] Send data, request: %@", record);
        
    NSMutableURLRequest *request = [self buildDebugRequestWithJSONString:jsonString withAppid:appId receiverUrl:receiverUrl deviceId:deviceId];
    
    dispatch_semaphore_t flushSem = dispatch_semaphore_create(0);

    __block int debugResult = -1;

    void (^block)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            debugResult = -2;
            NSLog(@"[ThinkingData] Debug Networking error:%@", error);
            [self callbackNetworkErrorWithRequest:jsonString error:error.debugDescription];
            dispatch_semaphore_signal(flushSem);
            return;
        }
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        if ([urlResponse statusCode] == 200) {
            NSError *err;
            
            if (!data) {
                return;
            }
            
            NSDictionary *retDic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
            
            NSLog(@"[ThinkingData] Send data, response: %@", retDic);

            if (err) {
                NSLog(@"[ThinkingData] Debug data json error:%@", err);
                debugResult = -2;
            } else if ([[retDic objectForKey:@"errorLevel"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
                debugResult = 1;
                NSArray* errorProperties = [retDic objectForKey:@"errorProperties"];
                NSMutableString *errorStr = [NSMutableString string];
                for (id obj in errorProperties) {
                    NSString *errorReasons = [obj objectForKey:@"errorReason"];
                    NSString *propertyName = [obj objectForKey:@"propertyName"];
                    [errorStr appendFormat:@" propertyName:%@ errorReasons:%@\n", propertyName, errorReasons];
                }
                NSLog(@"[ThinkingData] Debug data error:%@", errorStr);
            } else if ([[retDic objectForKey:@"errorLevel"] isEqualToNumber:[NSNumber numberWithInt:2]]) {
                debugResult = 2;
                NSString *errorReasons = [[retDic objectForKey:@"errorReasons"] componentsJoinedByString:@" "];
                NSLog(@"[ThinkingData] Debug data error:%@", errorReasons);
            } else if ([[retDic objectForKey:@"errorLevel"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
                debugResult = 0;
                NSLog(@"[ThinkingData] Verify data success.");
            } else if ([[retDic objectForKey:@"errorLevel"] isEqualToNumber:[NSNumber numberWithInt:-1]]) {
                debugResult = -1;
                NSString *errorReasons = [[retDic objectForKey:@"errorReasons"] componentsJoinedByString:@" "];
                NSLog(@"[ThinkingData] Debug mode error:%@", errorReasons);
            }
            
            @try {
                if ([retDic isKindOfClass:[NSDictionary class]]) {
                    if ([[(NSDictionary *)retDic objectForKey:@"errorLevel"] integerValue] != 0) {
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:retDic options:NSJSONWritingPrettyPrinted error:NULL];
                        NSString *string = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        [self callbackNetworkErrorWithRequest:jsonString error:string];
                    }
                }
            } @catch (NSException *exception) {
                
            }
        } else {
            debugResult = -2;
            NSString *urlResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"[ThinkingData] Debug %@ network failed with response '%@'.", self, urlResponse);
            [self callbackNetworkErrorWithRequest:jsonString error:urlResponse];
        }
        dispatch_semaphore_signal(flushSem);
    };

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:block];
    [task resume];

    dispatch_semaphore_wait(flushSem, DISPATCH_TIME_FOREVER);
    return debugResult;
}

- (void)callbackNetworkErrorWithRequest:(NSString *)request error:(NSString *)error {
    if (request == nil && error == nil) return;
    
}

- (NSMutableURLRequest * _Nullable)buildRequestWithJSONString:(NSString *)jsonString receiverUrl:(NSString *)receiverUrl {
    NSURL *url = [NSURL URLWithString:receiverUrl];
    if (!url) {
        return nil;
    }
    NSData *zippedData = [NSData td_gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *postBody = [zippedData base64EncodedStringWithOptions:0];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *contentType = [NSString stringWithFormat:@"text/plain"];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:6];
    return request;
}

- (NSMutableURLRequest *)buildDebugRequestWithJSONString:(NSString *)jsonString withAppid:(NSString *)appid receiverUrl:(NSString *)receiverUrl deviceId:(NSString *)deviceId {
    NSURL *url = [NSURL URLWithString:receiverUrl];
    if (!url) {
        return nil;
    }
    // dryRun=0, if the verification is passed, it will be put into storage. dryRun=1, no storage
    int dryRun = 1;
    NSString *postData = [NSString stringWithFormat:@"appid=%@&source=client&dryRun=%d&deviceId=%@&data=%@", appid, dryRun, deviceId ?: @"", [self URLEncode:jsonString]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    request.HTTPBody = [postData dataUsingEncoding:NSUTF8StringEncoding];
    return request;
}


#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;

    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            if (credential) {
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }

    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

@end
