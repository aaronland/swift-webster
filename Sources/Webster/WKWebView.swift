import Foundation
import WebKit

public enum WKWebViewDelegateErrors: Error {
    case notImplemented
}

extension WKWebView {
    
    func loadURL(url: URL) {
        
        let request = URLRequest(url: url)
        self.load(request)
        
        while (self.isLoading) {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        
    }
}
