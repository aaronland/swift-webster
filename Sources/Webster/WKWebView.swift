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
    var print_info: NSPrintInfo
    
    public init(printInfo: NSPrintInfo, completionHandler: @escaping (Result<Data, Error>) -> Void){
        on_complete = completionHandler
        print_info = printInfo

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
            print("DEFER")
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printed)
            // NotificationCenter.default.post(name: Notification.Name("status"), object: Status.complete)
        }
        
        let print_op = webView.printOperation(with: self.print_info)
        // print_op.showsPrintPanel = false
        // print_op.showsProgressPanel = false
        
        print("RUN")
        
        // Why does this never complete?
        // print_op.run()

        print("DONE")
        return

        /*
        let cfg = WKPDFConfiguration()
        // cfg.rect = CGRect(x: 0, y: 0, width: sz.width, height: sz.height)
        cfg.rect = .init(origin: .zero, size: .init(width: 595.28, height: 841.89))
                
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
         */
    }
}
