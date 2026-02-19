import Foundation
import WebKit

public enum WKWebViewDelegateErrors: Error {
    case notImplemented
}

extension WKWebView {
    
    func loadURL(url: URL) {
        
        print("LOAD \(url)")
        
        let request = URLRequest(url: url)
        self.load(request)
        
        while (self.isLoading) {
            print("is loading \(self.isLoading) \(self.estimatedProgress)")
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        
    }
}
