//
//  XRAudioRecorder.m
//  XRKit
//
//  Created by LL on 2018/12/11.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "XRAudioRecorder.h"

@implementation XRAudioRecorder

- (AudioFileID)currentFileID {
    return _audioFile;
}

- (AudioComponentInstance)audioUnit {
    return _audioUnit;
}

- (ExtAudioFileRef)audioFileRef {
    return _audioFileRef;
}

@end
