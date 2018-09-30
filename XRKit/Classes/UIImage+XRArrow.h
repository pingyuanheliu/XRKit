//
//  UIImage+XRArrow.h
//  XRKit
//
//  Created by LL on 2018/9/30.
//  Copyright © 2018年 LL. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (XRArrow)

/**
 右指向箭头
 
 @param size 尺寸大小
 @param color 颜色
 @return 箭头图片
 */
+ (UIImage *)xr_rightArrow:(CGSize)size color:(UIColor *)color;

/**
 左指向箭头
 
 @param size 尺寸大小
 @param color 颜色
 @return 箭头图片
 */
+ (UIImage *)xr_leftArrow:(CGSize)size color:(UIColor *)color;

/**
 右指向-灰色箭头
 
 @param size 尺寸大小
 @return 箭头图片
 */
+ (UIImage *)xr_rightGrayArrow:(CGSize)size;

/**
 左指向-白色箭头
 
 @param size 尺寸大小
 @return 箭头图片
 */
+ (UIImage *)xr_leftWhiteArrow:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
