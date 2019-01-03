//
//  XRAudioUnit.m
//  XRKit
//
//  Created by LL on 2019/1/3.
//  Copyright © 2019年 LL. All rights reserved.
//

#import "XRAudioUnit.h"

#define kOutputBus  0
#define kInputBus   1

@interface XRAudioUnit ()
{
    //
    AudioStreamBasicDescription _audioFormat;
    ExtAudioFileRef             _audioFileRef;
    AudioComponentInstance      _audioUnit;
}

@end

@implementation XRAudioUnit

#pragma mark - Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _audioFormat = [self pcmAudioStreamDescription];
    }
    return self;
}

#pragma mark - Format
/**
 音频流信息基本描述
 
 @return 描述对象
 */
- (AudioStreamBasicDescription)pcmAudioStreamDescription
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

/**
 重置音频流信息基本描述
 
 @return 描述对象
 */
- (AudioStreamBasicDescription)resetAudioStreamDescription
{
    AudioStreamBasicDescription audioFormat;
    //重置下
    memset(&audioFormat, 0, sizeof(audioFormat));
    return audioFormat;
}

#pragma mark -

/**
 设置音频格式

 @param format 格式
 @return 结果
 */
- (OSStatus)setStreamFormat:(AudioStreamBasicDescription)format {
    // Apply format
    // 输入
    OSStatus status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &format,
                                  sizeof(format));
    if (status != noErr) {
        return status;
    }
    // 输出
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  1,
                                  &format,
                                  sizeof(format));
    return status;
}

#pragma mark - Component

/**
 音频组件描述

 @return 描述
 */
- (AudioComponentDescription)audioComponent {
    AudioComponentDescription ioUnitDescription;
    ioUnitDescription.componentType = kAudioUnitType_Output;
    ioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags = 0;
    ioUnitDescription.componentFlagsMask = 0;
    return ioUnitDescription;
}

- (OSStatus)createAudioInstance {
    AudioComponentDescription description = [self audioComponent];
    AudioComponent foundIoUnitReference = AudioComponentFindNext(NULL, &description);
    OSStatus status = AudioComponentInstanceNew(foundIoUnitReference, &_audioUnit);
    if (status != noErr) {
        return status;
    }
    status = AudioUnitInitialize(_audioUnit);
    return status;
}

- (OSStatus)disposeAudioInstance {
    OSStatus status = AudioComponentInstanceDispose(_audioUnit);
    if (status != noErr) {
        return status;
    }
    status = AudioUnitUninitialize(_audioUnit);
    return status;
}

#pragma mark - 录音文件保存路径

/**
 创建音频保存对象
 */
- (void)createSaveFile {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *tgtPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.caf"];
    if ([manager fileExistsAtPath:tgtPath]) {
        [manager removeItemAtPath:tgtPath error:nil];
    }
    [manager createFileAtPath:tgtPath contents:nil attributes:nil];
    NSLog(@"tgtPath:%@",tgtPath);
    CFStringRef path;
    path = CFStringCreateWithCString (NULL, [tgtPath UTF8String], kCFStringEncodingUTF8);
    CFURLRef audioFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, false);
    CFRelease(path);
    AudioFileTypeID fileType = kAudioFileCAFType;
    OSStatus status = ExtAudioFileCreateWithURL(audioFileURL, fileType, &_audioFormat, NULL, kAudioFileFlags_EraseFile, &_audioFileRef);
    if (status == noErr) {
        NSLog(@"==create save file success==");
    }else {
        NSLog(@"==create save file error==");
    }
    CFRelease(audioFileURL);
}


/**
 释放频保存对象
 */
- (void)releaseSaveFile {
    if (_audioFileRef != NULL) {
        OSStatus status = ExtAudioFileDispose(_audioFileRef);
        if (status == noErr) {
            NSLog(@"==realease save file success==");
        }else {
            NSLog(@"==realease save file error==");
        }
    }
}

#pragma mark - Recording Callback
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    OSStatus status = noErr;
    
    return status;
}

#pragma mark - playing Callback
static OSStatus playingCallback(void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList *ioData) {
    OSStatus status = noErr;
    
    return status;
}

#pragma mark - Set Callback

- (OSStatus)setCallBack {
    // Set input callback
    AURenderCallbackStruct recorderStruct;
    recorderStruct.inputProc = recordingCallback;
    recorderStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    OSStatus status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &recorderStruct,
                                  sizeof(recorderStruct));
    if (status != noErr) {
        return status;
    }
    // Set output callback
    AURenderCallbackStruct playerStruct;
    playerStruct.inputProc = playingCallback;
    playerStruct.inputProcRefCon = 0;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &playerStruct,
                                  sizeof(playerStruct));
    return status;
}

@end
