//
//  File.swift
//  
//
//  Created by asc on 8/25/20.
//

import Foundation
import WebKit

public class WKWebViewDelegate: NSObject, WKNavigationDelegate {
    
    var on_complete: (Result<Data, Error>) -> Void
    
    public init(completionHandler: @escaping (Result<Data, Error>) -> Void){
        on_complete = completionHandler
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        // https://developer.apple.com/documentation/webkit/wkwebview/3650490-createpdf
        // webView.createPDF(cfg, on_complete)
    }
}
