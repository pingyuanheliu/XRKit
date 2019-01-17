//
//  UIImage+Scale.m
//  TestImage
//
//  Created by LL on 2019/1/17.
//  Copyright © 2019年 LL. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (Scale)

+ (UIImage *)ws_imageWithIndex:(NSInteger)index
{
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)];
    lab.backgroundColor = [UIColor redColor];
    lab.text = [NSString stringWithFormat:@"%02ld",index];
    lab.textColor = [UIColor whiteColor];
    lab.textAlignment = NSTextAlignmentCenter;
    lab.font = [UIFont systemFontOfSize:24.0];
    
    UIGraphicsBeginImageContext(lab.bounds.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [lab.layer renderInContext:ctx];
    UIImage* tImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tImage;
}

@end
