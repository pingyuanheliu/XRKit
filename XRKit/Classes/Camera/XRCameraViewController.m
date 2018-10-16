//
//  XRCameraViewController.m
//  XRKit
//
//  Created by LL on 2018/10/15.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "XRCameraViewController.h"

@interface XRCameraViewController ()

@property (nonatomic, strong) XRCameraManager *cameraManager;

@end

@implementation XRCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.cameraManager = [[XRCameraManager alloc] init];
    self.cameraType = XRCameraDefault;
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //添加相机视图
    [self showCameraInView:self.view];
    //App进入前台通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    //App进入后台通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //App进入前台通知
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    //App进入后台通知
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - Get & Set

- (void)setCameraType:(XRCameraType)cameraType {
    if (_cameraType == cameraType) {
        return;
    }
    _cameraType = cameraType;
    [self changeCameraType:cameraType];
}

#pragma mark -
/**
 在view显示相机视图
 
 @param view 视图
 */
- (void)showCameraInView:(UIView *)view {
    [self.cameraManager xr_showCameraInView:view type:self.cameraType];
}

/**
 移除相机视图
 */
- (void)removeCameraView {
    [self.cameraManager xr_removeCameraView];
}

/**
 开始相机运行
 */
- (void)startCameraRunning {
    [self.cameraManager xr_startCameraRunning];
}

/**
 停止相机
 */
- (void)stopCameraRunning {
    [self.cameraManager xr_stopCameraRunning];
}

/**
 切换相机输出类型

 @param type 类型
 */
- (void)changeCameraType:(XRCameraType)type {
    [self.cameraManager setCameraType:type];
}

/**
 切换相机摄像头
 */
- (void)changeCameraPosition {
    [self.cameraManager xr_changeCameraPosition];
}

#pragma mark -

/**
 进入前台
 
 @param notification 通知
 */
- (void)willEnterForeground:(NSNotification *)notification {
    //开始
    [self startCameraRunning];
}

/**
 进入后台
 
 @param notification 通知
 */
- (void)didEnterBackground:(NSNotification *)notification {
    //停止
    [self stopCameraRunning];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
