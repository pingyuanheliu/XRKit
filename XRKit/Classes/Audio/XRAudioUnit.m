//
//  XRAudioUnit.m
//  XRKit
//
//  Created by LL on 2019/1/3.
//  Copyright © 2019年 LL. All rights reserved.
//

#import "XRAudioUnit.h"
#import <AVFoundation/AVFoundation.h>

#define kOutputBus  0
#define kInputBus   1

#define CONST_BUFFER_SIZE 2048*2*10

typedef NS_ENUM(NSInteger, XRAudioStatus) {
    XRAudioDefault = 0,     //默认状态
    XRAudioPlaying = 1,     //播放音频
    XRAudioRecording = 2,   //录制音频
};


@interface XRAudioUnit ()
{
    //描述
    AudioStreamBasicDescription _audioFormat;
    ExtAudioFileRef             _audioFileRef;
    AudioComponentInstance      _audioUnit;
    //播放音频输入流
    NSInputStream *_inputSteam;
    Byte *_buffer;
}
//音频状态
@property (nonatomic, assign) NSInteger audioStatus;
//录音回调
@property (nonatomic, strong) void (^receiveAudioBuffer)(AudioBuffer inBuffer);

@end

@implementation XRAudioUnit

#pragma mark - Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSError *error;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session requestRecordPermission:^(BOOL granted) {
            if (granted) {
                NSLog(@"==YES==");
            }else {
                NSLog(@"==NO==");
            }
        }];
        if (@available(iOS 10.0, *)) {
            [session setCategory:AVAudioSessionCategoryPlayAndRecord
                            mode:AVAudioSessionModeMeasurement
                         options:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
        }
        if (error != nil) {
            NSLog(@"error:%@",error);
        }
        [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
        if (error != nil) {
            NSLog(@"error:%@",error);
        }
        [self startAudioUnit];
        
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
    _audioFormat = audioFormat;
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

#pragma mark -

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
    OSStatus status;
    status = AudioUnitUninitialize(_audioUnit);
    if (status != noErr) {
        return status;
    }
    status = AudioComponentInstanceDispose(_audioUnit);
    return status;
}

#pragma mark - 录音文件保存路径

- (ExtAudioFileRef)audioFileRef {
    return _audioFileRef;
}

#pragma mark -
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

#pragma mark - 播放音频

- (void)openPlayFile {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"output" withExtension:@"caf"];
    _inputSteam = [NSInputStream inputStreamWithURL:url];
    if (_inputSteam != nil) {
        [_inputSteam open];
    }
    _buffer = malloc(CONST_BUFFER_SIZE);
}

- (void)closePlayFile {
    if (_inputSteam != nil) {
        [_inputSteam close];
        _inputSteam = nil;
    }
    free(_buffer);
}

#pragma mark - Recording Callback

/**
 录音回调

 @param inRefCon inRefCon
 @param ioActionFlags ioActionFlags
 @param inTimeStamp inTimeStamp
 @param inBusNumber inBusNumber
 @param inNumberFrames inNumberFrames
 @param ioData ioData
 @return 状态
 */
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    OSStatus status = noErr;
    @autoreleasepool {
        XRAudioUnit *recorder = (__bridge XRAudioUnit *)(inRefCon);
        AudioBufferList bufferList;
        UInt16 numSamples = inNumberFrames;
        UInt16 samples[numSamples];
        memset (&samples, 0, sizeof (samples));
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0].mData = samples;
        bufferList.mBuffers[0].mNumberChannels = 1;
        bufferList.mBuffers[0].mDataByteSize = numSamples*sizeof(UInt16);
        
        AudioComponentInstance audioUnit = [recorder audioUnit];
        
        status = AudioUnitRender(audioUnit,
                                 ioActionFlags,
                                 inTimeStamp,
                                 inBusNumber,
                                 inNumberFrames,
                                 &bufferList);
        AudioBuffer inBuffer = bufferList.mBuffers[0];
        if (inBuffer.mDataByteSize > 0) {
            if (recorder.receiveAudioBuffer) {
                recorder.receiveAudioBuffer(inBuffer);
            }
        }
        ExtAudioFileRef audioFileRef = [recorder audioFileRef];
        ExtAudioFileWriteAsync(audioFileRef, inNumberFrames, &bufferList);
    }
    return status;
}

#pragma mark - playing Callback

/**
 播放音频回调

 @param inRefCon inRefCon
 @param ioActionFlags ioActionFlags
 @param inTimeStamp inTimeStamp
 @param inBusNumber inBusNumber
 @param inNumberFrames inNumberFrames
 @param ioData ioData
 @return 状态
 */
static OSStatus playingCallback(void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList *ioData) {
    OSStatus status = noErr;
    @autoreleasepool {
        XRAudioUnit *audioUnit = (__bridge XRAudioUnit *)(inRefCon);
        //
        AudioBufferList bufferList;
        UInt16 numSamples = inNumberFrames;
        UInt16 samples[numSamples];
        memset (&samples, 0, sizeof (samples));
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0].mData = samples;
        bufferList.mBuffers[0].mNumberChannels = 1;
        bufferList.mBuffers[0].mDataByteSize = numSamples*sizeof(UInt16);
        //
        UInt32 size = numSamples*sizeof(UInt16);
        NSInteger bytes = size < ioData->mBuffers[1].mDataByteSize * 2 ? size : ioData->mBuffers[1].mDataByteSize * 2;
        bytes = [audioUnit->_inputSteam read:audioUnit->_buffer maxLength:bytes];
        for (int i = 0; i < bytes; ++i) {
            ((Byte*)ioData->mBuffers[1].mData)[i/2] = audioUnit->_buffer[i];
        }
        ioData->mBuffers[1].mDataByteSize = (UInt32)bytes / 2;
        
        if (ioData->mBuffers[1].mDataByteSize < ioData->mBuffers[0].mDataByteSize) {
            ioData->mBuffers[0].mDataByteSize = ioData->mBuffers[1].mDataByteSize;
        }
    }
    return status;
}

#pragma mark - Set Callback

/**
 设置录音

 @param on 是否开启
 @return 状态
 */
- (OSStatus)setRecorderCallBack:(BOOL)on {
    //设置属性
    UInt32 enable;
    if (on) {
        enable = 1;
    }else {
        enable = 0;
    }
    OSStatus status;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &enable,
                                  sizeof(enable));
    if (status != noErr) {
        return status;
    }
    // Set input callback
    AURenderCallbackStruct recorderStruct;
    if (on) {
        recorderStruct.inputProc = recordingCallback;
        recorderStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    }else {
        recorderStruct.inputProc = 0;
        recorderStruct.inputProcRefCon = 0;
    }
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &recorderStruct,
                                  sizeof(recorderStruct));
    return status;
}


/**
 设置播放

 @param on 是否开启
 @return 状态
 */
- (OSStatus)setPlayerCallBack:(BOOL)on {
    //设置属性
    UInt32 enable;
    if (on) {
        enable = 0;
    }else {
        enable = 0;
    }
    OSStatus status;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &enable,
                                  sizeof(enable));
    if (status != noErr) {
        return status;
    }
    // Set output callback
    AURenderCallbackStruct playerStruct;
    if (on) {
        playerStruct.inputProc = playingCallback;
        playerStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    }else {
        playerStruct.inputProc = 0;
        playerStruct.inputProcRefCon = 0;
    }
    //设置属性
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &playerStruct,
                                  sizeof(playerStruct));
    return status;
}

#pragma mark - Public Methods

- (AudioComponentInstance)audioUnit {
    return _audioUnit;
}

#pragma mark -
- (OSStatus)startAudioUnit {
    AudioComponentDescription description = [self audioComponent];
    AudioComponent foundIoUnitReference = AudioComponentFindNext(NULL, &description);
    OSStatus status = AudioComponentInstanceNew(foundIoUnitReference, &_audioUnit);
    if (status != noErr) {
        return status;
    }
    AudioStreamBasicDescription audioDesc = [self pcmAudioStreamDescription];
    status = [self setStreamFormat:audioDesc];
    if (status != noErr) {
        return status;
    }
    UInt32 disable = 0;
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &disable,
                                  sizeof(disable));
    //
    return status;
}

- (OSStatus)stopAudioUnit {
    OSStatus status;
    AudioStreamBasicDescription audioDesc = [self resetAudioStreamDescription];
    status = [self setStreamFormat:audioDesc];
    NSLog(@"stop audio 1 status:%@",@(status));
    status = AudioOutputUnitStop(_audioUnit);
    NSLog(@"stop audio 2 status:%@",@(status));
    status = AudioUnitUninitialize(_audioUnit);
    NSLog(@"stop audio 3 status:%@",@(status));
    status = AudioComponentInstanceDispose(_audioUnit);
    NSLog(@"stop audio 4 status:%@",@(status));
    status = ExtAudioFileDispose(_audioFileRef);
    NSLog(@"stop audio 5 status:%@",@(status));
    return status;
}


#pragma mark -

- (void)listenRecordedData:(void (^)(AudioBuffer inBuffer))recorded {
    
}

#pragma mark -
/**
 开始录音
 */
- (BOOL)startAudioUnitRecorder {
    if (self.audioStatus & XRAudioRecording) {
        //已经在录音
        return NO;
    }
    //创建本地录音保存文件
    [self createSaveFile];
    //开启录音
    OSStatus status = [self setRecorderCallBack:YES];
    if (status == noErr) {
        self.audioStatus = (self.audioStatus | XRAudioRecording);
        return YES;
    }else {
        return NO;
    }
}

/**
 停止录音
 */
- (BOOL)stopAudioUnitRecorder {
    if (self.audioStatus & XRAudioRecording) {//已经在录音
        //停止录音
        OSStatus status = [self setRecorderCallBack:NO];
        if (status == noErr) {
            if (self.audioStatus & XRAudioPlaying) {
                //在播放
                self.audioStatus = XRAudioPlaying;
            }else {
                //不在播放
                self.audioStatus = XRAudioDefault;
            }
            //释放录音文件
            [self releaseSaveFile];
            return YES;
        }else {
            return NO;
        }
    }
    return NO;
}

#pragma mark -
/**
 开始播放
 
 @return 结果
 */
- (BOOL)startAudioUnitPlayer {
    if (self.audioStatus & XRAudioPlaying) {
        //已经在播放
        return NO;
    }
    OSStatus status = [self setPlayerCallBack:YES];
    if (status == noErr) {
        status = [self setRecorderCallBack:NO];
        if (status == noErr) {
            status = AudioUnitInitialize(_audioUnit);
            if (status != noErr) {
                return NO;
            }
            status = AudioOutputUnitStart(_audioUnit);
            if (status != noErr) {
                return NO;
            }
            self.audioStatus = (self.audioStatus | XRAudioPlaying);
            return YES;
        }else {
            return NO;
        }
    }else {
        return NO;
    }
}

/**
 停止播放
 
 @return 结果
 */
- (BOOL)stopAudioUnitPlayer {
    if (self.audioStatus & XRAudioPlaying) {//已经在播放
        OSStatus status = [self setPlayerCallBack:NO];
        if (status == noErr) {
            if (self.audioStatus & XRAudioRecording) {
                //在录音
                self.audioStatus = XRAudioRecording;
            }else {
                //不在录音
                self.audioStatus = XRAudioDefault;
            }
            return YES;
        }else {
            return NO;
        }
    }
    return NO;
}

@end
