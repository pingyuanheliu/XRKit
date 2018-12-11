//
//  XRAudioPlayer+AudioQueue.m
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "XRAudioPlayer+AudioQueue.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation XRAudioPlayer (AudioQueue)

/**
 音频播放回调

 @param inUserData 用户对象
 @param inAQ 音频队列
 @param inBuffer 音频缓存
 */
static void HandleOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    XRAudioPlayer *player = (__bridge XRAudioPlayer *)inUserData;
    [player handleAudioQueue:inAQ queueBuffer:inBuffer];
}

/**
 计算缓存大小

 @param inAQ 音频队列
 @param ASBDescription 音频流描述
 @param seconds 时长
 @param outBufferSize 缓存大小
 */
static void DeriveBufferSize(AudioQueueRef inAQ, AudioStreamBasicDescription *ASBDescription, Float64 seconds, UInt32 *outBufferSize) {
    static const int maxBufferSize = 512;
    
    int maxPacketSize = (*ASBDescription).mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(inAQ, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numBytesForTime = (*ASBDescription).mSampleRate * maxPacketSize * seconds;
    *outBufferSize = numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize;
}

#pragma mark -

//把缓冲区置空
static void MakeSilent(AudioQueueBufferRef buffer)
{
    for (int i = 0; i < buffer->mAudioDataBytesCapacity; i++) {
        buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
        UInt8 *samples = (UInt8 *)buffer->mAudioData;
        samples[i] = 0;
    }
}


#pragma mark -

/**
 处理播放的音频数据

 @param inAQ 队列
 @param inBuffer 缓存
 */
- (void)handleAudioQueue:(AudioQueueRef)inAQ queueBuffer:(AudioQueueBufferRef)inBuffer {
    [self.audioLock lock];
    NSLog(@"handle Audio Queue 1");
    NSUInteger length = [self.audioData length];
    if (length > 0) {
        NSRange range;
        if (length > 512) {
            range = NSMakeRange(0, 512);
        }else {
            range = NSMakeRange(0, length);
        }
        NSData *tmp = [self.audioData subdataWithRange:range];
        memcpy(inBuffer->mAudioData, tmp.bytes, tmp.length);
        inBuffer->mAudioDataByteSize = (UInt32)tmp.length;
        inBuffer->mPacketDescriptionCount = 0;
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
        //删除音频数据
        [self.audioData replaceBytesInRange:range withBytes:NULL length:0];
    }else {
        MakeSilent(inBuffer);
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
    NSLog(@"handle Audio Queue 2");
    [self.audioLock unlock];
}

#pragma mark -

/**
 添加音频数据

 @param data 数据
 */
- (void)addAudioData:(NSData *)data {
    [self.audioLock lock];
    if ([data length] > 0) {
        [self.audioData appendData:data];
    }
    [self.audioLock unlock];
}

/**
 添加音频数据
 
 @param bytes 数据
 @param length 长度
 */
- (void)addAudioBuffer:(const void *)bytes length:(NSUInteger)length {
    [self.audioLock lock];
    NSLog(@"add audio:%@",@(length));
    [self.audioData appendBytes:bytes length:length];
    [self.audioLock unlock];
}

#pragma mark -

/**
 开始播放

 @return 结果
 */
- (BOOL)startPlayer {
    NSLog(@"==startPlayer begin==");
    //音频流基本描述
    _audioFormat = [self audioStreamDescription];
    //创建输出队列
    OSStatus status = AudioQueueNewOutput(&_audioFormat, HandleOutputCallback, (__bridge void * _Nullable)(self), CFRunLoopGetMain(), kCFRunLoopDefaultMode, 0, &_outputQueue);
    NSLog(@"==1==");
    if (status != noErr) {
        return NO;
    }
    //创建录制音频队列缓冲区
    UInt32 bufferByteSize;
    DeriveBufferSize(_outputQueue, &_audioFormat, 0.5,  &bufferByteSize);
    for (int i = 0; i < 3; i++) {
        AudioQueueAllocateBuffer (_outputQueue, bufferByteSize, &_outputBuffers[i]);
        MakeSilent(_outputBuffers[i]);
        AudioQueueEnqueueBuffer (_outputQueue, (_outputBuffers[i]), 0, NULL);
    }
    NSLog(@"==2==");
    //音量
    Float32 gain = 5.0;
    status = AudioQueueSetParameter(_outputQueue, kAudioQueueParam_Volume, gain);
    if (status != noErr) {
        return NO;
    }
    NSLog(@"==3==");
    //开启播放队列
    status = AudioQueueStart(_outputQueue, NULL);
    if (status != noErr) {
        return NO;
    }
    self.state = XRAudioStatePlay;
    NSLog(@"==startPlayer end==");
    return YES;
}

/**
 停止播放

 @return 结果
 */
- (BOOL)stopPlayer {
    AudioQueueStop(_outputQueue, NO);
    AudioQueueDispose(_outputQueue, NO);
    self.state = XRAudioStateStop;
    return YES;
}

@end
