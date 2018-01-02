//
//  SQNetworkConfig.h
//  SQNetwork
//
//  Created by roylee on 2017/12/30.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SQRequest;
@class AFSecurityPolicy;

/**
 SQUrlFilterProtocol can be used to append common parameters to requests before sending them.
 */
@protocol SQUrlFilterProtocol <NSObject>
/**
 Preprocess request URL before actually sending them.
 
 @param originUrl request's origin URL, which is returned by `requestUrl`
 @param request   request itself
 
 @return A new url which will be used as a new `requestUrl`
 */
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(SQRequest *)request;
@end

/**
 SQCacheDirPathFilterProtocol can be used to append common path components when caching response results
 */
@protocol SQCacheDirPathFilterProtocol <NSObject>
/**
 Preprocess cache path before actually saving them.
 
 @param originPath original base cache path, which is generated in `SQRequest` class.
 @param request    request itself
 
 @return A new path which will be used as base path when caching.
 */
- (NSString *)filterCacheDirPath:(NSString *)originPath withRequest:(SQRequest *)request;
@end

/**
 SQNetworkConfig stored global network-related configurations, which will be used in `SQNetworkAgent`
 to form and filter requests, as well as caching response.
 */
@interface SQNetworkConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Return a shared config object.
 */
+ (SQNetworkConfig *)sharedConfig;


/**
 Request base URL, such as "http://www.example.com". Default is empty string.
 */
@property (nonatomic, strong) NSString *baseUrl;

/**
 Request CDN URL. Default is empty string.
 */
@property (nonatomic, strong) NSString *cdnUrl;

/**
 URL filters. See also `SQUrlFilterProtocol`.
 */
@property (nonatomic, strong, readonly) id<SQUrlFilterProtocol> urlFilter;

/**
 Cache path filters. See also `SQCacheDirPathFilterProtocol`.
 */
@property (nonatomic, strong, readonly) NSArray<id<SQCacheDirPathFilterProtocol>> *cacheDirPathFilters;

/**
 Security policy will be used by AFNetworking. See also `AFSecurityPolicy`.
 */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

/**
 Whether to log debug info. Default is NO;
 */
@property (nonatomic) BOOL debugLogEnabled;

/**
 SessionConfiguration will be used to initialize AFHTTPSessionManager. Default is nil.
 */
@property (nonatomic, strong) NSURLSessionConfiguration* sessionConfiguration;

/// Add a new URL filter.
- (void)addUrlFilter:(id<SQUrlFilterProtocol>)filter;

/// Remove all URL filters.
- (void)clearUrlFilter;

/// Add a new cache path filter
- (void)addCacheDirPathFilter:(id<SQCacheDirPathFilterProtocol>)filter;

/// Clear all cache path filters.
- (void)clearCacheDirPathFilter;

@end

NS_ASSUME_NONNULL_END
