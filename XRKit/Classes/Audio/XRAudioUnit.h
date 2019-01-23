//
//  XRAudioUnit.h
//  XRKit
//
//  Created by LL on 2019/1/3.
//  Copyright © 2019年 LL. All rights reserved.
//

#import <AudioUnit/AudioUnit.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface XRAudioUnit : NSObject

/**
 开始录音
 */
- (BOOL)startAudioUnitRecorder;

/**
 停止录音
 */
- (BOOL)stopAudioUnitRecorder;

/**
 开始播放
 
 @return 结果
 */
- (BOOL)startAudioUnitPlayer;

/**
 停止播放
 
 @return 结果
 */
- (BOOL)stopAudioUnitPlayer;

@end
