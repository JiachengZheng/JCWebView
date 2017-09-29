//
//  ViewController.swift
//  JCWebViewDemo
//
//  Created by 郑嘉成 on 2017/9/28.
//  Copyright © 2017年 zhengjiacheng. All rights reserved.
//

import UIKit
import WebKit
class ViewController: UIViewController {
    public var webView :JCWebViewProtocol?
    var progressView: JCWebProgressView?
    
    fileprivate var forceUseWKWebView = true
    fileprivate var loadProgress: CGFloat = 0.0
    fileprivate var timer: DispatchSourceTimer?
    
    open func createProgressView(_ frame: CGRect){
        if self.progressView != nil {
            return
        }
        progressView = JCWebProgressView(frame: frame)
        self.view.addSubview(progressView!)
    }
    
    fileprivate func startWebLoadProgress(){
        stopTimer()
        loadProgress = 0.4
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer!.scheduleRepeating(deadline: .now(), interval: .milliseconds(100))
        timer!.setEventHandler( handler: { [weak self] in
            self?.addWebViewLoadProgress()
        })
        timer!.resume()
    }
    
    fileprivate func addWebViewLoadProgress(){
        let step: CGFloat = 0.1
        if loadProgress < 0.8 {
            loadProgress += step
        }
        progressView?.progress = loadProgress
    }
    
    fileprivate func stopWebViewLoadProgress(){
        progressView?.progress = 1
        stopTimer()
    }
    
    fileprivate func stopTimer(){
        timer?.cancel()
        timer = nil
    }
    
    func createUIWebView(_ frame: CGRect) -> JCWebViewProtocol{
        let webView = UIWebView(frame: frame)
        webView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        webView.allowsInlineMediaPlayback = true
        webView.backgroundColor = UIColor.white
        return webView
    }
    
    func createWKWebView(_ frame: CGRect) -> JCWebViewProtocol{
        let config = WKWebViewConfiguration()
        let preference = WKPreferences()
        config.preferences = preference
        config.allowsInlineMediaPlayback = true
        
        let contentController = WKUserContentController()
        config.userContentController = contentController
        
        let webView = WKWebView(frame: frame)
        webView.backgroundColor = UIColor.white
        webView.allowsBackForwardNavigationGestures = true
        
        webView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        return webView
    }
    
    open func createWebView(_ frame: CGRect){
        webView = forceUseWKWebView ? createWKWebView(frame) : createUIWebView(frame)
        webView?.innerScrollView.delegate = self
        webView?.webDelegate = self
        if let view = webView as? UIView {
            self.view.addSubview(view)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        createWebView(CGRect(x: 0, y: 20, width: self.view.frame.size.width, height: self.view.frame.size.height - 20))
        createProgressView(CGRect(x: 0, y: 20, width: 0, height: 2))
        if let url = URL(string: "http://www.jianshu.com/u/3d8439db292b"){
            loadURL(url)
        }
    }
    
    open func loadURL(_ URL: URL){
        var request = URLRequest(url: URL)
        loadRequest(&request)
    }
    
    open func loadRequest(_ request: inout URLRequest){
        webView?.loadUrlRequest(&request)
    }
    
    deinit {
        stopWebViewLoadProgress()
        webView?.stopLoadingWeb()
        webView?.webDelegate = nil
        webView?.innerScrollView.delegate = nil
    }
}

extension ViewController: JCWebViewDelegate{
    public func webView(_ webView: JCWebViewProtocol, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool{
        return true
    }
    
    public func webViewDidStartLoad(_ webView: JCWebViewProtocol){
        startWebLoadProgress()
    }
    
    public func webViewDidFinishLoad(_ webView: JCWebViewProtocol){
        stopWebViewLoadProgress()
    }
    
    public func webView(_ webView: JCWebViewProtocol, didFailLoadWithError error: Error){
        stopWebViewLoadProgress()
    }
}

extension ViewController: UIScrollViewDelegate{
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
    }
}

