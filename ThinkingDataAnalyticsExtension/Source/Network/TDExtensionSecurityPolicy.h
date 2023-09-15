//
//  TDExtensionSecurityPolicy.h
//  ThinkingDataPushExtension
//
//  Created by 杨雄 on 2023/7/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Https Certificate Verification Mode
*/
typedef NS_OPTIONS(NSInteger, TDSSLPinningMode) {
    /**
     The default authentication method will only verify the certificate returned by the server in the system's trusted certificate list
    */
    TDSSLPinningModeNone          = 0,
    
    /**
     The public key of the verification certificate
    */
    TDSSLPinningModePublicKey     = 1 << 0,
    
    /**
     Verify all contents of the certificate
    */
    TDSSLPinningModeCertificate   = 1 << 1
};


/**
 Custom HTTPS Authentication
*/
typedef NSURLSessionAuthChallengeDisposition (^TDURLSessionDidReceiveAuthenticationChallengeBlock)(NSURLSession *_Nullable session, NSURLAuthenticationChallenge *_Nullable challenge, NSURLCredential *_Nullable __autoreleasing *_Nullable credential);


@interface TDExtensionSecurityPolicy : NSObject<NSCopying>

@property (nonatomic, assign) BOOL allowInvalidCertificates;
@property (nonatomic, assign) BOOL validatesDomainName;
@property (nonatomic, copy) TDURLSessionDidReceiveAuthenticationChallengeBlock sessionDidReceiveAuthenticationChallenge;
+ (instancetype)policyWithPinningMode:(TDSSLPinningMode)pinningMode;
+ (instancetype)defaultPolicy;
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain;

@end

#ifndef __Require_Quiet
    #define __Require_Quiet(assertion, exceptionLabel)                            \
      do                                                                          \
      {                                                                           \
          if ( __builtin_expect(!(assertion), 0) )                                \
          {                                                                       \
              goto exceptionLabel;                                                \
          }                                                                       \
      } while ( 0 )
#endif

#ifndef __Require_noErr_Quiet
    #define __Require_noErr_Quiet(errorCode, exceptionLabel)                      \
      do                                                                          \
      {                                                                           \
          if ( __builtin_expect(0 != (errorCode), 0) )                            \
          {                                                                       \
              goto exceptionLabel;                                                \
          }                                                                       \
      } while ( 0 )
#endif

NS_ASSUME_NONNULL_END
