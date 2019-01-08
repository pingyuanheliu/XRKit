//
//  XRAudioRecorder+AudioUnit.m
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "XRAudioRecorder+AudioUnit.h"

#define kOutputBus 0
#define kInputBus 1

@implementation XRAudioRecorder (AudioUnit)

#pragma mark - Recording Callback
static OSStatus AURecordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    OSStatus status = noErr;
    @autoreleasepool {
        XRAudioRecorder *recorder = (__bridge XRAudioRecorder *)(inRefCon);
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

#pragma mark - 录音文件保存路径

/**
 创建音频保存路径
 */
- (void)au_createSaveFilePath {
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
        NSLog(@"==create file path success==");
    }else {
        NSLog(@"==create file path failed ==");
    }
    CFRelease(audioFileURL);
}

#pragma mark -

/**
 自定义初始化
 */
- (void)customInitAudioUint {
    //定义音频流基本描述
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
    //
    //
    AudioComponentDescription ioUnitDescription;
    ioUnitDescription.componentType = kAudioUnitType_Output;
    ioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags = 0;
    ioUnitDescription.componentFlagsMask = 0;
    //
    AudioComponent foundIoUnitReference = AudioComponentFindNext(NULL, &ioUnitDescription);
    //
    OSStatus status = AudioComponentInstanceNew(foundIoUnitReference, &_audioUnit);
    if (status != noErr) {
        return;
    }
    // Enable IO for recording
    UInt32 enable = 1;
    UInt32 disable = 0;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &enable,
                                  sizeof(enable));
    if (status != noErr) {
        return;
    }
    // Apply format
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &_audioFormat,
                                  sizeof(_audioFormat));
    if (status != noErr) {
        return;
    }
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &disable,
                                  sizeof(disable));
    if (status != noErr) {
        return;
    }
    //
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &_audioFormat,
                                  sizeof(_audioFormat));
    if (status != noErr) {
        return;
    }
    // Set input callback
    AURenderCallbackStruct recorderStruct;
    recorderStruct.inputProc = AURecordingCallback;
    recorderStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &recorderStruct,
                                  sizeof(recorderStruct));
    if (status != noErr) {
        return;
    }
    // Set output callback
    //Remove a callback for playing
    AURenderCallbackStruct playerStruct;
    playerStruct.inputProc = 0;
    playerStruct.inputProcRefCon = 0;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &playerStruct,
                                  sizeof(playerStruct));
    if (status != noErr) {
        return;
    }
}

#pragma mark -

/**
 开始录音
 
 @param receive 录音数据回调
 */
- (void)startAudioUnitRecord:(void (^)(AudioBuffer inBuffer))receive {
    if (!self.isRecording) {
        self.recording = YES;
        self.receiveAudioBuffer = receive;
        //自定义音频描述
        [self customInitAudioUint];
        //创建音频保存路径
        [self au_createSaveFilePath];
        // Initialise
        OSStatus status = AudioUnitInitialize(_audioUnit);
        NSLog(@"status:%@",@(status));
        //开始录制音频
        status = AudioOutputUnitStart(_audioUnit);
        NSLog(@"status:%@",@(status));
    }
}

/**
 停止录音
 */
- (void)stopAudioUnitRecord {
    if (self.isRecording) {
        self.recording = NO;
        OSStatus status = AudioOutputUnitStop(_audioUnit);
        NSLog(@"status:%@",@(status));
        status = AudioUnitUninitialize(_audioUnit);
        NSLog(@"status:%@",@(status));
        status = AudioComponentInstanceDispose(_audioUnit);
        NSLog(@"status:%@",@(status));
        status = ExtAudioFileDispose(_audioFileRef);
        NSLog(@"status:%@",@(status));
        self.receiveAudioBuffer = nil;
    }
}


@end
