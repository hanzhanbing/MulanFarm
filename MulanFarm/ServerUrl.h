//
//  ServerUrl.h
//  ArtEast
//
//  Created by yibao on 16/9/30.
//  Copyright © 2016年 北京艺宝网络文化有限公司. All rights reserved.
//

#ifndef ServerUrl_h
#define ServerUrl_h

#define InterfaceHtml @"http://farmapp.daweichang.com/farm/bin/doc/farm_api.pdf"

#define AESSecret @"F$0.%a~+r^#=`M|?" //加密密钥

#pragma mark - ---------------接口地址---------------

#define ProductUrl @"http://farmapp.daweichang.com/farm/controller/api/"


#pragma mark - ---------------接口名称---------------

#define URL_Login @"user.php?m=login" //登录
#define URL_Register @"user.php?m=reg" //注册
#define URL_FindPwd @"user.php?m=findPwd" //找回密码
#define URL_FindPwdVerify @"user.php?m=findPwdVerify" //找回密码验证
#define URL_UpdatePwd @"user.php?m=updatePwd" //修改密码
#define URL_Logout @"user.php?m=logout" //退出登录
#define URL_UpdateUserInfo @"user.php?m=updateProfile" //修改信息
#define URL_Agreement @"appinfo.php?m=agreement" //用户协议
#define URL_AboutUs @"appinfo.php?m=aboutUs" //关于我们
#define URL_AppInfo @"appinfo.php?m=appInfo" //程序信息
#define URL_SignIn @"user.php?m=signIn" //签到
#define URL_UploadAvatar @"user.php?m=uploadAvatar" //上传头像
#define URL_SendEmailCaptcha @"user.php?m=sendEmailCaptcha" //发送邮箱验证码
#define URL_CameraList @"camera.php?m=list" //摄像头列表
#define URL_CameraBind @"camera.php?m=bind" //绑定摄像头
#define URL_CameraSelect @"camera.php?m=select" //选择摄像头
#define URL_CameraDelete @"camera.php?m=delete" //删除摄像头
#define URL_SaveNote @"note.php?m=save" //保存笔记
#define URL_NoteList @"note.php?m=list" //笔记列表
#define URL_ArticleList @"article.php?m=list" //文章列表
#define URL_ArchiveList @"archive.php?m=list" //档案列表
#define URL_ArchiveDetaile @"archive.php?m=detail" //档案详情
#define URL_ArchiveEdit @"archive.php?m=update" //修改档案
#define URL_ArchiveDelete @"archive.php?m=delete" //删除档案
#define URL_UploadAlbum @"archive.php?m=uploadAlbum" //上传图册
#define URL_DeleteAlbum @"archive.php?m=deleteAlbum"  //删除相册
#define URL_MsgList @"user.php?m=msgList" //消息列表

#define URL_Recharge @"account.php?m=topup" //充值
#define URL_Transfer @"account.php?m=transfer" //转账
#define URL_Query @"account.php?m=query" //查询余额
#define URL_PayQuery @"account.php?m=payQuery" //查询充值结果

#endif /* ServerUrl_h */
