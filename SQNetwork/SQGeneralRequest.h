//
//  SQGeneralRequest.h
//  SQNetwork
//
//  Created by roylee on 2018/1/2.
//  Copyright © 2018年 bantang. All rights reserved.
//

#import "SQRequest.h"

#ifndef SQ_SUBCLASSING_RESTRICTED
#define SQ_SUBCLASSING_RESTRICTED __attribute__((objc_subclassing_restricted))
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 A general request inherited from SQRequest. And all the properties is confirm protocol
 `SQReqest`.
 
 This request will provide several properties for easy creating API requst.
 */
SQ_SUBCLASSING_RESTRICTED
@interface SQGeneralRequest : SQRequest <SQRequest>

/// All below property is confirmed protocol `SQRequest`, more info see `SQRequest`.
@property (nonatomic, strong) NSString *baseUrl;

@property (nonatomic, strong) NSString *requestUrl;

@property (nonatomic, strong) NSString *cdnUrl;

@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

@property (nonatomic, strong) id requestArgument;

@property (nonatomic, assign) SQRequestMethod requestMethod;

@property (nonatomic, assign) SQRequestSerializerType requestSerializerType;

@property (nonatomic, assign) SQResponseSerializerType responseSerializerType;

@property (nonatomic, strong, nullable) NSArray<NSString *> *requestAuthorizationHeaderFieldArray;

@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *requestHeaderFieldValueDictionary;

@property (nonatomic, strong, nullable) NSURLRequest *buildCustomUrlRequest;

@property (nonatomic, assign) BOOL useCDN;

@property (nonatomic, assign) BOOL allowsCellularAccess;

@property (nonatomic, strong, nullable) id jsonValidator;

/**
 Start a request with `requestUrl`, `requestArgument`.
 
 @param url         used as `requestUrl`.
 
 @param arguments   used as `requestArgument`.
 */
- (void)startWithRequestUrl:(NSString *)url arguments:(id)arguments;

/**
 Convenience method to start a request with `requestUrl`, `requestArgument`, block callbacks.
 */
- (void)startWithRequestUrl:(NSString *)url
                  arguments:(id)arguments
 completionBlockWithSuccess:(nullable SQRequestCompletionBlock)success
                    failure:(nullable SQRequestCompletionBlock)failure;

@end

NS_ASSUME_NONNULL_END

