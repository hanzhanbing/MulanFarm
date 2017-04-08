//
//  FarmVC.m
//  MulanFarm
//
//  Created by zyl on 17/3/9.
//  Copyright © 2017年 cydf. All rights reserved.
//

#import "FarmVC.h"
#import "BellListVC.h"
#import "MD5.h"
#import "P2PClient.h"
#import "OpenGLView.h"
#import "Util.h"
#import "BackProtocol.h"
#import "CameraListVC.h"
#import "ArchiveInfo.h"
#import "RecordDetailVC.h"

//以下是 用户账号密码 设备id和密码,不保证一直有用,请使用您自己的账号密码和设备
#define UserName @"0810090"
#define UserPswd @"111222"
#define DeviceId @"7019032"
#define DevicePw @"abc123"

@interface FarmVC ()<P2PClientDelegate,BackProtocol>{
    NSString* _p2pcode1;
    NSString* _p2pcode2;
    NSString* _userIDName;//用户的id号
    BOOL _hadInitDevice;//是否连接设备
    BOOL _hadLogin;//是否成功登录
    BOOL _isReject;//是否挂断了
    
    /**
     这个错误提示是来自P2PCInterface.h里的 dwErrorOption枚举,
     写在这里只是为了更好的展示错误信息,实际开发的时候请不要像我这样用这种不好的编程习惯
     */
    NSArray<NSString*>* _errorStrings;
    
    CameraInfo *cameraInfo;
}

@end

@implementation FarmVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"农场";
    
    [self setNavBar];
    
    self.clearNoteBtn.layer.borderColor = AppThemeColor.CGColor;
    self.clearNoteBtn.layer.borderWidth = 1;
    self.clearNoteBtn.layer.cornerRadius = 5;
    [self.clearNoteBtn.layer setMasksToBounds:YES];
    
    _isReject=YES;
    _errorStrings=@[
                    @"没有发生错误",
                    @"对方的ID 被禁用",
                    @"对方的ID 过期了",
                    @"对方的ID 尚未激活",
                    @"对方离线",
                    @"对方忙线中",
                    @"对方已关机",
                    @"没有找到协助人",
                    @"对方已经挂断",
                    @"连接超时",
                    @"内部错误",
                    @"无人接听",
                    @"密码错误",
                    @"连接失败",
                    @"连接不支持"
                    ];
    
    [self startLogin];//开始登录
    [[P2PClient sharedClient] setDelegate:self];
}

- (void)setNavBar {
    
    self.bellCountLab.layer.cornerRadius = self.bellCountLab.width/2;
    [self.bellCountLab.layer setMasksToBounds:YES];
    
    self.signBtn.layer.borderWidth = 1;
    self.signBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    self.signBtn.layer.cornerRadius = 5;
    [self.signBtn.layer setMasksToBounds:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//添加摄像头
- (IBAction)addCameraBtn:(id)sender {
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CameraListVC *vc = [story instantiateViewControllerWithIdentifier:@"CameraList"];
    vc.hidesBottomBarWhenPushed = YES;
    vc.backDelegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

//消息中心
- (IBAction)bellAction:(id)sender {
    
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    BellListVC *vc = [story instantiateViewControllerWithIdentifier:@"BellList"];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

//签到
- (IBAction)signAction:(id)sender {
    [[NetworkManager sharedManager] postJSON:URL_SignIn parameters:nil completion:^(id responseData, RequestState status, NSError *error) {
        
        if (status == Request_Success) {
            [Utils showToast:@"签到成功"];
        }
    }];
}

//查看档案
- (IBAction)showRecordAction:(id)sender {
    
    ArchiveInfo *info = [[ArchiveInfo alloc] init];
    info.ID = cameraInfo.archive_id;
    RecordDetailVC *vc = (RecordDetailVC *)[Utils GetStordyVC:@"Main" WithStordyID:@"RecordDetailVC"];
    vc.info = info;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)clearNoteAction:(id)sender {
    
    _titleTF.text = nil;
    _contentTF.text = @"输入内容";
}

- (IBAction)saveNoteAction:(id)sender {
    
    if ([Utils isBlankString:_titleTF.text]) {
        [Utils showToast:@"请输入笔记标题"];
        return;
    }
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         _titleTF.text, @"title",
                         _contentTF.text,@"content",
                         nil];
    [[NetworkManager sharedManager] postJSON:URL_SaveNote parameters:dic imageDataArr:nil imageName:nil completion:^(id responseData, RequestState status, NSError *error) {
        
        if (status == Request_Success) {
            [Utils showToast:@"保存成功"];
            
            [JHHJView hideLoading]; //结束加载
            
            _titleTF.text = nil;
            _contentTF.text = nil;
        } else {
            [Utils showToast:@"保存失败"];
        }
    }];
}

#pragma mark - BackProtocol 扫码回调代理

- (void)backAction:(CameraInfo *)info {
    
    cameraInfo = info;
    
    _petLab.text = cameraInfo.name;
    
    NSLog(@"摄像头对应档案ID：%@",info.archive_id);
    
}

#pragma mark - 摄像头

//开始监控
- (void)startMoni {
    
    if (_isReject&&_hadLogin&&_hadInitDevice) {
        //[Utils showToast:@"发送呼叫命令"];
        [[P2PClient sharedClient] setIsBCalled:NO];
        [[P2PClient sharedClient] setP2pCallState:P2PCALL_STATUS_CALLING];
        
        /**设备密码采用了加密算法加密处理,这样密码有字母也不怕了*/
        [[P2PClient sharedClient] p2pCallWithId:DeviceId
                                       password:[NSString stringWithFormat:@"%ud",[Util GetTreatedPassword:DevicePw]]
                                       callType:P2PCALL_TYPE_MONITOR];
    }
}

//停止监控
- (void)stopMoni {
    
    if (!_isReject) {
        //[Utils showToast:@"发送挂断命令"];
        _isReject=YES;
        [[P2PClient sharedClient] p2pHungUp];
    }
}

-(void)connectDevice{
    if (_hadLogin) {//只有登录了才去连接设备
        if (!_hadInitDevice) {
            //[Utils showToast:@"正在初始化设备"];
            _hadInitDevice=[[P2PClient sharedClient] p2pConnectWithId:_userIDName codeStr1:_p2pcode1 codeStr2:_p2pcode2];
            NSString* result=[NSString stringWithFormat:@"初始化连接设备 %@",_hadInitDevice?@"成功,你可以操作设备了":@"失败,你将不能操作设备"];
            //[Utils showToast:result];
        }
        
        [self startMoni];//开始监控
    }
}

#pragma mark - 协议的实现

- (void)P2PClientCalling:(NSDictionary*)info{
    NSString* str=[NSString stringWithFormat:@"正在呼叫,%@,解释:%@",
                   [self stringFromDic:info],
                   [self stringErrorByError:[info[@"ErrorOption"] integerValue]]];
    //[Utils showToast:str];
}

- (void)P2PClientReject:(NSDictionary*)info{
    _isReject=YES;
    NSString* str=[NSString stringWithFormat:@"视频挂断,%@,解释:%@",
                   [self stringFromDic:info],
                   [self stringErrorByError:[info[@"ErrorOption"] integerValue]]];
    //[Utils showToast:str];
}

- (void)P2PClientAccept:(NSDictionary*)info{
    NSString* str=[NSString stringWithFormat:@"接收数据,%@,解释:%@",
                   [self stringFromDic:info],
                   [self stringErrorByError:[info[@"ErrorOption"] integerValue]]];
    //[Utils showToast:str];
}

- (void)P2PClientReady:(NSDictionary*)info{
    NSString* str=[NSString stringWithFormat:@"准备就绪,%@,解释:%@",
                   [self stringFromDic:info],
                   [self stringErrorByError:[info[@"ErrorOption"] integerValue]]];
    [Utils showToast:str];
    
    //开始渲染
    [[P2PClient sharedClient] setP2pCallState:P2PCALL_STATUS_READY_P2P];
    
    if([[P2PClient sharedClient] p2pCallType]==P2PCALL_TYPE_MONITOR){
        //连接就绪之后就开始启动渲染
        [self monitorStartRender];
    }
}

#pragma mark - 准备渲染监控界面
-(void)monitorStartRender{
    [Utils showToast:@"渲染>>>你可以看到画面了"];
    _isReject = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self renderView];
    });
    [[PAIOUnit sharedUnit] setMuteAudio:NO];
    [[PAIOUnit sharedUnit] setSpeckState:YES];
}

#pragma mark - 开始渲染监控画面
- (void)renderView
{
    GAVFrame * m_pAVFrame;
    while (!_isReject)
    {
        if(fgGetVideoFrameToDisplay(&m_pAVFrame))
        {
            [_remoteView render:m_pAVFrame];
            vReleaseVideoFrame();
        }
        usleep(10000);
    }
}

#pragma mark - 登录相关
/**开始登录*/
-(void)startLogin{
    
    /**
     登录的方法不是这个demo的重点,此处不详细介绍,欲知详情,请查看登录的demo
     */

    //[Utils showToast:@"正在登录"];
    
    /**    可供使用的服务器地址:
     api1.cloudlinks.cn
     api2.cloudlinks.cn
     api3.cloud-links.net
     api4.cloud-links.net
     */
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    NSURL* URL = [NSURL URLWithString:@"http://api1.cloudlinks.cn/Users/LoginCheck.ashx"];
    NSDictionary* URLParams = @{
                                @"AppOS": @"2",
                                @"AppVersion":[NSString stringWithFormat:@"%d",2<<24|7<<16|3<<8|4],
                                @"User":UserName,
                                @"Pwd": [MD5 md5_32bit:UserPswd],
                                @"Opion": @"GetParam",
                                @"VersionFlag": @" ",
                                };
    URL = NSURLByAppendingQueryParameters(URL, URLParams);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                NSDictionary* jsonDic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                //                NSLog(@"返回结果:%@",jsonDic);
                NSString* errCode=jsonDic[@"error_code"];
                if ([errCode isEqualToString:@"0"]) {//返回0即认为是登录成功
                    _hadLogin=YES;
                    //[Utils showToast:@"登录成功"];
                    //拿到登录成功之后的2个p2p连接码和用户名
                    _userIDName=[NSString stringWithFormat:@"%d",(int)[jsonDic[@"UserID"] integerValue]&0x7fffffff];//用户id就是这样得到的
                    _p2pcode1=jsonDic[@"P2PVerifyCode1"];
                    _p2pcode2=jsonDic[@"P2PVerifyCode2"];
                    [self connectDevice];//开始连接p2p
                    
                }else{
                    _hadLogin=NO;
                    [Utils showToast:@"登录失败,对设备的操作将无效,失败原因:"];
                    NSString* theErrStr=jsonDic[@"error"];
                    //[Utils showToast:theErrStr];
                }
            }
            else {
                _hadLogin=NO;
                NSString* fal=@"登录失败,对设备的操作将无效,失败原因:";
                fal=[fal stringByAppendingString:[error localizedDescription]];
                //[Utils showToast:fal];
            }
        });
    }];
    [task resume];//发起任务,开始登录
}

/**
 从字典参数拼接地址
 */
static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

/**
 创建一个带参数的URL地址串
 */
static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
                           [URL absoluteString],
                           NSStringFromQueryParameters(queryParameters)
                           ];
    NSURL* theUrl=[NSURL URLWithString:URLString];
    return theUrl;
}

-(NSString*)stringFromDic:(NSDictionary*)dic{
    NSString* str=@"";
    if (dic) {
        NSData* data=[NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        str=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return str;
}

-(NSString*)stringErrorByError:(NSInteger)error{
    return _errorStrings[error];
}

@end
