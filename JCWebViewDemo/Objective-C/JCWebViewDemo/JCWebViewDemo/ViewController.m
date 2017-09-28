//
//  ViewController.m
//  JCWebViewDemo
//
//  Created by 郑嘉成 on 2017/9/28.
//  Copyright © 2017年 zhengjiacheng. All rights reserved.
//

#import "ViewController.h"
#import "JCWebView.h"
@interface ViewController ()<JCWebViewDelegate>
@property (nonatomic, strong) JCWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    JCWebView *webView = [[JCWebView alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height-20) forceUseUIWebView:NO];
    [self.view addSubview:webView];
    webView.delegate = self;
    NSURL *url = [NSURL URLWithString:@"http://www.jianshu.com/u/3d8439db292b"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [webView loadRequest:request];
    self.webView = webView;
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
