//
//  XRPhotoBrowser.m
//  XRKit
//
//  Created by LL on 2019/1/18.
//  Copyright © 2019年 LL. All rights reserved.
//

#import "XRPhotoBrowser.h"
//左右间隔
#define PADDING 10

@interface XRPhotoBrowser ()<UIScrollViewDelegate>
{
    //图片计数
    NSUInteger _photoCount;
    //页面滚动视图
    UIScrollView *_pageScrollView;
}

//固定不变的图片数组
@property (nonatomic, strong) NSMutableArray<XRPhoto *> *fixedPhotos;
//可变的图片数组
@property (nonatomic, strong) NSMutableArray<XRPhoto *> *alterPhotos;

@end

@implementation XRPhotoBrowser

#pragma mark - Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialDefine];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialDefine];
    }
    return self;
}

/**
 自定义图片数组

 @param photosArray 图片数组
 @return 视图控制器
 */
- (id)initWithPhotos:(NSArray<XRPhoto *> *)photosArray {
    self = [self init];
    if (self) {
        _fixedPhotos = [[NSMutableArray alloc] initWithArray:photosArray];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self customUI];
}

#pragma mark - Init

/**
 初始化定义
 */
- (void)initialDefine {
    _photoCount = NSNotFound;
}

/**
 自定义视图
 */
- (void)customUI {
    if (_pageScrollView == nil) {
        CGRect rect = [self frameForPageScrollView];
        _pageScrollView = [[UIScrollView alloc] initWithFrame:rect];
        _pageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _pageScrollView.pagingEnabled = YES;
        _pageScrollView.delegate = self;
        _pageScrollView.showsVerticalScrollIndicator = NO;
        _pageScrollView.showsHorizontalScrollIndicator = NO;
        _pageScrollView.backgroundColor = [UIColor colorWithRed:0x10/255.0 green:0x13/255.0 blue:0x15/255.0 alpha:1.0];
    }
}

#pragma mark - Frame
//主体页面控制视图区域大小
- (CGRect)frameForPageScrollView {
    CGRect frame = self.view.bounds;
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}

#pragma mark - Data

- (NSUInteger)numberOfPhotos {
    if (_photoCount == NSNotFound) {
        if (_fixedPhotos) {
            _photoCount = _fixedPhotos.count;
        }
    }
    if (_photoCount == NSNotFound) _photoCount = 0;
    return _photoCount;
}

#pragma mark - Size

- (CGSize)contentSizeForPageScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pageScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
