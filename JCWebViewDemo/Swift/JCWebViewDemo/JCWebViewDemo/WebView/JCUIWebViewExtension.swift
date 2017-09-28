//
//  JCUIWebViewExtension.swift
//  JCWebDemo
//
//  Created by zhengjiacheng on 2017/6/2.
//

import UIKit

private var kUIWebDelegateKey = "kUIWebDelegateKey"
private var kUIDelegateHandler = "kUIDelegateHandler"

extension UIWebView: JCWebViewProtocol{
    
    public weak var webDelegate: JCWebViewDelegate? {
        get{
            if let delegate = objc_getAssociatedObject(self, &kUIWebDelegateKey) as? JCWebViewDelegate{
                return delegate
            }
            return nil
        }
        set{
            if let delegate = newValue {
                let handler = JCUIWebViewDelegateHandler(delegate)//对代理方法进行转发
                self.delegateHandler = handler
                self.delegate = handler
                objc_setAssociatedObject(self, &kUIWebDelegateKey, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN);
            }else{
                self.delegate = nil
                self.delegateHandler = nil
            }
        }
    }
    
    public var webTitle: String? {
        let script = "document.title"
        if let title = self.stringByEvaluatingJavaScript(from: script){
            return title
        }
        return ""
    }
    
    public var innerScrollView: UIScrollView {
        return self.scrollView
    }

    public var currentRequest: URLRequest? {
        return self.request
    }

    public var loading: Bool {
        return self.isLoading
    }

    public func loadUrlRequest(_ request: inout URLRequest){
        self.loadRequest(request)
    }

    public func loadHTML(_ HTMLString: String, baseURL: URL?){
        self.loadHTMLString(HTMLString, baseURL: baseURL)
    }
    
    public func loadData(_ data: Data, mimeType MIMEType: String, textEncodingName: String, baseURL: URL){
        self.load(data, mimeType: MIMEType, textEncodingName: textEncodingName, baseURL: baseURL)
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
        let result = self.stringByEvaluatingJavaScript(from: javaScriptString)
        if let completionHandler = completionHandler{
            completionHandler(result ,nil)
        }
    }

    public var scalesWebPageToFit: Bool{
        set{
            self.scalesPageToFit = newValue
        }
        get{
            return self.scalesPageToFit
        }
    }
    
    public var delegateHandler: Any? {
        get{
            if let handler = objc_getAssociatedObject(self, &kUIDelegateHandler) as? JCUIWebViewDelegateHandler{
                return handler
            }
            return nil
        }
        set{
            objc_setAssociatedObject(self, &kUIDelegateHandler, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

class JCUIWebViewDelegateHandler:NSObject, UIWebViewDelegate {
    
    weak var delegate: JCWebViewDelegate?
    
    init(_ delegate: JCWebViewDelegate?) {
        self.delegate = delegate
    }
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool{
        if let should = delegate?.webView(webView, shouldStartLoadWith: request, navigationType: navigationType) {
            return should
        }
        return true
    }
    
    public func webViewDidStartLoad(_ webView: UIWebView){
        delegate?.webViewDidStartLoad(webView)
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView){
        delegate?.webViewDidFinishLoad(webView)
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error){
        delegate?.webView(webView, didFailLoadWithError: error)
    }
}






