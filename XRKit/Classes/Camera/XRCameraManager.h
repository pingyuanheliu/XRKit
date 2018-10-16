//
//  XRCameraManager.h
//  XRKit
//
//  Created by LL on 2018/10/15.
//  Copyright © 2018年 LL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//相机类型
typedef NS_ENUM(NSInteger, XRCameraType) {
    XRCameraDefault = 0,        //默认
    XRCameraPhoto = 1 << 0,     //照片
    XRCameraVideo = 1 << 1,     //视频
    XRCameraQRcode = 1 << 2,    //二维码
};

//相机管理代理类
@protocol XRCameraManagerDelegate <NSObject>

@optional
//图像样本缓存数据输出
- (void)xr_didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

@protocol XRCameraManagerDataSource <NSObject>

@optional
//二维码识别区域
- (CGRect)xr_qr_interestRect;

@end

//相机管理类
@interface XRCameraManager : NSObject

//代理
@property (nonatomic, weak) id <XRCameraManagerDelegate> delegate;
@property (nonatomic, weak) id <XRCameraManagerDataSource> dataSource;
//相机类型
@property (nonatomic, assign) XRCameraType cameraType;

/**
 在view显示相机视图
 
 @param view 视图
 @param type 相机类型
 */
- (void)xr_showCameraInView:(UIView *)view type:(XRCameraType)type;

/**
 移除相机视图
 */
- (void)xr_removeCameraView;

/**
 开始相机运行
 */
- (void)xr_startCameraRunning;

/**
 停止相机
 */
- (void)xr_stopCameraRunning;

/**
 切换相机摄像头
 */
- (void)xr_changeCameraPosition;

/**
 获取图像数据
 
 @param complete 完成回调
 */
- (void)xr_captureImageData:(void(^)(NSData *data))complete;

@end
