//
//  FlexSocketManager.h
//  BossHi-RD
//
//  Created by 周兴 on 2022/7/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FHRFileChangeBlock)(NSString *fileName);

@interface FlexSocketManager : NSObject

@property (nonatomic, assign) BOOL isConnecting;
@property (nonatomic, assign) BOOL connectToMapIpNormal;///连接localhost是否正常
@property (nonatomic, copy) FHRFileChangeBlock fileChangeBlock;

+ (instancetype)sharedInstance;
- (void)connect;
- (void)disConnect;
- (void)updateMacIpNormal;
- (void)sendMsg:(NSString *)msg;

@end

NS_ASSUME_NONNULL_END
