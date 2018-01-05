//
//  SQBatchRequest.m
//  SQNetwork
//
//  Created by roylee on 2017/12/30.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import "SQBatchRequest.h"
#import "SQNetworkPrivate.h"
#import "SQBatchRequestAgent.h"
#import <objc/runtime.h>

@interface SQBatchRequest ()<SQRequestDelegate>

// Tag request finished count, 0 is start.
@property (nonatomic, assign) NSInteger finishedCount;

@end

@implementation SQBatchRequest

- (instancetype)initWithRequestArray:(NSArray<SQRequest *> *)requestArray {
    self = [super init];
    if (self) {
        _requestArray = [requestArray copy];
        _finishedCount = 0;
        for (SQRequest * req in _requestArray) {
            if (![req isKindOfClass:[SQRequest class]]) {
                SQLog(@"Error, request item must be SQRequest instance.");
                return nil;
            }
        }
        if (requestArray.count <= 0) {
            SQLog(@"Error, request array must not be empty.");
            return nil;
        }
    }
    return self;
}

- (void)start {
    if (_finishedCount > 0) {
        SQLog(@"Error! Batch request has already started.");
        return;
    }
    [[SQBatchRequestAgent sharedAgent] addBatchRequest:self];
    [self toggleAccessoriesWillStartCallBack];
    _failedRequest = nil;
    
    __weak typeof(self) weakSelf = self;
    for (SQRequest * request in _requestArray) {
        [request startWithCompletionBlockWithSuccess:^(__kindof SQRequest * _Nonnull request, id  _Nullable formattedData) {
            [weakSelf requestFinished:request];
        } failure:^(__kindof SQRequest * _Nonnull request, id  _Nullable formattedData) {
            [weakSelf requestFailed:request];
        }];
    }
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    _delegate = nil;
    [self clearRequest];
    [self toggleAccessoriesDidStopCallBack];
    [[SQBatchRequestAgent sharedAgent] removeBatchRequest:self];
}

- (void)startWithCompletionBlockWithSuccess:(void (^)(SQBatchRequest *batchRequest))success
                                    failure:(void (^)(SQBatchRequest *batchRequest))failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)setCompletionBlockWithSuccess:(void (^)(SQBatchRequest *batchRequest))success
                              failure:(void (^)(SQBatchRequest *batchRequest))failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (void)dealloc {
    [self clearRequest];
}

#pragma mark - SQRequest Call Back

- (void)requestFinished:(SQRequest *)Request {
    _finishedCount ++;
    if (_finishedCount == _requestArray.count) {
        [self toggleAccessoriesWillStopCallBack];
        if ([_delegate respondsToSelector:@selector(batchRequestFinished:)]) {
            [_delegate batchRequestFinished:self];
        }
        if (_successCompletionBlock) {
            _successCompletionBlock(self);
        }
        [self clearCompletionBlock];
        [self toggleAccessoriesDidStopCallBack];
        [[SQBatchRequestAgent sharedAgent] removeBatchRequest:self];
    }
}

- (void)requestFailed:(SQRequest *)request {
    _failedRequest = request;
    
    // If the request is fail ignored, handle the request as sucess finished.
    if (_failedRequest.ignoreFailedInBatchReqeust) {
        [self requestFinished:request];
        [request stop];
    }else {
        // Fail config.
        [self toggleAccessoriesWillStopCallBack];
        
        // Stop
        for (SQRequest *request in _requestArray) {
            [request stop];
        }
        // Callback
        if ([_delegate respondsToSelector:@selector(batchRequestFailed:)]) {
            [_delegate batchRequestFailed:self];
        }
        if (_failureCompletionBlock) {
            _failureCompletionBlock(self);
        }
        // Clear
        [self clearCompletionBlock];
        
        [self toggleAccessoriesDidStopCallBack];
    }
}

- (void)clearRequest {
    for (SQRequest * request in _requestArray) {
        request.delegate = nil;
        [request stop];
    }
    [self clearCompletionBlock];
}

#pragma mark - Request Accessoies

- (void)addAccessory:(id<SQRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

@end




@implementation SQRequest (BatchRequest)

- (BOOL)ignoreFailedInBatchReqeust {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIgnoreFailedInBatchReqeust:(BOOL)ignoreFailedInBatchReqeust {
    objc_setAssociatedObject(self, @selector(ignoreFailedInBatchReqeust), @(ignoreFailedInBatchReqeust), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
