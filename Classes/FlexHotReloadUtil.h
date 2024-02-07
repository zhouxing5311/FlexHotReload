//
//  FlexHotReloadUtil.h
//  BossHi-RD
//
//  Created by 周兴 on 2022/7/21.
//

#import <Foundation/Foundation.h>

//是否开启热重载
#define FHROpenWhenDebug 1

extern NSMutableDictionary<NSString *, NSData*> *_Nullable flexXmlCacheData;


NS_ASSUME_NONNULL_BEGIN


@class FlexRootView;

//打日志
extern void FHRLogger(NSString *logString);

@interface FlexHotReloadUtil : NSObject

///更新服务端地址（可选，当配置了local_mac_ip后可以不用更新服务端地址）
+ (void)updateServerIP:(NSString *)ip;
///获取mac ip地址
+ (NSString *)getMacIp;
///判断能否访问电脑ip。超时1秒
+ (BOOL)isMacIpReachable;

///flex资源路径
+ (NSString *)flexResourcePath:(NSString *)name;
//同步访问localhost资源
+ (NSData *)syncGetFlexHttpResource:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
