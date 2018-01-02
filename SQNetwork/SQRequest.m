//
//  SQRequest.m
//  SQNetwork
//
//  Created by roylee on 2017/12/29.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import "SQRequest.h"
#import "SQNetworkAgent.h"
#import "SQNetworkPrivate.h"
#import "SQNetworkCache.h"

NSString *const SQRequestValidationErrorDomain = @"com.bantang.request.validation";

@interface SQRequest ()

@property (nonatomic, weak, readwrite) id<SQRequest> child;
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) id responseJSONObject;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSString *responseString;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation SQRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        if ([self isMemberOfClass:[SQRequest class]]) {
            [NSException raise:@"SQRequest Init Error" format:@"SQRequest is an abstract class, only subclass is available.",nil];
        }
        if ([self conformsToProtocol:@protocol(SQRequest)]) {
            [self setChild:(id<SQRequest>)self];
        }else {
            [NSException raise:@"SQRequest Implemention Error" format:@"Subclass must confirm protocol SQRequest.",nil];
        }
    }
    return self;
}

#pragma mark - Request and Response Information

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSInteger)responseStatusCode {
    return self.response.statusCode;
}

- (NSDictionary *)responseHeaders {
    return self.response.allHeaderFields;
}

- (NSURLRequest *)currentRequest {
    return self.requestTask.currentRequest;
}

- (NSURLRequest *)originalRequest {
    return self.requestTask.originalRequest;
}

- (NSData *)responseData {
    if (_responseData) {
        return _responseData;
    }
    if (self.cacheData) {
        return self.cacheData;
    }
    return nil;
}

- (NSString *)responseString {
    if (_responseString) {
        return _responseString;
    }
    if (self.cacheString) {
        return self.cacheString;
    }
    return nil;
}

- (id)responseJSONObject {
    if (_responseJSONObject) {
        return _responseJSONObject;
    }
    if (self.cacheJSON) {
        return self.cacheJSON;
    }
    return nil;
}

- (id)responseObject {
    if (_responseObject) {
        return _responseObject;
    }
    if (self.cacheJSON) {
        return self.cacheJSON;
    }
    if (self.cacheXML) {
        return self.cacheXML;
    }
    if (self.cacheData) {
        return self.cacheData;
    }
    return nil;
}

- (BOOL)isCancelled {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}

#pragma mark - Request Configuration

- (void)setCompletionBlockWithSuccess:(SQRequestCompletionBlock)success
                              failure:(SQRequestCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (void)addAccessory:(id<SQRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

#pragma mark - Request Action

- (void)start {
    [self toggleAccessoriesWillStartCallBack];
    [[SQNetworkAgent sharedAgent] addRequest:self];
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    self.delegate = nil;
    [[SQNetworkAgent sharedAgent] cancelRequest:self];
    [self toggleAccessoriesDidStopCallBack];
}

- (void)startWithCompletionBlockWithSuccess:(SQRequestCompletionBlock)success
                                    failure:(SQRequestCompletionBlock)failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

#pragma mark - @protocol SQRequest

- (NSString *)requestUrl {
    return @"";
}

- (NSString *)cdnUrl {
    return @"";
}

- (NSString *)baseUrl {
    return @"";
}

- (NSTimeInterval)requestTimeoutInterval {
    return 20.f;
}

- (SQRequestMethod)requestMethod {
    return SQRequestMethodGET;
}

- (SQRequestSerializerType)requestSerializerType {
    return SQRequestSerializerTypeHTTP;
}

- (SQResponseSerializerType)responseSerializerType {
    return SQResponseSerializerTypeJSON;
}

- (BOOL)allowsCellularAccess {
    return YES;
}

- (BOOL)statusCodeValidator {
    NSInteger statusCode = [self responseStatusCode];
    return (statusCode >= 200 && statusCode <= 299);
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.currentRequest.URL, self.currentRequest.HTTPMethod, self.child.requestArgument];
}

@end
