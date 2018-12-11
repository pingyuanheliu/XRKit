//
//  XRAudioPlayer+AudioQueue.h
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "XRAudioPlayer.h"

@interface XRAudioPlayer (AudioQueue)

/**
 添加音频数据
 
 @param data 数据
 */
- (void)addAudioData:(NSData *)data;

/**
 添加音频数据
 
 @param bytes 数据
 @param length 长度
 */
- (void)addAudioBuffer:(const void *)bytes length:(NSUInteger)length;

/**
 开始播放
 
 @return 结果
 */
- (BOOL)startPlayer;

/**
 停止播放
 
 @return 结果
 */
- (BOOL)stopPlayer;

@end
