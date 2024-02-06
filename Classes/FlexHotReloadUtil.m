//
//  FlexHotReloadUtil.m
//  BossHi-RD
//
//  Created by 周兴 on 2022/7/21.
//  Copyright © 2022 xucg. All rights reserved.
//

#import "FlexHotReloadUtil.h"
#import "FlexRootView.h"
#import "FlexSocketManager.h"

//flex xml资源缓存
NSMutableDictionary<NSString *, NSData*> *_Nullable flexXmlCacheData;
//flex name与path映射
NSDictionary<NSString*, NSString*> *_Nullable flexXmlPathMapData;
//服务ip
NSString *serverIP;

@implementation FlexHotReloadUtil

void FHRLogger(NSString *logString) {
    printf("[FHR]：%s\n", logString.UTF8String);
}

+ (void)load {
#ifdef DEBUG
    if (!FHROpenWhenDebug) return;
    
    //缓存初始化
    flexXmlCacheData = @{}.mutableCopy;
    
    //开始连接长连接
    [[FlexSocketManager sharedInstance] connect];
    
    //构建路径映射资源
    [self initXmlPathMapData];
#endif
}

+ (void)initXmlPathMapData {
    //构建本地路径缓存映射
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSString *xmlResourceUrl = [NSString stringWithFormat:@"http://%@:8000/xmlResource", [FlexHotReloadUtil getMacIp]];
    NSData *xmlData = [FlexHotReloadUtil syncGetFlexHttpResource:xmlResourceUrl];
    NSString *flexInfoString = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    NSArray<NSString *> *flexInfos = [flexInfoString componentsSeparatedByString:@"\n"];
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    FHRLogger([NSString stringWithFormat:@"加载xml资源耗时：%.2f", (endTime - startTime) * 1000]);
    
    //构建字典映射
    NSMutableDictionary *xmlInfoDict = @{}.mutableCopy;
    [flexInfos enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *currentInfo = [obj componentsSeparatedByString:@"/"];
        NSString *lastFilePath = currentInfo.lastObject;
        if (currentInfo.count > 1 && [lastFilePath containsString:@".xml"]) {
            [xmlInfoDict setObject:obj forKey:lastFilePath];
        }
    }];
    flexXmlPathMapData = xmlInfoDict.copy;
    FHRLogger([NSString stringWithFormat:@"本地xml资源映射构建完成，数量：%ld", flexXmlPathMapData.allKeys.count]);
}

+ (void)updateServerIP:(NSString *)ip {
    serverIP = ip;
    //开始连接长连接
    [[FlexSocketManager sharedInstance] updateMacIpNormal];
    [[FlexSocketManager sharedInstance] connect];
    //构建路径映射资源
    [self initXmlPathMapData];
}

+ (NSString *)getMacIp {
    if (serverIP.length) return serverIP;
    
    NSString *fileUrl = [[NSBundle mainBundle] pathForResource:@"local_mac_ip" ofType:@"txt"];
    NSString *ipInfo = [[NSString alloc] initWithContentsOfFile:fileUrl encoding:NSUTF8StringEncoding error:nil];
    NSArray<NSString *> *ips = [ipInfo componentsSeparatedByString:@"\n"];
    return ips.firstObject;
}

+ (NSString *)flexResourcePath:(NSString *)name {
    NSString *flexResourcePath = flexXmlPathMapData[name];
    return flexResourcePath;
}

+ (BOOL)isMacIpReachable {
    NSString *pingUrl = [NSString stringWithFormat:@"http://%@:8000", [FlexHotReloadUtil getMacIp]];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:pingUrl] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:1];
    NSURLResponse *response = nil;
    NSError *error = nil;

    [NSURLConnection sendSynchronousRequest:urlRequest
                          returningResponse:&response
                                      error:&error];
    

    if (error || ((NSHTTPURLResponse *)response).statusCode != 200) {
        return NO;
    }
    return YES;
}

//同步访问localhost资源
+ (NSData *)syncGetFlexHttpResource:(NSString *)urlString {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:1];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *resourceData = [NSURLConnection sendSynchronousRequest:urlRequest
                                                 returningResponse:&response
                                                             error:&error];
    if (error) {
        FHRLogger([NSString stringWithFormat:@"访问 %@ 失败，错误是 %@", urlString, error]);
        return nil;
    }
    return resourceData;
}

@end
