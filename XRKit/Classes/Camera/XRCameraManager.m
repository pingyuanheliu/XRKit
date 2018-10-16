//
//  XRCameraManager.m
//  XRKit
//
//  Created by LL on 2018/10/15.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "XRCameraManager.h"

@interface XRCameraManager ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;

@end

@implementation XRCameraManager

//单例
static dispatch_once_t onceToken;
static id instance;

#pragma mark - 单例模式
/**
 单例模式
 */
+ (XRCameraManager *)shareManager {
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}


/**
 尝试释放
 */
+ (void)share_dealloc {
    onceToken = 0;
    instance = nil;
}

#pragma mark - Life Cycle

- (void)dealloc {
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cameraType = XRCameraDefault;
    }
    return self;
}

#pragma mark - Get & Set

/**
 设置相机类型

 @param cameraType 相机类型
 */
- (void)setCameraType:(XRCameraType)cameraType {
    if (_cameraType == cameraType) {
        return;
    }
    //设置当前类型
    _cameraType = cameraType;
    //修改输出流
    if (_session != nil) {
        //开始配置session
        [_session beginConfiguration];
        //重置输出流配置
        [self retsetOutputConfiguration];
        //结束配置session
        [_session commitConfiguration];
    }
}

#pragma mark - Methods

/**
 二维码扫描有效区域

 @return 有效区域
 */
- (CGRect)qr_rectOfInterest {
    CGSize tsize = [UIScreen mainScreen].bounds.size;
    CGSize ssize = CGSizeMake(200.0, 200.0);
    CGFloat x = (tsize.width - ssize.width)/2.0;
    CGFloat y = (tsize.height - ssize.height)/2.0;
    CGRect crect = CGRectMake(x, y, ssize.width, ssize.height);
    //(y,x,h,w)
    x = crect.origin.y/tsize.height;
    y = crect.origin.x/tsize.width;
    CGFloat width = crect.size.height/tsize.height;
    CGFloat height = crect.size.width/tsize.width;
    CGRect irect = CGRectMake(x, y, width, height);
    return irect;
}

/**
 获取相机设备
 
 @param position 摄像头位置
 @return 相机设备
 */
- (AVCaptureDevice *)captureDeviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

/**
 重置Input配置
 */
- (void)retsetInputConfiguration {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        //判断session是否为空
        if (_session == nil) {
            return;
        }
        //移除旧有的输入流
        for (AVCaptureInput *input in _session.inputs) {
            [_session removeInput:input];
        }
        //添加新的输入流
        AVCaptureDevice *device = [self captureDeviceWithPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        if (input == nil) {
            return;
        }
        if ([_session canAddInput:input]) {
            [_session addInput:input];
        }
    }
}

/**
 重置Output配置
 */
- (void)retsetOutputConfiguration {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        //判断session是否为空
        if (_session == nil) {
            return;
        }
        //移除旧有的输出流
        for (AVCaptureOutput *output in _session.outputs) {
            //移除视频样本输出代理
            if ([output isKindOfClass:[AVCaptureVideoDataOutput class]]) {
                AVCaptureVideoDataOutput *videoOutput = (AVCaptureVideoDataOutput *)output;
                [videoOutput setSampleBufferDelegate:nil queue:NULL];
            }
            //移除视频样本输出代理
            if ([output isKindOfClass:[AVCaptureMetadataOutput class]]) {
                AVCaptureMetadataOutput *videoOutput = (AVCaptureMetadataOutput *)output;
                [videoOutput setMetadataObjectsDelegate:nil queue:NULL];
            }
            [_session removeOutput:output];
        }
        //添加新的输出流
        if (_cameraType & XRCameraPhoto) {
            //拍照
            AVCaptureStillImageOutput *output = [[AVCaptureStillImageOutput alloc] init];
            if ([_session canAddOutput:output]) {
                [_session addOutput:output];
            }
        }
        if (_cameraType & XRCameraVideo) {
            //视频输出
            AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            [output setSampleBufferDelegate:self queue:queue];
            NSNumber *bgra = [NSNumber numberWithInt:kCVPixelFormatType_32BGRA];
            output.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:bgra, kCVPixelBufferPixelFormatTypeKey, nil];
            if ([_session canAddOutput:output]) {
                [_session addOutput:output];
            }
        }
        if (_cameraType & XRCameraQRcode) {
            //二维码扫描
            AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
            dispatch_queue_t queue = dispatch_get_main_queue();
            [output setMetadataObjectsDelegate:self queue:queue];
            if ([_session canAddOutput:output]) {
                [_session addOutput:output];
                NSArray *available = output.availableMetadataObjectTypes;
                if ([available containsObject:AVMetadataObjectTypeQRCode]) {
                    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
                    //识别区域
                    if (self.dataSource && [self.dataSource respondsToSelector:@selector(xr_qr_interestRect)]) {
                        CGRect rect = [self.dataSource xr_qr_interestRect];
                        output.rectOfInterest = rect;
                    }
                }
            }
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (sampleBuffer == NULL) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(xr_didOutputSampleBuffer:)]) {
        [self.delegate xr_didOutputSampleBuffer:sampleBuffer];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *codeObject = [metadataObjects firstObject];
        NSLog(@"code:%@",codeObject);
        NSString *string = codeObject.stringValue;
        NSLog(@"string:%@",string);
        [self xr_stopCameraRunning];
    }
}

#pragma mark - Public

/**
 在view显示相机视图
 
 @param view 视图
 @param type 相机类型
 */
- (void)xr_showCameraInView:(UIView *)view type:(XRCameraType)type {
    if (_preview != nil) {
        //修改位置显示
        [view.layer insertSublayer:_preview atIndex:0];
    }else {
        NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        if ([videoDevices count] > 0) {
            //创建session
            if (_session == nil) {
                _session = [[AVCaptureSession alloc] init];
                [_session setSessionPreset:AVCaptureSessionPresetHigh];
            }
            //开始配置session
            [_session beginConfiguration];
            //重置Input配置
            [self retsetInputConfiguration];
            //重置Output配置
            [self retsetOutputConfiguration];
            //结束配置session
            [_session commitConfiguration];
            //配置Layer层显示
            _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
            _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
            _preview.frame = view.bounds;
            [view.layer insertSublayer:_preview atIndex:0];
            //启动
            [self xr_startCameraRunning];
        }
    }
}

/**
 移除相机视图
 */
- (void)xr_removeCameraView {
    if (_preview != nil) {
        [_preview removeFromSuperlayer];
        _preview = nil;
    }
}

#pragma mark -
/**
 开始相机运行
 */
- (void)xr_startCameraRunning {
    if (![_session isRunning]) {
        [_session startRunning];
    }
}

/**
 停止相机
 */
- (void)xr_stopCameraRunning {
    if ([_session isRunning]) {
        [_session stopRunning];
    }
}

#pragma mark -

/**
 切换相机摄像头
 */
- (void)xr_changeCameraPosition {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if ([videoDevices count] > 0) {
        if (_session != nil) {
            if (_session.inputs.count == 0) {
                return;
            }
            AVCaptureDeviceInput *oinput = [_session.inputs firstObject];
            AVCaptureDevicePosition position;
            if (oinput.device.position == AVCaptureDevicePositionBack) {
                position = AVCaptureDevicePositionFront;
            }else {
                position = AVCaptureDevicePositionBack;
            }
            AVCaptureDevice *device = [self captureDeviceWithPosition:position];
            //开始session配置
            [_session beginConfiguration];
            //移除旧有的输入流
            [_session removeInput:oinput];
            // 添加新的输入流
            AVCaptureDeviceInput *ninput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            if ([_session canAddInput:ninput]) {
                [_session addInput:ninput];
            }
            //结束session配置
            [_session commitConfiguration];
        }
    }
}

#pragma mark -

/**
 获取图像数据
 
 @param complete 完成回调
 */
- (void)xr_captureImageData:(void(^)(NSData *data))complete {
    for (AVCaptureOutput *output in _session.outputs) {
        if ([output isKindOfClass:[AVCaptureStillImageOutput class]]) {
            AVCaptureStillImageOutput *imageOutput = (AVCaptureStillImageOutput *)output;
            AVCaptureConnection *connection = [imageOutput connectionWithMediaType:AVMediaTypeVideo];
            [imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
                if (imageDataSampleBuffer == NULL) {
                    return ;
                }
                __block NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (complete) {
                        complete(imageData);
                    }
                });
            }];
            break;
        }
    }
}

@end
