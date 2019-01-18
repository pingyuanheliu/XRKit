//
//  XRPhotoBrowser.h
//  XRKit
//
//  Created by LL on 2019/1/18.
//  Copyright © 2019年 LL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XRPhoto.h"

@class XRPhotoBrowser;

@protocol XRPhotoBrowserDetegate <NSObject>

@optional
//删除照片
- (void)photoBrowser:(XRPhotoBrowser *)photoBrowser didDeletePhoto:(XRPhoto *)photo;

@end

@interface XRPhotoBrowser : UIViewController

//代理
@property (nonatomic, weak) id<XRPhotoBrowserDetegate> delegate;

/**
 自定义图片数组
 
 @param photosArray 图片数组
 @return 视图控制器
 */
- (id)initWithPhotos:(NSArray<XRPhoto *> *)photosArray;

@end
