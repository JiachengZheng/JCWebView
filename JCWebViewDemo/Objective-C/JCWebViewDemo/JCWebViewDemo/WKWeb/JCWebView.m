//
//  JCWebView.m
//  JCWebDemo
//
//  Created by zhengjiacheng on 2017/3/24.
//

#import "JCWebView.h"
#import "WKWebViewPoolHandler.h"
#import "JCWebViewCookieScript.h"

@interface JCWebView ()<UIWebViewDelegate, WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, assign) double estimatedProgress;
@property (nonatomic, strong) NSURLRequest *originRequest;
@property (nonatomic, strong) NSURLRequest *request; 
@property (nonatomic, strong) dispatch_source_t timer;               //用于UIWebView 加载进度
@property (nonatomic, copy) NSString *title;
@end

@implementation JCWebView

@synthesize scalesPageToFit = _scalesPageToFit;

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {
        _isUsedUIWebView = YES;
        [self initRealWebView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    return [self initWithFrame:frame forceUseUIWebView:YES];
}

- (instancetype)initWithFrame:(CGRect)frame forceUseUIWebView:(BOOL)forceUseUIWebView{
    self = [super initWithFrame:frame];
    if (self){
        _isUsedUIWebView = forceUseUIWebView;
        [self initRealWebView];
    }
    return self;
}

-(void)initRealWebView{
    Class wkWebView = NSClassFromString(@"WKWebView");
    if(wkWebView && !self.isUsedUIWebView){
        [self initWKWebView];
        _isUsedUIWebView = NO;
    }else{
        [self initUIWebView];
        _isUsedUIWebView = YES;
    }
    self.scalesPageToFit = YES;
    [self.realWebView setFrame:self.bounds];
    [self.realWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self addSubview:self.realWebView];
}

-(void)initWKWebView{
    WKWebViewConfiguration* configuration = [[NSClassFromString(@"WKWebViewConfiguration") alloc] init];
    WKPreferences *preferences = [NSClassFromString(@"WKPreferences") new];
    configuration.preferences = preferences;
    configuration.allowsInlineMediaPlayback = YES;
    
    //!!!重要：共享一个pool 用以cookies共享
    configuration.processPool = [[WKWebViewPoolHandler sharedInstance] defaultPool];
    
    WKUserContentController *userContentController = [NSClassFromString(@"WKUserContentController") new];
    configuration.userContentController = userContentController;
    
    WKWebView* webView = [[NSClassFromString(@"WKWebView") alloc] initWithFrame:self.bounds configuration:configuration];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    webView.allowsLinkPreview = NO;
    webView.backgroundColor = [UIColor whiteColor];

    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    _realWebView = webView;
}

-(void)initUIWebView{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.bounds];
    webView.backgroundColor = [UIColor whiteColor];
    webView.delegate = self;
    webView.allowsInlineMediaPlayback = YES;
    webView.keyboardDisplayRequiresUserAction = NO;
    _realWebView = webView;
}

#pragma mark - 对外接口
-(UIScrollView *)scrollView{
    return [self.realWebView scrollView];
}

- (NSURLRequest *)request{
    if(_isUsedUIWebView){
        UIWebView *webview = (UIWebView*)self.realWebView;
        return webview.request;
    }else{
        return _request;
    }
}

- (id)loadRequest:(NSURLRequest *)request{
    NSMutableURLRequest *newRequest = [request mutableCopy];
    if(_isUsedUIWebView){
        self.request = newRequest;
        [(UIWebView*)self.realWebView loadRequest:newRequest];
        return nil;
    }else{
        NSString *userAgent =[[NSUserDefaults standardUserDefaults] valueForKey:@"UserAgent"];
        double systemVersion = [[[UIDevice currentDevice] systemVersion] doubleValue];
        //添加自定义 userAgent 表示使用WKWebView
        if (userAgent && userAgent.length > 0 && systemVersion >= 9) {
            WKWebView *webView = (WKWebView*)self.realWebView;
            webView.customUserAgent = userAgent;
        }
        //重新添加Cookie WKWebView 不会带上cookie 需要同时在request上添加以及使用脚本添加
        [self injectCookies:newRequest];
        
        self.request = newRequest;
        return [(WKWebView*)self.realWebView loadRequest:newRequest];
    }
}

- (void)injectCookies:(NSMutableURLRequest *)request{
    [self resetCookieForHeaderFields:request];
    [self addUserCookieScript:request];
}

// 修改请求头的Cookie
- (void)resetCookieForHeaderFields:(NSMutableURLRequest *)request{
    NSArray *cookies = [self currentCookies:request];
    NSDictionary *requestHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    request.allHTTPHeaderFields = requestHeaderFields;
}

// 获取当前域名下的cookie
- (NSArray *)currentCookies:(NSMutableURLRequest *)request{
    NSArray *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
    NSString *validDomain = request.URL.host;
    NSMutableArray *mutableArr = [NSMutableArray array];
    for (NSHTTPCookie *cookie in cookies) {
        if (![validDomain hasSuffix:cookie.domain]) {
            continue;
        }
        [mutableArr addObject:cookie];
    }
    return mutableArr;
}

/// 通过脚本出入cookie
- (void)addUserCookieScript:(NSURLRequest *)request{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    if (!cookies || cookies.count < 1) {
        return;
    }
    NSString *cookieScript = [self injectLocalCookieScript];
    WKUserScript *startScript = [[WKUserScript alloc]initWithSource:cookieScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    WKWebView *wkWebView = (WKWebView*)self.realWebView;
    [wkWebView.configuration.userContentController addUserScript:startScript];
}

- (NSString *)injectLocalCookieScript{
    NSString *jsString = kInjectLocalCookieScript;
    NSMutableString *cookieScript = [NSMutableString stringWithString:jsString];
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:@"jk"]) {//不添加本地jk，一般页面会写入jk
            continue;
        }
        NSString *name = cookie.name ?: @"";
        NSString *value = cookie.value ?: @"";
        NSString *domain = cookie.domain ?: @"";
        NSString *path = cookie.path ?: @"/";
        NSString *secure = cookie.secure ?@"true": @"false";
        NSInteger days = 1;
        if (cookie.expiresDate) {
            NSTimeInterval seconds = [cookie.expiresDate timeIntervalSinceNow];
            days = seconds/3600/24;
        }
        [cookieScript appendString:[NSString stringWithFormat:@"setCookieFromApp('%@', '%@', %ld, '%@','%@', %@);",name,value,(long)days,path,domain,secure]];
    }
    return cookieScript;
}

//防止Cookie丢失
- (NSURLRequest *)fixRequest:(NSURLRequest *)request{
    NSMutableURLRequest *fixedRequest;
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        fixedRequest = (NSMutableURLRequest *)request;
    } else {
        fixedRequest = request.mutableCopy;
    }
    NSDictionary *dict = [NSHTTPCookie requestHeaderFieldsWithCookies:[self currentCookies:fixedRequest]];
    if (dict.count) {
        NSMutableDictionary *mDict = request.allHTTPHeaderFields.mutableCopy;
        [mDict setValuesForKeysWithDictionary:dict];
        fixedRequest.allHTTPHeaderFields = mDict;
    }
    return fixedRequest;
}

- (void)evaluateJavaScriptToAddCookie:(void(^)(void))completion{
    if (self.isUsedUIWebView) {
        return;
    }
    NSString *cookieScript = [self injectLocalCookieScript];
    WKWebView *wkWebView = (WKWebView*)self.realWebView;
    [wkWebView evaluateJavaScript:cookieScript completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        completion();
    }];
}

- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL{
    if(_isUsedUIWebView){
        [(UIWebView*)self.realWebView loadHTMLString:string baseURL:baseURL];
        return nil;
    }else{
        return [(WKWebView*)self.realWebView loadHTMLString:string baseURL:baseURL];
    }
}

-(NSURLRequest *)currentRequest{
    return _isUsedUIWebView ? [(UIWebView*)self.realWebView request] : _request;
}

-(NSURL *)URL{
    return _isUsedUIWebView ? [(UIWebView*)self.realWebView request].URL : [(WKWebView*)self.realWebView URL];
}

-(BOOL)isLoading{
    return [self.realWebView isLoading];
}

-(BOOL)canGoBack{
    return [self.realWebView canGoBack];
}

-(BOOL)canGoForward{
    return [self.realWebView canGoForward];
}

- (id)goBack{
    if(_isUsedUIWebView){
        [(UIWebView*)self.realWebView goBack];
        return nil;
    }else{
        return [(WKWebView*)self.realWebView goBack];
    }
}

- (id)goForward{
    if(_isUsedUIWebView){
        [(UIWebView*)self.realWebView goForward];
        return nil;
    }else{
        return [(WKWebView*)self.realWebView goForward];
    }
}

- (id)reload{
    if(_isUsedUIWebView){
        [(UIWebView*)self.realWebView reload];
        return nil;
    }else{
        return [(WKWebView*)self.realWebView reload];
    }
}

- (id)reloadFromOrigin{
    if(_isUsedUIWebView){
        if(self.originRequest){
            [self evaluateJavaScript:[NSString stringWithFormat:@"window.location.replace('%@')",self.originRequest.URL.absoluteString] completionHandler:nil];
        }
        return nil;
    }else{
        return [(WKWebView*)self.realWebView reloadFromOrigin];
    }
}

- (void)stopLoading{
    [self.realWebView stopLoading];
}

+ (void)removeCache {
    double systemVersion = [[[UIDevice currentDevice] systemVersion] doubleValue];
    NSSet *websiteDataTypes = [NSSet setWithArray:@[
                                                    WKWebsiteDataTypeCookies,
                                                    WKWebsiteDataTypeSessionStorage,
                                                    ]];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{}];
}

#pragma mark - KVO 属性 WKWebView 进度相关
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object != self.realWebView) {
        return;
    }
    if([keyPath isEqualToString:@"estimatedProgress"]){
        //暂时不用真实进度了，体验一般
    }else if([keyPath isEqualToString:@"title"]){
        self.title = change[NSKeyValueChangeNewKey];
    }
}

#pragma mark - UIWebView 进度相关
- (void)setWebViewProgress:(NSTimer *)timer{
    float pStep = .1;
    if (self.estimatedProgress<0.8) {
        self.estimatedProgress += pStep;
    }
    if ([self.delegate respondsToSelector:@selector(webView:requestLoadEstimatedProgress:)]) {
        [self.delegate webView:self requestLoadEstimatedProgress:self.estimatedProgress];
    }
}

- (void)setEstimatedProgress:(double)estimatedProgress{
    _estimatedProgress = estimatedProgress;
}

- (void)endWebViewLoadingProgress{
    if ([self.delegate respondsToSelector:@selector(webView:requestLoadEstimatedProgress:)]) {
        [self.delegate webView:self requestLoadEstimatedProgress:1.0];
    }
    [self stopTimer];
}

- (void)startTimer{
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(0.4 * NSEC_PER_SEC);
    dispatch_source_set_timer(self.timer, start, interval, 0);
    __weak typeof(self) instance = self;
    dispatch_source_set_event_handler(self.timer, ^{
        [instance setWebViewProgress:nil];
    });
    dispatch_resume(self.timer);
}

- (void)stopTimer{
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

#pragma mark- UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView{
    [self _webViewDidStartLoad];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if(!self.originRequest){
        self.originRequest = webView.request;
    }
    [self _webViewDidFinishLoad];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [self _webViewDidFailLoadWithError:error];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    BOOL resultBOOL = [self _webViewShouldStartLoadWithRequest:request navigationType:navigationType];
    return resultBOOL;
}

#pragma mark- WKNavigationDelegate
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{

    BOOL resultBOOL = [self _webViewShouldStartLoadWithRequest:navigationAction.request navigationType:navigationAction.navigationType];
    
    if(resultBOOL){
        NSURLRequest *originalRequest = navigationAction.request;
        self.request = originalRequest;
        [self fixRequest:originalRequest];
        
        if(!navigationAction.targetFrame){
            [webView loadRequest:navigationAction.request];
        }
        
        UIApplication *app = [UIApplication sharedApplication];
        NSURL *url = navigationAction.request.URL;
        if ([url.scheme isEqualToString:@"tel"]){
            if ([app canOpenURL:url]){
                [app openURL:url];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        if ([url.host containsString:@"itunes.apple.com"]){
            if ([app canOpenURL:url]){
                [app openURL:url];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        decisionHandler(WKNavigationActionPolicyAllow);
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    [webView loadRequest:[self fixRequest:navigationAction.request]];
    return nil;
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    [self _webViewDidStartLoad];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [self _webViewDidFinishLoad];
}

- (void)webView:(WKWebView *) webView didFailProvisionalNavigation: (WKNavigation *) navigation withError: (NSError *) error{
    [self _webViewDidFailLoadWithError:error];
}

- (void)webView: (WKWebView *)webView didFailNavigation:(WKNavigation *) navigation withError: (NSError *) error{
    [self _webViewDidFailLoadWithError:error];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
    // 获取cookie,并设置到本地
    NSArray *cookies =[NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
    if (cookies.count>0) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:response.URL mainDocumentURL:nil];
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0)){
    [webView reload];
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    //重要！ js 里面的alert实现，如果不实现，网页的alert函数无效
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler();
                                                      }]];
    UIViewController *tpVCL = [self topViewController];
    [tpVCL presentViewController:alertController animated:YES completion:^{}];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(YES);
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action){
                                                          completionHandler(NO);
                                                      }]];
    UIViewController *tpVCL = [self topViewController];
    [tpVCL presentViewController:alertController animated:YES completion:^{}];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler {
    completionHandler(@"Client Not handler");
}

#pragma mark - JCWebViewDelegate 内部方法
- (void)_webViewDidFinishLoad{
    [self endWebViewLoadingProgress];
    if([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]){
        [self.delegate webViewDidFinishLoad:self];
    }
}

- (void)_webViewDidStartLoad{
    if (!self.timer) {
        [self startTimer];
    }
    self.estimatedProgress = 0.4;
    if([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]){
        [self.delegate webViewDidStartLoad:self];
    }
}

- (void)_webViewDidFailLoadWithError:(NSError *)error{
    [self endWebViewLoadingProgress];
    if([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]){
        [self.delegate webView:self didFailLoadWithError:error];
    }
}

-(BOOL)_webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType{
    BOOL resultBOOL = YES;
    if([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]){
        if(navigationType == -1) {
            navigationType = UIWebViewNavigationTypeOther;
        }
        resultBOOL = [self.delegate webView:self shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return resultBOOL;
}

#pragma mark - evaluateJavaScript
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler{
    if(_isUsedUIWebView){
        NSString* result = [(UIWebView*)self.realWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
        if(completionHandler){
            completionHandler(result,nil);
        }
    }else{
        return [(WKWebView*)self.realWebView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
    }
}

-(id )stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString{
    if(_isUsedUIWebView){
        NSString* result = [(UIWebView*)self.realWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
        return result;
    }else{
        __block NSString* result = nil;
        __block BOOL isExecuted = NO;
        [(WKWebView*)self.realWebView evaluateJavaScript:javaScriptString completionHandler:^(id obj, NSError *error) {
            result = obj;
            isExecuted = YES;
        }];
        while (isExecuted == NO) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        return result;
    }
}

-(void)setScalesPageToFit:(BOOL)scalesPageToFit{
    if(_isUsedUIWebView){
        UIWebView* webView = _realWebView;
        webView.scalesPageToFit = scalesPageToFit;
    }else{//WK 的 scalesPageToFit 不知道怎么写
        _scalesPageToFit = scalesPageToFit;
    }
}

-(BOOL)scalesPageToFit{
    return _isUsedUIWebView ? [_realWebView scalesPageToFit] : _scalesPageToFit;
}

- (UIViewController *)topViewController {
    UIViewController *resultVC;
    resultVC = [self findTopViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self findTopViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

- (UIViewController *)findTopViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self findTopViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self findTopViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
    return nil;
}

#pragma mark -
-(void)dealloc{
    [self stopTimer];
    if(_isUsedUIWebView){
        UIWebView *webView = (UIWebView *)_realWebView;
        webView.delegate = nil;
    }else{
        WKWebView *webView = (WKWebView *)_realWebView;
        webView.UIDelegate = nil;
        webView.navigationDelegate = nil;
        [webView removeObserver:self forKeyPath:@"estimatedProgress"];
        [webView removeObserver:self forKeyPath:@"title"];
    }
    [_realWebView scrollView].delegate = nil;
    [_realWebView stopLoading];
    [_realWebView removeFromSuperview];
    _realWebView = nil;
}

@end
