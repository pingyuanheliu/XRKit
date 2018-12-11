//
//  XRAudioPlayer.m
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "XRAudioPlayer.h"

@implementation XRAudioPlayer

#pragma mark - Life Cycle

- (void)dealloc
{
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _audioData = [[NSMutableData alloc] init];
        _audioLock = [[NSLock alloc] init];
        //
        [self customInitSession];
    }
    return self;
}

#pragma mark - Method

/**
 初始化音频会话
 */
- (void)customInitSession {
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    [audioSession setPreferredSampleRate:8000.0 error:&error];
    [audioSession setPreferredInputNumberOfChannels:1 error:&error];
    [audioSession setPreferredOutputNumberOfChannels:1 error:&error];
    [audioSession setPreferredIOBufferDuration:0.02 error:&error];
    [audioSession setActive:YES error:&error];
}

/**
 音频流信息基本描述

 @return 描述对象
 */
- (AudioStreamBasicDescription)audioStreamDescription
{
    AudioStreamBasicDescription audioFormat;
    //重置下
    memset(&audioFormat, 0, sizeof(audioFormat));
    //设置format，怎么称呼不知道。
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    //这个屌属性不知道干啥的。，
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    //采样率的意思是每秒需要采集的帧数
    audioFormat.mSampleRate = 8000.0;
    //设置通道数,这里先使用系统的测试下
    audioFormat.mChannelsPerFrame = 1;
    //每个通道里，一帧采集的bit数目
    audioFormat.mBitsPerChannel = 16;
    //
    audioFormat.mBytesPerFrame = audioFormat.mChannelsPerFrame * sizeof(SInt16);
    //
    audioFormat.mFramesPerPacket = 1;
    //
    audioFormat.mBytesPerPacket = audioFormat.mBytesPerFrame;
    return audioFormat;
}

@end
