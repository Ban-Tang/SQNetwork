//
//  SQBatchRequestAgent.h
//  SQNetwork
//
//  Created by roylee on 2018/1/2.
//  Copyright © 2018年 bantang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SQBatchRequest;

///  SQBatchRequestAgent handles batch request management. It keeps track of all
///  the batch requests.
@interface SQBatchRequestAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared batch request agent.
+ (SQBatchRequestAgent *)sharedAgent;

///  Add a batch request.
- (void)addBatchRequest:(SQBatchRequest *)request;

///  Remove a previously added batch request.
- (void)removeBatchRequest:(SQBatchRequest *)request;

@end

NS_ASSUME_NONNULL_END
