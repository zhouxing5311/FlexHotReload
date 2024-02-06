//
//  FlexSocketManager.m
//  BossHi-RD
//
//  Created by 周兴 on 2022/7/21.
//  Copyright © 2022 xucg. All rights reserved.
//

#import "FlexSocketManager.h"
#import "FlexHotReloadUtil.h"

#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface FlexSocketManager()

@property (nonatomic, assign) int clientScoket;
@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, strong) dispatch_queue_t socketQueue;

@end

@implementation FlexSocketManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static FlexSocketManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        //子线程开启socket连接
        self.socketQueue = dispatch_queue_create("com.bosshi.flexhotreload", NULL);
        //设置初始网络状态
        [self updateMacIpNormal];
    }
    return self;
}

- (void)updateMacIpNormal {
    self.connectToMapIpNormal = [FlexHotReloadUtil isMacIpReachable];
}

- (void)initScoket {
    //非wifi环境不连接
    if (!self.connectToMapIpNormal) {
        FHRLogger(@"非wifi环境，无法连接FileWatcher");
        return;
    }
    //每次连接前，先断开连接
    if (_clientScoket != 0) {
        [self disConnect];
        _clientScoket = 0;
    }

    //创建客户端socket
    _clientScoket = CreateClinetSocket();

    //服务器Ip
    const char *server_ip = [FlexHotReloadUtil getMacIp].UTF8String;
    //服务器端口
    short server_port = 8178;
    //等于0说明连接失败
    if (ConnectionToServer(_clientScoket,server_ip, server_port)==0) {
        FHRLogger(@"Connect to server error");
        return ;
    }
    //走到这说明连接成功
    FHRLogger(@"Connect to server ok");
    self.isConnecting = YES;
    
    //开始接收消息
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self recieveAction];
    });
    
    //发送版本信息
    NSString *name = [UIDevice currentDevice].name;
    NSString *version = [UIDevice currentDevice].systemVersion;
    [self sendMsg:[NSString stringWithFormat:@"%@(%@)", name, version]];
    
    //暂时先不心跳，防止断点调试时无法心跳
//    [self heartBeats];
}

- (void)setConnectToMapIpNormal:(BOOL)connectToMapIpNormal {
    if (_connectToMapIpNormal != connectToMapIpNormal) {
        _connectToMapIpNormal = connectToMapIpNormal;
        if (_connectToMapIpNormal) {
            //连接正常，尝试重连socket
            if (!self.isConnecting) {
                [self connect];
            }
            FHRLogger(@"开始连接电脑ip");
        } else {
            FHRLogger(@"无法连接电脑ip");
            //关闭socket连接
            [[FlexSocketManager sharedInstance] disConnect];
        }
    }
}

static int CreateClinetSocket(void) {
    int ClinetSocket = 0;
    //创建一个socket,返回值为Int。（注scoket其实就是Int类型）
    //第一个参数addressFamily IPv4(AF_INET) 或 IPv6(AF_INET6)。
    //第二个参数 type 表示 socket 的类型，通常是流stream(SOCK_STREAM) 或数据报文datagram(SOCK_DGRAM)
    //第三个参数 protocol 参数通常设置为0，以便让系统自动为选择我们合适的协议，对于 stream socket 来说会是 TCP 协议(IPPROTO_TCP)，而对于 datagram来说会是 UDP 协议(IPPROTO_UDP)。
    ClinetSocket = socket(AF_INET, SOCK_STREAM, 0);
    return ClinetSocket;
}

static int ConnectionToServer(int client_socket,const char * server_ip,unsigned short port) {

    //生成一个sockaddr_in类型结构体
    struct sockaddr_in sAddr={0};
    sAddr.sin_len=sizeof(sAddr);
    //设置IPv4
    sAddr.sin_family=AF_INET;

    //inet_aton是一个改进的方法来将一个字符串IP地址转换为一个32位的网络序列IP地址
    //如果这个函数成功，函数的返回值非零，如果输入地址不正确则会返回零。
    inet_aton(server_ip, &sAddr.sin_addr);

    //htons是将整型变量从主机字节顺序转变成网络字节顺序，赋值端口号
    sAddr.sin_port=htons(port);

    //用scoket和服务端地址，发起连接。
    //客户端向特定网络地址的服务器发送连接请求，连接成功返回0，失败返回 -1。
    //注意：该接口调用会阻塞当前线程，直到服务器返回。
    if (connect(client_socket, (struct sockaddr *)&sAddr, sizeof(sAddr)) == 0) {
        return client_socket;
    }
    return 0;
}

#pragma mark - Methods
- (void)heartBeats {
    //开启心跳
    [self destroyHeart];
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}

- (void)destroyHeart {
    if (self.connectTimer) {
        [self.connectTimer invalidate];
        self.connectTimer = nil;
    }
}

- (void)longConnectToSocket {
    [self sendMsg:@"i am here"];
}

#pragma mark - 对外逻辑
- (void)connect {
    if (!self.connectToMapIpNormal) {
        return;
    }
    dispatch_async(self.socketQueue, ^{
        [self initScoket];
    });
}

- (void)disConnect {
    //关闭连接
    close(self.clientScoket);
    [self destroyHeart];
}

//发送消息
- (void)sendMsg:(NSString *)msg {
    const char *send_Message = [msg UTF8String];
    ssize_t sendLen = send(self.clientScoket, send_Message, strlen(send_Message)+1,0);
    if (sendLen == -1) {
        FHRLogger(@"与socket断开连接，无法发送");
        return;
    }
    FHRLogger([NSString stringWithFormat:@"发送消息：%@", msg]);
}

//收取服务端发送的消息
- (void)recieveAction {
    while (1) {
        char recv_Message[1024] = {0};
        ssize_t recvLen = recv(self.clientScoket, recv_Message, sizeof(recv_Message), 0);
        if (recvLen == -1) {
            //与socket断开连接，跳出循环
            FHRLogger(@"与socket断开连接");
            [self disConnect];
            self.isConnecting = NO;
            break;
        }
        if (recvLen == 0) {
            continue;
        }
        if (self.fileChangeBlock) {
            self.fileChangeBlock([[NSString alloc] initWithUTF8String:recv_Message]);
        }
        FHRLogger([NSString stringWithFormat:@"收到消息：%s", recv_Message]);
    }
}

@end
