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
        _audioUnit = nil;
//        self.audioStatus = XRAudioPlaying;
        self.audioStatus = XRAudioRecording;
//        self.audioStatus = XRAudioPlaying | XRAudioRecording;
    }
    return self;
}

#pragma mark - Setter

- (void)setAudioStatus:(NSInteger)audioStatus {
    _audioStatus = audioStatus;
    //状态
    OSStatus status;
    //开始
    if (_audioStatus != XRAudioDefault) {
        //1-I、改变Session分类
        [self setAudioSessionCategory];
        //2-I、AudioComponent Instance New
        status = [self createAudioInstance];
        
        //format property
        status = [self setAudioUnitProperty];
        
        //3-I、Initialize
        status = AudioUnitInitialize(_audioUnit);
        //4-I、Start
        status = AudioOutputUnitStart(_audioUnit);
    }
    //停止
    if (_audioStatus == XRAudioDefault) {
        //4-D、Stop
        status = AudioOutputUnitStop(_audioUnit);
        //3-D、Uninitialize
        status = AudioUnitUninitialize(_audioUnit);
        //2-D、AudioComponent Instance Dispose
        status = [self disposeAudioInstance];
        //1-D、改变Session分类
        [self setAudioSessionCategory];
    }
}

#pragma mark - Audio Session

/**
 自定义AudioSession
 */
- (void)setAudioSessionCategory {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSLog(@"session:%@",session.category);
    //
    BOOL playing = (self.audioStatus & XRAudioPlaying);
    BOOL recording = (self.audioStatus & XRAudioRecording);
    if (@available(iOS 10.0, *)) {
        if (playing && recording) {
            //既播放，也录音
            [session setCategory:AVAudioSessionCategoryPlayAndRecord
                            mode:AVAudioSessionModeVideoChat
                         options:AVAudioSessionCategoryOptionDefaultToSpeaker
                           error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
            [session setActive:YES
                         error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
        }else if (playing) {
            //仅播放
            [session setCategory:AVAudioSessionCategoryPlayback
                            mode:AVAudioSessionModeSpokenAudio
                         options:AVAudioSessionCategoryOptionMixWithOthers
                           error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
            [session setActive:YES
                         error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
        }else if (recording) {
            //仅录音
            [session setCategory:AVAudioSessionCategoryRecord
                            mode:AVAudioSessionModeMeasurement
                         options:AVAudioSessionCategoryOptionAllowBluetooth
                           error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
            [session setActive:YES
                         error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
        }else {
            //既不播放，也不录音
            [session setCategory:AVAudioSessionCategorySoloAmbient
                            mode:AVAudioSessionModeDefault
                         options:0
                           error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
            [session setActive:NO
                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                         error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
        }
    }else {
        if (playing && recording) {
            //既播放，也录音
            [session setCategory:AVAudioSessionCategoryPlayAndRecord
                           error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
            [session setActive:YES
                         error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
        }else if (playing) {
            //仅播放
            [session setCategory:AVAudioSessionCategoryPlayback
                           error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
            [session setActive:YES
                         error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
        }else if (recording) {
            //仅录音
            [session setCategory:AVAudioSessionCategoryRecord
                           error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
            [session setActive:YES
                         error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
        }else {
            //既不播放，也不录音
            [session setCategory:AVAudioSessionCategorySoloAmbient
                           error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
            [session setActive:NO
                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                         error:&error];
            if (error != nil) {
                NSLog(@"error:%@",error);
            }
        }
    }
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

 @return 结果
 */
- (OSStatus)setAudioUnitProperty {
    OSStatus status;
    AudioStreamBasicDescription format = [self pcmAudioStreamDescription];
    // 输入
    status = AudioUnitSetProperty(_audioUnit,
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
    if (status != noErr) {
        return status;
    }
    //设置Callback
    if (_audioStatus & XRAudioPlaying) {
        status = [self setPlayerCallBack:YES];
    } else {
        status = [self setPlayerCallBack:NO];
    }
    if (status != noErr) {
        return status;
    }
    if (_audioStatus & XRAudioRecording) {
        status = [self setRecorderCallBack:YES];
    } else {
        status = [self setRecorderCallBack:NO];
    }
    if (status != noErr) {
        return status;
    }
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    UInt32 flag = 0;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
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
    if (_audioUnit == nil) {
        AudioComponentDescription description = [self audioComponent];
        AudioComponent foundIoUnitReference = AudioComponentFindNext(NULL, &description);
        OSStatus status = AudioComponentInstanceNew(foundIoUnitReference, &_audioUnit);
        return status;
    } else {
        OSStatus status;
        //4-D、Stop
        status = AudioOutputUnitStop(_audioUnit);
        if (status != noErr) {
            return status;
        }
        //3-D、Uninitialize
        status = AudioUnitUninitialize(_audioUnit);
        return status;
    }
}

- (OSStatus)disposeAudioInstance {
    OSStatus status;
    status = AudioComponentInstanceDispose(_audioUnit);
    _audioUnit = nil;
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
        enable = 1;
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
