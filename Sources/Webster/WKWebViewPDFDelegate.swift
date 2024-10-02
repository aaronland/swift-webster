import Foundation
import WebKit

@available(macOS 11.0, *)
public class WKWebViewPDFDelegate: NSObject, WKNavigationDelegate {
    
    var on_complete: (Result<Data, Error>) -> Void
    
    public init(completionHandler: @escaping (Result<Data, Error>) -> Void){
        on_complete = completionHandler
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // print("DID COMMIT")
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        // print("FAILED \(error)")
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        // print("FAIL PROVISIONAL")
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // print("START")
    }
    
    // https://developer.apple.com/documentation/webkit/wkwebview/3650490-createpdf

    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printing)
        
        defer {
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printed)
        }
        
        webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
            if complete == nil {
                return
            }
            
            if error != nil {
                return
            }
            
            webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
            
                if error != nil {
                    return
                }
                
                guard let h = height as? CGFloat else {
                    return
                }

                webView.evaluateJavaScript("document.body.scrollWidth", completionHandler: { (width, error) in

                    if error != nil {
                        return
                    }
                    
                    guard let w = width as? CGFloat else {
                        return
                    }
                       
                    // This works but prints a single page with these dimensions
                    // so... "works"
                    
                    let cfg = WKPDFConfiguration()
                    cfg.rect = .init(origin: .zero, size: .init(width: w, height: h))

                        webView.createPDF(configuration: cfg){ result in
                            switch result {
                            case .success(let data):
                                print("DATA")
                                self.on_complete(.success(data))
                            case .failure(let err):
                                print("SAD 3 \(err)")
                                self.on_complete(.failure(err))
                            }
                        }
                    })
                })
            
            
        })
        
        


    }
}
