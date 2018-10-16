//
//  ViewController.m
//  XRKit
//
//  Created by LL on 2018/9/30.
//  Copyright © 2018年 LL. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, assign) XRCameraType type;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"==1 viewDidLoad==");
    self.cameraType = XRCameraQRcode | XRCameraVideo;
}

- (IBAction)clickChangeItem:(UIBarButtonItem *)sender {
    
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"==1 viewWillAppear==");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"==1 viewDidAppear==");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"==1 viewWillDisappear==");
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"==1 viewDidDisappear==");
}

@end
