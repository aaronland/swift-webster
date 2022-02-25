import Foundation
import WebKit

public enum WKWebViewDelegateErrors: Error {
    case notImplemented
}

public class WKWebViewDelegate: NSObject, WKNavigationDelegate {
    
    var on_complete: (Result<Data, Error>) -> Void
    
    public init(completionHandler: @escaping (Result<Data, Error>) -> Void){
        on_complete = completionHandler
    }
    
    // https://developer.apple.com/documentation/webkit/wkwebview/3650490-createpdf

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        on_complete(.failure(WKWebViewDelegateErrors.notImplemented))
        
        /*
        if #available(OSX 10.16, *) {
            
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printing)
            
            defer {
                NotificationCenter.default.post(name: Notification.Name("status"), object: Status.complete)
            }
            
            print("PDF IT UP, YO")
            let cfg = WKPDFConfiguration()
            webView.createPDF(configuration: cfg, completionHandler: on_complete)

        } else {
            on_complete(.failure(WKWebViewDelegateErrors.notImplemented))
        }
        */
    }
}
