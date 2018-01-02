//
//  SQBatchRequest.h
//  SQNetwork
//
//  Created by roylee on 2017/12/30.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class SQBatchRequest;

typedef void (^SQBatchRequestCompletionBlock)(__kindof SQBatchRequest *Request);

/**
 The SQBatchRequestDelegate protocol defines several optional methods you can use
 to receive network-related messages. All the delegate methods will be called
 on the main queue.
 */
@protocol SQBatchRequestDelegate <NSObject>

@optional
/**
 Tell the delegate that all the requests has finished successfully.
 
 @param Request The corresponding requests.
 */
- (void)batchRequestFinished:(__kindof SQBatchRequest *)Request;

/**
 Tell the delegate that one of the requests has failed.
 
 @param Request The corresponding requests.
 */
- (void)batchRequestFailed:(__kindof SQBatchRequest *)Request;

@end


/**
 SQBatchRequest can be used to batch several SQRequest. Note that when used inside SQBatchRequest, a single
 SQBatchRequest will have its own callback and delegate cleared, in favor of the batch request callback.
 */
@interface SQBatchRequest : NSObject

/**
 All the requests are stored in this array.
 */
@property (nonatomic, strong, readonly) NSArray<SQRequest *> *requestArray;

/**
 All the request operation are stored in this array.
 */
@property (nonatomic, strong, readonly) NSArray<SQRequest *> *RequestArray;

/**
 The delegate object of the batch request operation. Default is nil.
 */
@property (nonatomic, weak, nullable) id<SQBatchRequestDelegate> delegate;

/**
 The success callback. Note this will be called only if all the requests are finished.
 This block will be called on the main queue.
 */
@property (nonatomic, copy, nullable) void (^successCompletionBlock)(SQBatchRequest *);

/**
 The failure callback. Note this will be called if one of the requests fails.
 This block will be called on the main queue.
 */
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(SQBatchRequest *);

/**
 Tag can be used to identify batch request. Default value is 0.
 */
@property (nonatomic) NSInteger tag;

/**
 This can be used to add several accossories object. Note if you use `addAccessory` to add acceesory
 this array will be automatically created. Default is nil.
 */
@property (nonatomic, strong, nullable) NSMutableArray<id<SQRequestAccessory>> *requestAccessories;

/**
 The first request that failed (and causing the batch request to fail).
 */
@property (nonatomic, strong, readonly, nullable) SQRequest *failedRequest;

/**
 Creates a `YTKBatchRequest` with a bunch of requests.
 
 @param requestArray requests used to create batch request.
 */
- (instancetype)initWithRequestArray:(NSArray<SQRequest *> *)requestArray;

/**
 Set completion callbacks
 */
- (void)setCompletionBlockWithSuccess:(nullable void (^)(SQBatchRequest *batchRequest))success
                              failure:(nullable void (^)(SQBatchRequest *batchRequest))failure;

/**
 Nil out both success and failure callback blocks.
 */
- (void)clearCompletionBlock;

/**
 Convenience method to add request accessory. See also `requestAccessories`.
 */
- (void)addAccessory:(id<SQRequestAccessory>)accessory;

/**
 Append all the requests to queue.
 */
- (void)start;

/**
 Stop all the requests of the batch request operation.
 */
- (void)stop;

/**
 Convenience method to start the batch request with block callbacks.
 */
- (void)startWithCompletionBlockWithSuccess:(nullable void (^)(SQBatchRequest *batchRequest))success
                                    failure:(nullable void (^)(SQBatchRequest *batchRequest))failure;

@end




@interface SQRequest (BatchRequest)

/**
 Indicator that if going on other requests when this request failed. Default is NO.

 If this property is YES, the `failedRequest` of the batch request operation will be the
 last failed request. And the failed request will not break the batch request operation.
 */
@property (nonatomic, assign) BOOL ignoreFailedInBatchReqeust;

@end


NS_ASSUME_NONNULL_END
