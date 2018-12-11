//
//  XRAudioRecorder.h
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface XRAudioRecorder : NSObject
{
    AudioStreamBasicDescription  _audioFormat;
    AudioQueueRef                _inputQueue;
    AudioQueueBufferRef          _inputBuffers[3];
    AudioFileID                  _audioFile;
    //
    AudioComponentInstance       _audioUnit;
    ExtAudioFileRef              _audioFileRef;
}

@property (nonatomic, assign, getter=isRecording) BOOL recording;

@property (nonatomic, assign) SInt64 currentPacket;

@property (nonatomic, strong) void (^receiveBuffer)(AudioQueueBufferRef inBuffer);
@property (nonatomic, strong) void (^receiveAudioBuffer)(AudioBuffer inBuffer);
@property (nonatomic, strong) void (^receiveData)(NSData *data);

- (AudioFileID)currentFileID;
- (AudioComponentInstance)audioUnit;
- (ExtAudioFileRef)audioFileRef;

@end
