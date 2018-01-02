//
//  SQNetwork.h
//  SQNetwork
//
//  Created by roylee on 2017/12/29.
//  Copyright © 2017年 bantang. All rights reserved.
//
//  This component is based on YTKNetWork https://github.com/yuantiku.
//

#import <Foundation/Foundation.h>

#ifndef _SQNETWORK_
    #define _SQNETWORK_

#if __has_include(<SQNetwork/SQNetwork.h>)

    FOUNDATION_EXPORT double SQNetworkVersionNumber;
    FOUNDATION_EXPORT const unsigned char SQNetworkVersionString[];

    #import <SQNetwork/SQRequest.h>
    #import <SQNetwork/SQNetworkAgent.h>
    #import <SQNetwork/SQBatchRequest.h>
    #import <SQNetwork/SQNetworkConfig.h>

#else

    #import "SQRequest.h"
    #import "SQNetworkAgent.h"
    #import "SQBatchRequest.h"
    #import "SQNetworkConfig.h"

#endif /* __has_include */

#endif /* SQNetwork_h */

