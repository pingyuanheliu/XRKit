//
//  XRAudioRecorder+AudioQueue.h
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "XRAudioRecorder.h"

@interface XRAudioRecorder (AudioQueue)

/**
 开始录音
 
 @param receive 录音数据回调
 */
- (void)startAudioQueueRecord:(void (^)(AudioQueueBufferRef inBuffer))receive;

/**
 停止录音
 */
- (void)stopAudioQueueRecord;

@end
