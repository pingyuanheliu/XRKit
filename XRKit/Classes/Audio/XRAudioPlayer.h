//
//  XRAudioPlayer.h
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, XRAudioState) {
    XRAudioStateStop = 0,   //停止
    XRAudioStatePause,      //暂停
    XRAudioStatePlay,       //播放
};

@interface XRAudioPlayer : NSObject
{
    AudioStreamBasicDescription _audioFormat;
    AudioQueueRef _outputQueue;//音频播放队列
    AudioQueueBufferRef _outputBuffers[3];
}

//音频播放状态
@property (nonatomic, assign) XRAudioState state;
//音频锁
@property (nonatomic, strong) NSLock *audioLock;
//音频数据
@property (nonatomic, strong) NSMutableData *audioData;

/**
 音频流信息基本描述
 
 @return 描述对象
 */
- (AudioStreamBasicDescription)audioStreamDescription;

@end
