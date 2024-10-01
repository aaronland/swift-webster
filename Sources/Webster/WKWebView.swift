import Foundation
import WebKit

extension WKWebView {
    
    func loadURL(url: URL) {

            let request = URLRequest(url: url)
            self.load(request)

            while (self.isLoading) {
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
            }
            
    }
}

public enum WKWebViewDelegateErrors: Error {
    case notImplemented
}

@available(macOS 11.0, *)
public class WKWebViewDelegate: NSObject, WKNavigationDelegate {
    
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
                
        NotificationCenter.default.post(name: Notification.Name("status"), object: Status.wtf)
            
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printing)
            
            defer {
                NotificationCenter.default.post(name: Notification.Name("status"), object: Status.complete)
            }

            let cfg = WKPDFConfiguration()
            webView.createPDF(configuration: cfg, completionHandler: on_complete)
    }
}
