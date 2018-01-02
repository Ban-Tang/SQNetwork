//
//  SQGeneralRequest.m
//  SQNetwork
//
//  Created by roylee on 2018/1/2.
//  Copyright © 2018年 bantang. All rights reserved.
//

#import "SQGeneralRequest.h"

@implementation SQGeneralRequest

- (void)startWithRequestUrl:(NSString *)url arguments:(id)arguments {
    _requestUrl = url;
    _requestArgument = arguments;
    [self start];
}

- (void)startWithRequestUrl:(NSString *)url
                  arguments:(id)arguments
 completionBlockWithSuccess:(nullable SQRequestCompletionBlock)success
                    failure:(nullable SQRequestCompletionBlock)failure {
    _requestUrl = url;
    _requestArgument = arguments;
    [self startWithCompletionBlockWithSuccess:success failure:failure];
}

@end
