//
//  FlexNode+Local.m
//  BossHi-RD
//
//  Created by 周兴 on 2022/7/21.
//  Copyright © 2022 xucg. All rights reserved.
//

#import "FlexNode+Local.h"
#import "FlexHotReloadUtil.h"
#import "FlexSocketManager.h"
#import "NSObject+AM.h"
#import "FlexRootView.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"


@implementation FlexNode (Local)

+ (void)load {
#ifdef DEBUG
    if (!FHROpenWhenDebug) return;
    
    //hook 加载node方法
    SEL loadSelector = @selector(internalLoadRes:Owner:);
    if ([self respondsToSelector:loadSelector]) {
        //hook 加载 node方法
        [FlexNode am_swizzleClassMethodWithOriginSel:loadSelector swizzledSel:@selector(fhr_internalLoadRes:owner:)];
                
        //开始连接长连接
        [[FlexSocketManager sharedInstance] connect];
        [FlexSocketManager sharedInstance].fileChangeBlock = ^(NSString * _Nonnull fileName) {
            if ([fileName hasSuffix:@".xml"]) {
                NSString *fileNameString = [[[fileName componentsSeparatedByString:@"/"] lastObject] stringByReplacingOccurrencesOfString:@".xml" withString:@""];
                //清除变化的文件缓存
                [flexXmlCacheData removeObjectForKey:[NSString stringWithFormat:@"%@.xml", fileNameString]];
            }
        };
        FHRLogger(@"开始启动本地服务");
    } else {
        FHRLogger([NSString stringWithFormat:@"FlexNode 无方法：%@", NSStringFromSelector(loadSelector)]);
    }
#endif
}

#pragma mark -- FlexNode Methods
+ (FlexNode *)fhr_internalLoadRes:(NSString *)flexName
                            owner:(NSObject *)owner {
    //重连socket
    if (![FlexSocketManager sharedInstance].isConnecting) {
        [[FlexSocketManager sharedInstance] connect];
    }
    
    //判断服务是否开启
    FlexNode *localNode = [self loadNodeFromLocalHost:flexName owner:owner];
    if (localNode) {
        return localNode;
    }
    return [FlexNode fhr_internalLoadRes:flexName owner:owner];
}

//从localhost加载node
+ (FlexNode *)loadNodeFromLocalHost:(NSString *)flexName owner:(NSObject *)owner {
    if (![FlexSocketManager sharedInstance].connectToMapIpNormal) {
        //非wifi环境不连接
        return nil;
    }
    NSString *flexResourceKey = [NSString stringWithFormat:@"%@.xml", flexName];
    NSString *flexResourcePath = [FlexHotReloadUtil flexResourcePath:flexResourceKey];
    //判断是否有缓存
    NSData *cacheData = flexXmlCacheData[flexResourceKey];
    if (cacheData) {
        FlexNode *node = [FlexNode loadNodeData:cacheData];
        if (node) {
            FHRLogger([NSString stringWithFormat:@"flex use cache xml：%@", flexResourceKey]);
            return node;
        } else {
            return [FlexNode fhr_internalLoadRes:flexName owner:owner];
        }
    }
    //请求网络获取
    NSString *fileUrl = [NSString stringWithFormat:@"http://%@:8000/%@", [FlexHotReloadUtil getMacIp], flexResourcePath];
    NSData *xmlData = [FlexHotReloadUtil syncGetFlexHttpResource:fileUrl];
    FlexNode *node = nil;
    if (xmlData) {
        node = [FlexNode loadNodeData:xmlData];
        if (node == nil) {
            FHRLogger([NSString stringWithFormat:@"local xml：%@ parse error", fileUrl]);
        }
    } else {
        //没请求到数据，说明链接异常。需关闭当前链接
        [FlexSocketManager sharedInstance].connectToMapIpNormal = NO;
        FHRLogger(@"连接本地ip异常，关闭本地模式");
    }
    //添加满足，则返回node
    if (flexName.length && flexResourcePath.length) {
        if (node) {
            //将xmldata添加到缓存
            [flexXmlCacheData setObject:xmlData forKey:flexResourceKey];
            FHRLogger([NSString stringWithFormat:@"flex use local xml：%@", fileUrl]);
            return node;
        }
    }
    return nil;
}

@end
