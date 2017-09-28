//
//  JCWKWebViewExtension.swift
//  JCWebDemo
//
//  Created by zhengjiacheng on 2017/6/3.
//

import Foundation
import WebKit

private var kWKWebDelegateKey = "kWKWebDelegateKey"
private var kWKDelegateHandler = "kWKDelegateHandler"
private var kscalesWebPageToFit = "kscalesWebPageToFit"

extension WKWebView: JCWebViewProtocol{
    public weak var webDelegate: JCWebViewDelegate? {
        get{
            if let delegate = objc_getAssociatedObject(self, &kWKWebDelegateKey) as? JCWebViewDelegate{
                return delegate
            }
            return nil
        }
        set{
            if let delegate = newValue {
                let handler = JCWKWebViewDelegateHandler(delegate,webView: self)//对代理方法进行转发
                self.delegateHandler = handler
                self.navigationDelegate = handler
                self.uiDelegate = handler
                objc_setAssociatedObject(self, &kWKWebDelegateKey, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN);
            }else{
                self.uiDelegate = nil
                self.navigationDelegate = nil
                self.delegateHandler = nil
            }
        }
    }
    
    public var webTitle: String? {
        return self.title
    }
    
    public var innerScrollView: UIScrollView {
        return self.scrollView
    }
    
    public var currentRequest: URLRequest? {
        //没写完
        return nil
    }
    
    public var loading: Bool {
        return self.isLoading
    }
    
    public func loadUrlRequest(_ request: inout URLRequest){
        if let userAgent = UserDefaults.standard.value(forKey: "UserAgent") as? String{
            if !userAgent.isEmpty{
                if #available(iOS 9.0, *) {
                    self.customUserAgent = userAgent
                }
            }
        }
        injectCookies(&request)
        self.load(request)
    }
    
    func _loadUrlRequest(_ request: inout URLRequest){
        
        if let userAgent = UserDefaults.standard.value(forKey: "UserAgent") as? String{
            if !userAgent.isEmpty{
                if #available(iOS 9.0, *) {
                    self.customUserAgent = userAgent
                }
            }
        }
        injectCookies(&request)
        self.load(request)
    }
    
    func injectCookies(_ requst: inout URLRequest){
        resetCookieForHeaderFields(&requst)
        fixRequest(&requst)
    }
    
    // 修改请求头的Cookie
    func resetCookieForHeaderFields( _ request: inout URLRequest){
        let cookies = currentDomainCookies(request)
        let requestHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
        request.allHTTPHeaderFields = requestHeaderFields
    }
    
    // 获取当前域名下的cookie
    func currentDomainCookies(_ request: URLRequest) -> [HTTPCookie]{
        var curDomainCookies: [HTTPCookie] = []
        guard let cookies = HTTPCookieStorage.shared.cookies, let validDomain = request.url?.host else{
            return curDomainCookies
        }
        
        for cookie in cookies {
            if !validDomain.hasSuffix(cookie.domain) {
                continue
            }
            curDomainCookies.append(cookie)
        }
        return curDomainCookies
    }
    
    /// 通过脚本出入cookie
    func addUserCookieScript(_ request: URLRequest){
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            return
        }
        if cookies.isEmpty {
            return
        }
        guard let cookieScript = injectLocalCookieScript() else{
            return
        }
        let script = WKUserScript(source: cookieScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        self.configuration.userContentController.addUserScript(script)
    }
    
    func injectLocalCookieScript() -> String?{
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            return nil
        }
        if cookies.isEmpty {
            return nil
        }
        var jsString = kInjectLocalCookieScript
        for cookie in cookies {
            if cookie.name == "jk" {
                continue
            }
            let secure = cookie.isSecure ? "true" : "false"
            var days: Double = 1
            if let expireDate = cookie.expiresDate{
                days = expireDate.timeIntervalSinceNow / Double(3600*24)
            }
            jsString += "setCookieFromApp('\(cookie.name)', '\(cookie.value)', \(days), '\(cookie.path)','\(cookie.domain)', \(secure));"
        }
        return jsString
    }
    
    func fixRequest( _ request: inout URLRequest){
        let dic = HTTPCookie.requestHeaderFields(with: currentDomainCookies(request))
        if var headerFields = request.allHTTPHeaderFields{
            for (key,value) in dic {
                headerFields[key] = value
            }
            request.allHTTPHeaderFields = headerFields
        }
    }
    
    public func loadHTML(_ HTMLString: String, baseURL: URL?){
        self.loadHTMLString(HTMLString, baseURL: baseURL)
    }
    
    public func loadData(_ data: Data, mimeType MIMEType: String, textEncodingName: String, baseURL: URL){
        if #available(iOS 9.0, *) {
            self.load(data, mimeType: MIMEType, characterEncodingName: textEncodingName, baseURL: baseURL)
        } else {
            // Fallback on earlier versions
        }
    }
    
    public func reloadWeb(){
        self.reload()
    }
    
    public func stopLoadingWeb(){
        self.stopLoading()
    }
    
    public func goBackPage(){
        self.goBack()
    }
    
    public func goForwardPage(){
        self.goForward()
    }
    
    public var canWebGoBack: Bool {
        return self.canGoBack
    }
    
    public var canWebGoForward: Bool {
        return self.canGoForward
    }
    
    public func evaluateJavaScriptString(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Swift.Void)?){
        self.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    public var scalesWebPageToFit: Bool{
        get{
            if let handler = objc_getAssociatedObject(self, &kscalesWebPageToFit) as? NSNumber{
                return handler.boolValue
            }
            return false
        }
        set{
            let number = NSNumber.init(value: newValue)
            objc_setAssociatedObject(self, &kscalesWebPageToFit, number, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    
    public var delegateHandler: Any? {
        get{
            if let handler = objc_getAssociatedObject(self, &kWKDelegateHandler) as? JCWKWebViewDelegateHandler{
                return handler
            }
            return nil
        }
        set{
            objc_setAssociatedObject(self, &kWKDelegateHandler, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

class JCWKWebViewDelegateHandler: NSObject{
    weak var delegate: JCWebViewDelegate?
    weak var webView: WKWebView?
    
    init(_ delegate: JCWebViewDelegate?, webView: WKWebView?) {
        self.delegate = delegate
        self.webView = webView
    }
}


// MARK: WKNavigationDelegate
extension JCWKWebViewDelegateHandler: WKNavigationDelegate{
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void){
        let result = delegate?.webView(webView, shouldStartLoadWith: navigationAction.request, navigationType: UIWebViewNavigationType(rawValue: navigationAction.navigationType.rawValue) ?? UIWebViewNavigationType.other)
        
        if result != nil {
            var request = navigationAction.request
            webView.fixRequest(&request)
            
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            // WKWebView 不会处理这些跳转，需要交给UIApplication 来处理
            if let url = navigationAction.request.url{
                let application = UIApplication.shared
                if url.scheme == "tel",application.canOpenURL(url){
                    application.openURL(url)
                    decisionHandler(.cancel)
                    return
                }
                
                if let host = url.host{
                    if host.contains("itunes.apple.com"),application.canOpenURL(url){
                        application.openURL(url)
                        decisionHandler(.cancel)
                        return
                    }
                }
            }
            
            decisionHandler(.allow)
        }else{
            decisionHandler(.cancel)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void){
        
        //保存 response.allHeaderFields 里的cookie
        if let response = navigationResponse.response as? HTTPURLResponse, let url = navigationResponse.response.url{
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as! [String : String], for: url)
            if cookies.count > 0 {
                HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
            }
        }
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!){
        delegate?.webViewDidStartLoad(webView)
    }
    
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!){
        
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error){
        delegate?.webView(webView, didFailLoadWithError: error)
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!){
        
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
        delegate?.webViewDidFinishLoad(webView)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error){
        delegate?.webView(webView, didFailLoadWithError: error)
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void){
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust{
            if let trust = challenge.protectionSpace.serverTrust{
                let card = URLCredential(trust: trust)
                completionHandler(.useCredential,card)
            }
        }
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}


// MARK: WKUIDelegate
extension JCWKWebViewDelegateHandler: WKUIDelegate{
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Swift.Void){
        // js 里面的alert实现，如果不实现，alert函数无效
        
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "确定", style: .default) { (_) in
            completionHandler()
        }
        alertController.addAction(confirmAction)
        
        //没写完
        //        [tpVCL presentViewController:alertController animated:YES completion:^{}];
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Swift.Void){
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "确定", style: .default) { (_) in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (_) in
            completionHandler(true)
        }
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        //没写完
        //        [tpVCL presentViewController:alertController animated:YES completion:^{}];
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Swift.Void){
        completionHandler("Client Not handler")
    }

}

private let kInjectLocalCookieScript = "function setCookieFromApp(name, value, expires, path, domain, secure){var argv = arguments;var argc = arguments.length;var now = new Date();var expires = (argc > 2) ? new Date(new Date().getTime() + parseInt(expires) * 24 * 60 * 60 * 1000) : new Date(now.getFullYear(), now.getMonth() + 1, now.getUTCDate());var path = (argc > 3) ? argv[3] : '/';var domain = (argc > 4) ? argv[4] :'';var secure = (argc > 5) ? argv[5] : false;var httpOnly = (argc > 6) ? argv[6] : false;document.cookie = name + '=' + value + ((expires == null) ? '' : ('; expires=' + expires.toGMTString())) + ((path == null) ? '' : ('; path=' + path)) + ((domain == null) ? '' : ('; domain=' + domain)) + ((secure == true) ? '; secure' : '');};"

