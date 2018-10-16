//
//  XRCameraViewController.h
//  XRKit
//
//  Created by LL on 2018/10/15.
//  Copyright © 2018年 LL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XRCameraManager.h"

@interface XRCameraViewController : UIViewController

//相机输出类型
@property (nonatomic, assign) XRCameraType cameraType;

/**
 在view显示相机视图
 
 @param view 视图
 */
- (void)showCameraInView:(UIView *)view;

/**
 移除相机视图
 */
- (void)removeCameraView;

/**
 开始相机运行
 */
- (void)startCameraRunning;

/**
 停止相机
 */
- (void)stopCameraRunning;

/**
 切换相机输出类型
 
 @param type 类型
 */
- (void)changeCameraType:(XRCameraType)type;

/**
 切换相机摄像头
 */
- (void)changeCameraPosition;

/**
 进入前台
 
 @param notification 通知
 */
- (void)willEnterForeground:(NSNotification *)notification;

/**
 进入后台
 
 @param notification 通知
 */
- (void)didEnterBackground:(NSNotification *)notification;

@end
