//
//  XRAudioRecorder+AudioQueue.m
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "XRAudioRecorder+AudioQueue.h"

@implementation XRAudioRecorder (AudioQueue)

//录音回调
void AQRecordingCallback(void                               *inUserData,
                         AudioQueueRef                      inAQ,
                         AudioQueueBufferRef                inBuffer,
                         const AudioTimeStamp               *inStartTime,
                         UInt32                             inNumberPackets,
                         const AudioStreamPacketDescription *inPacketDescs)
{
    XRAudioRecorder *recorder = (__bridge XRAudioRecorder *)(inUserData);
    if (inNumberPackets > 0) {
        if (inBuffer->mAudioDataByteSize > 0) {
            if (recorder.receiveBuffer) {
                recorder.receiveBuffer(inBuffer);
            }
        }
    }
    AudioFileID fileID = [recorder currentFileID];
    OSStatus status = AudioFileWritePackets(fileID, false, inBuffer->mAudioDataByteSize, inPacketDescs, recorder.currentPacket, &inNumberPackets, inBuffer->mAudioData);
    if (status == noErr) {
        recorder.currentPacket += inNumberPackets;
    }
    if (!recorder.isRecording) {
        return;
    }
    AudioQueueEnqueueBuffer (inAQ, inBuffer, 0, NULL);
}

void DeriveBufferSize (AudioQueueRef audioQueue, AudioStreamBasicDescription *ASBDescription, Float64 seconds, UInt32 *outBufferSize) {
    static const int maxBufferSize = 512;
    
    int maxPacketSize = (*ASBDescription).mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numBytesForTime = (*ASBDescription).mSampleRate * maxPacketSize * seconds;
    *outBufferSize = numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize;
}

#pragma mark - Method

/**
 自定义音频描述
 */
- (void)customAudioStreamBasicDescription {
    //重置下
    memset(&_audioFormat, 0, sizeof(_audioFormat));
    //设置format，怎么称呼不知道。
    _audioFormat.mFormatID = kAudioFormatLinearPCM;
    //这个屌属性不知道干啥的。，
    _audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    //采样率的意思是每秒需要采集的帧数
    _audioFormat.mSampleRate = 8000.0;
    //设置通道数,这里先使用系统的测试下 //TODO:
    _audioFormat.mChannelsPerFrame = 1;
    //每个通道里，一帧采集的bit数目
    _audioFormat.mBitsPerChannel = 16;
    //
    _audioFormat.mBytesPerFrame = _audioFormat.mChannelsPerFrame * sizeof (SInt16);
    //
    _audioFormat.mFramesPerPacket = 1;
    //
    _audioFormat.mBytesPerPacket = _audioFormat.mBytesPerFrame;
}

/**
 创建录音保存文件路径
 */
- (void)aq_createSaveFilePath {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *tgtPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.caf"];
    if ([manager fileExistsAtPath:tgtPath]) {
        [manager removeItemAtPath:tgtPath error:nil];
    }
    [manager createFileAtPath:tgtPath contents:nil attributes:nil];
    NSLog(@"tgtPath:%@",tgtPath);
    AudioFileTypeID fileType = kAudioFileCAFType;
    CFStringRef path;
    path = CFStringCreateWithCString (NULL, [tgtPath UTF8String], kCFStringEncodingUTF8);
    CFURLRef audioFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, false);
    CFRelease(path);
    OSStatus status = AudioFileCreateWithURL(audioFileURL, fileType, &_audioFormat, kAudioFileFlags_EraseFile, &_audioFile);
    if (status == noErr) {
        NSLog(@"==create file path success==");
    }else {
        NSLog(@"==create file path failed ==");
    }
    CFRelease(audioFileURL);
}

#pragma mark -

/**
 开始录音

 @param receive 录音数据回调
 */
- (void)startAudioQueueRecord:(void (^)(AudioQueueBufferRef inBuffer))receive {
    if (!self.isRecording) {
        self.recording = YES;
        self.receiveBuffer = receive;
        self.currentPacket = 0;
        //自定义音频描述
        [self customAudioStreamBasicDescription];
        //创建音频保存路径
        [self aq_createSaveFilePath];
        //创建一个录制音频队列
        AudioQueueNewInput (&(_audioFormat), AQRecordingCallback, (__bridge void *)self, NULL, NULL, 0, &_inputQueue);
        //创建录制音频队列缓冲区
        UInt32 bufferByteSize;
        DeriveBufferSize(_inputQueue, &_audioFormat, 0.5,  &bufferByteSize);
        for (int i = 0; i < 3; i++) {
            AudioQueueAllocateBuffer (_inputQueue, bufferByteSize, &_inputBuffers[i]);
            AudioQueueEnqueueBuffer (_inputQueue, (_inputBuffers[i]), 0, NULL);
        }
        //音量
        Float32 gain = 5.0;
        AudioQueueSetParameter(_inputQueue, kAudioQueueParam_Volume, gain);
        //开启录制队列
        AudioQueueStart(_inputQueue, NULL);
    }
}

/**
 停止录音
 */
- (void)stopAudioQueueRecord {
    if (self.isRecording) {
        self.recording = NO;
        AudioQueueStop(_inputQueue, NO);
        AudioQueueDispose(_inputQueue, NO);
        AudioFileClose(_audioFile);
        self.receiveBuffer = nil;
    }
}

@end
