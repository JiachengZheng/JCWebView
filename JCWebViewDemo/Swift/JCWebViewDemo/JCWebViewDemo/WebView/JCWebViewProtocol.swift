//
//  JCWebViewProtocol.swift
//  JCWebDemo
//
//  Created by zhengjiacheng on 2017/5/5.
//

import Foundation
import UIKit

public protocol JCWebViewDelegate: class {
    func webView(_ webView: JCWebViewProtocol, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool
    
    func webViewDidStartLoad(_ webView: JCWebViewProtocol)
    
    func webViewDidFinishLoad(_ webView: JCWebViewProtocol)
    
    func webView(_ webView: JCWebViewProtocol, didFailLoadWithError error: Error)
}

public protocol JCWebViewProtocol: class {
    
    
    weak var webDelegate: JCWebViewDelegate? { set get }
    
    //用于代理转发
    var delegateHandler: Any? {set get}
    
    var webTitle: String? {get}
    
    var innerScrollView: UIScrollView { get }
    
    var currentRequest: URLRequest? { get }
    
    var loading: Bool { get }
    
    
    func loadUrlRequest(_ request: inout URLRequest)
    
    func loadHTML(_ HTMLString: String, baseURL: URL?)
    
    func loadData(_ data: Data, mimeType MIMEType: String, textEncodingName: String, baseURL: URL)
    
    
    func reloadWeb()
    
    func stopLoadingWeb()
    
    
    func goBackPage()
    
    func goForwardPage()
    
    
    var canWebGoBack: Bool { get }
    
    var canWebGoForward: Bool { get }
    
    
    func evaluateJavaScriptString(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Swift.Void)?)
    
    var scalesWebPageToFit: Bool {set get}
    
}





