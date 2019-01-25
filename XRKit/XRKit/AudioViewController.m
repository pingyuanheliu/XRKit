//
//  AudioViewController.m
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "AudioViewController.h"
#import "XRAudioPlayer.h"
#import "XRAudioPlayer+AudioQueue.h"
#import "XRAudioRecorder.h"
#import "XRAudioRecorder+AudioQueue.h"
#import "XRAudioUnit.h"

#import "XRPhoto.h"
#import "XRPhotoBrowser.h"

@interface AudioViewController ()

@property (nonatomic, strong) XRAudioPlayer *audioPlayer;
@property (nonatomic, strong) XRAudioRecorder *audioRecorder;
@property (nonatomic, strong) XRAudioUnit *audioUnit;

@end

@implementation AudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.audioPlayer = [[XRAudioPlayer alloc] init];
//    self.audioRecorder = [[XRAudioRecorder alloc] init];
    //首先向NSNotificationCenter添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __weak typeof(self) weakSelf = self;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session requestRecordPermission:^(BOOL granted) {
        if (granted) {
            NSLog(@"==YES==:%@",[NSThread currentThread]);
            weakSelf.audioUnit = [[XRAudioUnit alloc] init];
        }else {
            NSLog(@"==NO==:%@",[NSThread currentThread]);
        }
    }];
}

/**
 *  一旦输出改变则执行此方法
 *
 *  @param notification 输出改变通知对象
 */
-(void)routeChange:(NSNotification *)notification{
    NSLog(@"====notification:%@",[NSThread currentThread]);
    NSDictionary *userInfo = notification.userInfo;
    NSLog(@"===userInfo:%@",userInfo);
    id reasonKey = userInfo[AVAudioSessionRouteChangeReasonKey];
    if (reasonKey != nil && [reasonKey isKindOfClass:[NSNumber class]]) {
        switch ([reasonKey integerValue]) {
            case AVAudioSessionRouteChangeReasonUnknown://0
            {
                
            }
                break;
            case AVAudioSessionRouteChangeReasonNewDeviceAvailable://1
            {
                
            }
                break;
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable://2
            {
                
            }
                break;
            case AVAudioSessionRouteChangeReasonCategoryChange://3
            {
                
            }
                break;
            case AVAudioSessionRouteChangeReasonOverride://4
            {
                
            }
                break;
            case AVAudioSessionRouteChangeReasonWakeFromSleep://6
            {
                
            }
                break;
            case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory://7
            {
                
            }
                break;
            case AVAudioSessionRouteChangeReasonRouteConfigurationChange://8
            {
                
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - Click Item

- (IBAction)clickPlayItem:(UIBarButtonItem *)sender {
//    BOOL result = [self.audioPlayer startPlayer];
//    NSLog(@"result:%@",@(result));
//    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 1.0*NSEC_PER_SEC);
//    dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        [self readAudio];
//    });
//    [self.audioRecorder startAudioQueueRecord:nil];
    [self.audioUnit startAudioUnitPlayer];
}

- (IBAction)clickPauseItem:(UIBarButtonItem *)sender {
//    [self.audioPlayer stopPlayer];
//    [self.audioRecorder stopAudioQueueRecord];
    [self.audioUnit stopAudioUnitPlayer];
}

- (void)readAudio {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"output" ofType:@"caf"];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary *attr = [manager attributesOfItemAtPath:path error:nil];
    uint64_t total = attr.fileSize;
    NSLog(@"read total:%@",@(total));
//    uint64_t offset = 0;
    uint32_t size = 512;
    //
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];
    [inputStream open];
    //
    while (inputStream.hasBytesAvailable) {
        @autoreleasepool {
            NSMutableData *bufData = [[NSMutableData alloc] initWithCapacity:size];
            uint8_t *buffer = (uint8_t*)[bufData bytes];
            NSInteger read = [inputStream read:buffer maxLength:size];
            if (read > 0) {
                [self.audioPlayer addAudioBuffer:buffer length:read];
                //40*1000(40微秒)
                usleep(40000);
            }else {
                break;
            }
        }
    }
    NSLog(@"read end");
    [inputStream close];
}

#pragma mark -

- (IBAction)clickPhotoItem:(id)sender {
    XRPhoto *photo = [[XRPhoto alloc] init];
    NSArray *array = @[photo,photo,photo,photo,photo];
    XRPhotoBrowser *browerVC = [[XRPhotoBrowser alloc] initWithPhotos:array];
    [self.navigationController pushViewController:browerVC animated:YES];
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
