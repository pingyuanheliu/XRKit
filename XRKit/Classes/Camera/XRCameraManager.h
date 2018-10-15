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
    XRCameraDefault = 0,    //默认
    XRCameraPhoto,          //照片
    XRCameraVideo,          //视频
    XRCameraQRcode,         //二维码
};

//相机管理代理类
@protocol XRCameraManagerDelegate <NSObject>

@optional
//图像样本缓存数据输出
- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

//相机管理类
@interface XRCameraManager : NSObject

//代理
@property (nonatomic, weak) id <XRCameraManagerDelegate> delegate;
//相机类型
@property (nonatomic, assign) XRCameraType cameraType;

@end
