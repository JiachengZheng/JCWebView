//
//  JCWebView.h
//  JCWebDemo
//
//  Created by zhengjiacheng on 2017/3/24.
//  All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class JCWebView;
@protocol JCWebViewDelegate <NSObject>

@optional
- (BOOL)webView:(JCWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

- (void)webViewDidStartLoad:(JCWebView *)webView;

- (void)webViewDidFinishLoad:(JCWebView *)webView;

- (void)webView:(JCWebView *)webView didFailLoadWithError:(NSError *)error;
///加载进度，用于进度条
- (void)webView:(JCWebView *)webView requestLoadEstimatedProgress:(double)estimatedProgress;
@end

@interface JCWebView : UIView

/**
 @param forceUseUIWebView 是否强制使用UIWebView  默认使用WKWebView
 */
- (instancetype)initWithFrame:(CGRect)frame forceUseUIWebView:(BOOL)forceUseUIWebView;

@property (nonatomic, weak) id<JCWebViewDelegate> delegate;
/// 是否使用 UIWebView 默认是NO
@property (nonatomic, readonly) BOOL isUsedUIWebView;
/// 当前内部使用的webView
@property (nonatomic, readonly) id realWebView;
/// 当前加载进度 通过代理设置进度条
@property (nonatomic, readonly) double estimatedProgress;
/// 网页标题
@property (nonatomic, readonly, copy) NSString *title;

@property (nonatomic, readonly, weak) UIScrollView *scrollView;

@property (nonatomic, readonly, copy) NSURL *URL;

@property (nonatomic, readonly) NSURLRequest *originRequest;
@property (nonatomic, readonly) NSURLRequest *request;

@property (nonatomic, readonly, getter=isLoading) BOOL loading;

@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;

@property (nonatomic) BOOL scalesPageToFit;


- (id)loadRequest:(NSURLRequest *)request;
- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

- (id)goBack;
- (id)goForward;

- (id)reload;
- (id)reloadFromOrigin;

- (void)stopLoading;

/// 清除缓存
+ (void)removeCache;

/// 执行js脚本 异步方法（推荐）
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;

/// 执行js脚本 同步方法（不推荐）
- (id)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString;


- (void)evaluateJavaScriptToAddCookie:(void(^)(void))completion;
@end
