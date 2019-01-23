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

#import "XRPhoto.h"
#import "XRPhotoBrowser.h"

@interface AudioViewController ()

@property (nonatomic, strong) XRAudioPlayer *audioPlayer;
@property (nonatomic, strong) XRAudioRecorder *audioRecorder;

@end

@implementation AudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.audioPlayer = [[XRAudioPlayer alloc] init];
    self.audioRecorder = [[XRAudioRecorder alloc] init];
}

#pragma mark - Click Item

- (IBAction)clickPlayItem:(UIBarButtonItem *)sender {
//    BOOL result = [self.audioPlayer startPlayer];
//    NSLog(@"result:%@",@(result));
//    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 1.0*NSEC_PER_SEC);
//    dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        [self readAudio];
//    });
    [self.audioRecorder startAudioQueueRecord:nil];
}

- (IBAction)clickPauseItem:(UIBarButtonItem *)sender {
//    [self.audioPlayer stopPlayer];
    [self.audioRecorder stopAudioQueueRecord];
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
