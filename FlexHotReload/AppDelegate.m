//
//  AppDelegate.m
//  FlexHotReload
//
//  Created by 周兴 on 2024/2/6.
//

#import "AppDelegate.h"
#import "ViewController.h"

#ifdef DEBUG

#import "FlexHotReloadUtil.h"
#import "FlexSocketManager.h"

#endif

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    ViewController *vc = [[ViewController alloc] init];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
    navVC.navigationBar.translucent = NO;
    self.window.rootViewController = navVC;
    
    
#ifdef DEBUG
    //获取本机ip方式
    /*
     方式1：工程中build phase配置script
     将local_mac_ip.txt导入工程中，并将其添加到.gitignore忽略文件中
     */
    
    /*
     方式2：自定义ip设置
     会有代码提交问题，因为每个人的电脑ip不一致，使用此方法时会忽略local_mac_ip.txt中的配置
     */
//    [FlexHotReloadUtil updateServerIP:@"10.252.10.1"];
    
    
    
    //监听网络状态变化，当网络状态变动时重连FileWatcher（通过AFN等监听网络变化）
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChangeAcion) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    
//    [FlexSocketManager sharedInstance].connectToMapIpNormal = NO;//4g时关闭
//    [[FlexSocketManager sharedInstance] updateMacIpNormal];//wifi时尝试重连
    
#endif
    
    return YES;
}


@end
