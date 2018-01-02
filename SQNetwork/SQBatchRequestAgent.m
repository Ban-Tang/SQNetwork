//
//  SQBatchRequestAgent.m
//  SQNetwork
//
//  Created by roylee on 2018/1/2.
//  Copyright © 2018年 bantang. All rights reserved.
//

#import "SQBatchRequestAgent.h"
#import "SQBatchRequest.h"

@interface SQBatchRequestAgent()

@property (strong, nonatomic) NSMutableArray<SQBatchRequest *> *requestArray;

@end

@implementation SQBatchRequestAgent

+ (SQBatchRequestAgent *)sharedAgent {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestArray = [NSMutableArray array];
    }
    return self;
}

- (void)addBatchRequest:(SQBatchRequest *)request {
    @synchronized(self) {
        [_requestArray addObject:request];
    }
}

- (void)removeBatchRequest:(SQBatchRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}

@end
