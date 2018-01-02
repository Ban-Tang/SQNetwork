//
//  SQNetworkCache.m
//  SQNetwork
//
//  Created by roylee on 2017/12/30.
//  Copyright © 2017年 bantang. All rights reserved.
//

#import "SQNetworkCache.h"
#import "SQNetworkConfig.h"
#import "SQRequest.h"
#import "SQNetworkPrivate.h"
#import <objc/runtime.h>

#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_With_QoS_Available 1140.11
#else
#define NSFoundationVersionNumber_With_QoS_Available NSFoundationVersionNumber_iOS_8_0
#endif

static dispatch_queue_t SQrequest_cache_writing_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_With_QoS_Available) {
            attr = dispatch_queue_attr_make_with_qos_class(attr, QOS_CLASS_BACKGROUND, 0);
        }
        queue = dispatch_queue_create("com.bantang.SQrequest.caching", attr);
    });
    return queue;
}

NSString *const SQRequestCacheErrorDomain = @"com.bantang.request.caching";

@interface SQCacheMetadata : NSObject<NSSecureCoding>

@property (nonatomic, assign) long long version;
@property (nonatomic, strong) NSString *sensitiveDataString;
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSString *appVersionString;

@end

@implementation SQCacheMetadata

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.version) forKey:NSStringFromSelector(@selector(version))];
    [aCoder encodeObject:self.sensitiveDataString forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    [aCoder encodeObject:@(self.stringEncoding) forKey:NSStringFromSelector(@selector(stringEncoding))];
    [aCoder encodeObject:self.creationDate forKey:NSStringFromSelector(@selector(creationDate))];
    [aCoder encodeObject:self.appVersionString forKey:NSStringFromSelector(@selector(appVersionString))];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.version = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(version))] integerValue];
    self.sensitiveDataString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    self.stringEncoding = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(stringEncoding))] integerValue];
    self.creationDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(creationDate))];
    self.appVersionString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(appVersionString))];
    
    return self;
}

@end



@interface SQRequest ()
@property (nonatomic, strong) SQCacheMetadata *cacheMetadata;
@end


@interface SQNetworkCache()

@property (nonatomic, strong) NSString *cachePath;

@end

@implementation SQNetworkCache

+ (instancetype)shareCache {
    static id cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[[self class] alloc] init];
    });
    return cache;
}

- (instancetype)init {
    return [self initWithCachePath:@"LazyRequestCache"];
}

- (instancetype)initWithCachePath:(NSString *)cachePath {
    self = [super init];
    if (self) {
        _cachePath = [self createBasePath:cachePath];
    }
    return self;
}

- (BOOL)loadCacheDataWithRequest:(SQRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    // Try load metadata.
    if (![self loadCacheMetadataWithRequest:request]) {
        if (error) {
            *error = [NSError errorWithDomain:SQRequestCacheErrorDomain code:SQRequestCacheErrorInvalidMetadata userInfo:@{ NSLocalizedDescriptionKey:@"Invalid metadata. Cache may not exist"}];
        }
        return NO;
    }
    
    // Try load cache.
    if (![self loadCacheDataWithRequest:request]) {
        if (error) {
            *error = [NSError errorWithDomain:SQRequestCacheErrorDomain code:SQRequestCacheErrorInvalidCacheData userInfo:@{ NSLocalizedDescriptionKey:@"Invalid cache data"}];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)loadCacheMetadataWithRequest:(SQRequest *)request {
    NSString *path = [self cacheMetadataFilePathWithRequest:request];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        @try {
            request.cacheMetadata = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            return YES;
        } @catch (NSException *exception) {
            SQLog(@"Load cache metadata failed, reason = %@", exception.reason);
            return NO;
        }
    }
    return NO;
}

- (BOOL)loadCacheDataWithRequest:(SQRequest *)request {
    NSString *path = [self cacheFilePathWithRequest:request];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        request.cacheData = data;
        request.cacheString = [[NSString alloc] initWithData:request.cacheData encoding:request.cacheMetadata.stringEncoding];
        switch (request.child.responseSerializerType) {
            case SQResponseSerializerTypeHTTP:
                // Do nothing.
                return YES;
            case SQResponseSerializerTypeJSON:
                request.cacheJSON = [NSJSONSerialization JSONObjectWithData:request.cacheData options:(NSJSONReadingOptions)0 error:&error];
                return error == nil;
            case SQResponseSerializerTypeXMLParser:
                request.cacheXML = [[NSXMLParser alloc] initWithData:request.cacheData];
                return YES;
        }
    }
    return NO;
}

- (void)cacheData:(NSData *)data forRequest:(SQRequest *)request {
    if (![request isDataFromCache]) {
        if (data != nil) {
            @try {
                // New data will always overwrite old data.
                [data writeToFile:[self cacheFilePathWithRequest:request] atomically:YES];
                
                SQCacheMetadata *metadata = [[SQCacheMetadata alloc] init];
                metadata.stringEncoding = [SQNetworkUtils stringEncodingWithRequest:request];
                metadata.creationDate = [NSDate date];
                metadata.appVersionString = [SQNetworkUtils appVersionString];
                [NSKeyedArchiver archiveRootObject:metadata toFile:[self cacheMetadataFilePathWithRequest:request]];
            } @catch (NSException *exception) {
                SQLog(@"Save cache failed, reason = %@", exception.reason);
            }
        }
    }
}

- (void)deleteCacheWithRequest:(SQRequest *)request {
    NSString *filePath = [self cacheFilePathWithRequest:request];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
}

- (void)clearCache {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:_cachePath error:nil];
}

#pragma mark - Private

- (NSString *)createBasePath:(NSString *)pathName {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:pathName];
    return path;
}

- (void)createDirectoryIfNeeded:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        [self createBaseDirectoryAtPath:path];
    } else {
        if (!isDir) {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            [self createBaseDirectoryAtPath:path];
        }
    }
}

- (void)createBaseDirectoryAtPath:(NSString *)path {
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
                                               attributes:nil error:&error];
    if (error) {
        SQLog(@"create cache directory failed, error = %@", error);
    } else {
        [SQNetworkUtils addDoNotBackupAttribute:path];
    }
}

- (NSString *)cacheBasePathWithReuqest:(SQRequest *)request {
    NSString *path = _cachePath;
    
    // Filter cache base path
    NSArray<id<SQCacheDirPathFilterProtocol>> *filters = [[SQNetworkConfig sharedConfig] cacheDirPathFilters];
    if (filters.count > 0) {
        for (id<SQCacheDirPathFilterProtocol> f in filters) {
            path = [f filterCacheDirPath:path withRequest:request];
        }
    }
    
    [self createDirectoryIfNeeded:path];
    return path;
}

- (NSString *)cacheFileNameWithRequest:(SQRequest *)request {
    NSString *requestUrl = [request.child requestUrl];
    NSString *baseUrl = [SQNetworkConfig sharedConfig].baseUrl;
    id argument = [[request.child requestArgument] mutableCopy];
    if (request.ignoreArgumentKeys.count > 0) {
        for (NSString *ignoreKey in request.ignoreArgumentKeys) {
            [argument setValue:nil forKey:ignoreKey];
        }
    }
    NSString *requestInfo = [NSString stringWithFormat:@"Method:%ld Host:%@ Url:%@ Argument:%@",
                             (long)[request.child requestMethod], baseUrl, requestUrl, argument];
    NSString *cacheFileName = [SQNetworkUtils md5StringFromString:requestInfo];
    return cacheFileName;
}

- (NSString *)cacheFilePathWithRequest:(SQRequest *)request {
    NSString *cacheFileName = [self cacheFileNameWithRequest:request];
    NSString *path = [self cacheBasePathWithReuqest:request];
    path = [path stringByAppendingPathComponent:cacheFileName];
    return path;
}

- (NSString *)cacheMetadataFilePathWithRequest:(SQRequest *)request {
    NSString *cacheMetadataFileName = [NSString stringWithFormat:@"%@.metadata", [self cacheFileNameWithRequest:request]];
    NSString *path = [self cacheBasePathWithReuqest:request];
    path = [path stringByAppendingPathComponent:cacheMetadataFileName];
    return path;
}

@end




@implementation SQRequest (CacheExtension)

- (SQCacheMetadata *)cacheMetadata {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCacheMetadata:(SQCacheMetadata *)cacheMetadata {
    objc_setAssociatedObject(self, @selector(cacheMetadata), cacheMetadata, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSData *)cacheData {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCacheData:(NSData *)cacheData {
    objc_setAssociatedObject(self, @selector(cacheData), cacheData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)cacheString {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCacheString:(NSString *)cacheString {
    objc_setAssociatedObject(self, @selector(cacheString), cacheString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)cacheJSON {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCacheJSON:(id)cacheJSON {
    objc_setAssociatedObject(self, @selector(cacheJSON), cacheJSON, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)cacheXML {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCacheXML:(NSXMLParser *)cacheXML {
    objc_setAssociatedObject(self, @selector(cacheXML), cacheXML, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)ignoreCache {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIgnoreCache:(BOOL)ignoreCache {
    objc_setAssociatedObject(self, @selector(ignoreCache), @(ignoreCache), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray<NSString *> *)ignoreArgumentKeys {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setIgnoreArgumentKeys:(NSArray<NSString *> *)ignoreArgumentKeys {
    objc_setAssociatedObject(self, @selector(ignoreArgumentKeys), ignoreArgumentKeys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)writeCacheAsynchronously {
    id flag = objc_getAssociatedObject(self, _cmd);
    if (flag) {
        return [flag boolValue];
    }
    return YES;
}

- (void)setWriteCacheAsynchronously:(BOOL)writeCacheAsynchronously {
    objc_setAssociatedObject(self, @selector(writeCacheAsynchronously), @(writeCacheAsynchronously), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isDataFromCache {
    return self.cacheData != nil;
}

- (BOOL)loadCacheWithError:(NSError * __autoreleasing *)error {
    return [[SQNetworkCache shareCache] loadCacheDataWithRequest:self error:error];
}

- (void)startWithoutCache {
    [self setIgnoreCache:YES];
    [self start];
}

- (void)saveResponseDataToCacheFile:(NSData *)data {
    if (self.ignoreCache || self.isDataFromCache) {
        return;
    }
    // Cache the data.
    if (self.writeCacheAsynchronously) {
        dispatch_async(SQrequest_cache_writing_queue(), ^{
            [[SQNetworkCache shareCache] cacheData:self.responseData forRequest:self];
        });
    } else {
        [[SQNetworkCache shareCache] cacheData:self.responseData forRequest:self];
    }
}

@end


