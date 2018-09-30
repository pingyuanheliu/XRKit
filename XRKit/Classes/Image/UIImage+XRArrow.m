//
//  UIImage+XRArrow.m
//  XRKit
//
//  Created by LL on 2018/9/30.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "UIImage+XRArrow.h"

@implementation UIImage (XRArrow)

/**
 右指向箭头
 
 @param size 尺寸大小
 @param color 颜色
 @return 箭头图片
 */
+ (UIImage *)xr_rightArrow:(CGSize)size color:(UIColor *)color {
    CGFloat width = size.width;
    CGFloat height = size.height;
    BOOL opaque = NO;
    CGFloat scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.0, 0.0)];
    [path addLineToPoint:CGPointMake(width-1.0, height/2.0)];
    [path addLineToPoint:CGPointMake(0.0, height)];
    path.lineWidth = 1.0;
    path.lineCapStyle = kCGLineCapButt;
    path.lineJoinStyle = kCGLineJoinMiter;
    [color setStroke];
    [path stroke];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/**
 左指向箭头
 
 @param size 尺寸大小
 @param color 颜色
 @return 箭头图片
 */
+ (UIImage *)xr_leftArrow:(CGSize)size color:(UIColor *)color {
    CGFloat width = size.width;
    CGFloat height = size.height;
    BOOL opaque = NO;
    CGFloat scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(width, 0.0)];
    [path addLineToPoint:CGPointMake(1.0, height/2.0)];
    [path addLineToPoint:CGPointMake(width, height)];
    path.lineWidth = 1.0;
    path.lineCapStyle = kCGLineCapButt;
    path.lineJoinStyle = kCGLineJoinMiter;
    [color setStroke];
    [path stroke];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/**
 右指向-灰色箭头
 
 @param size 尺寸大小
 @return 箭头图片
 */
+ (UIImage *)xr_rightGrayArrow:(CGSize)size {
    UIColor *color = [UIColor lightGrayColor];
    return [UIImage xr_rightArrow:size color:color];
}

/**
 左指向-白色箭头
 
 @param size 尺寸大小
 @return 箭头图片
 */
+ (UIImage *)xr_leftWhiteArrow:(CGSize)size {
    UIColor *color = [UIColor whiteColor];
    return [UIImage xr_leftArrow:size color:color];
}

@end
