import Foundation
import WebKit
import Logging

public enum Status {
    case printing
    case printed
    case complete
}

public enum Errors: Error {
    case runLoopExit
    case notImplemented
    case pdfOperationFailed
}

public class Webster {
    
    /// Dots-per-inch of the PDF file to create
    public var dpi: Double = 72.0
    
    /// Width in inches of the PDF file to create
    public var width: Double = 8.5
    
    /// Height in inches of the PDF file to create
    public var height: Double = 11.0
    
    /// Margin in inches of the PDF file to create
    public var margin: Double = 1.0
    
    /// swift-log instance for webster related logging
    public var logger = Logger(label: "webster", factory: StreamLogHandler.standardError)
    
    private var rendering = false
    private var working = false
    
    public init() {
     
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "status"),
                                               object: nil,
                                               queue: .main) { (notification) in
            
            let status = notification.object as! Status
            self.logger.debug("Received status notification: \(status)")
            
            switch status {
            case Status.complete:
                self.working = false
            case Status.printed:
                self.rendering = false
            default:
                ()
            }
        }
    }
    
    public func render(source: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void {

        working = true
        
        self.renderAsync(source: source, completionHandler: completionHandler)
        
        let runloop = RunLoop.current
        
        while working && runloop.run(mode: .default, before: .distantFuture) {
            
        }
        
        return
    }
    
    private func renderAsync(source: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void {
                
        if #available(OSX 10.16, *) {
            
            completionHandler(.failure(Errors.notImplemented))
            return
            
            /*
             let webView = WKWebView()
             let delegate = WKWebViewDelegate(completionHandler: completionHandler)
             
             webView.navigationDelegate = delegate
             webView.load(URLRequest(url: source))
             
            return
             */
            
        } else {
            
            defer {
                NotificationCenter.default.post(name: Notification.Name("status"), object: Status.complete)
            }
            
            // before iOS 14, MacOS 11
            
            let webView = WebView()
            let delegate = WebViewDelegate()
            
            delegate.dpi = CGFloat(dpi)
            delegate.width = CGFloat(width)
            delegate.height = CGFloat(height)
            delegate.margin = CGFloat(margin)
            
            webView.frameLoadDelegate = delegate
            
            webView.frame = NSRect(x: 0.0, y: 0.0, width: 800, height: 640)
            webView.mainFrame.load(URLRequest(url: source))
            
            // Blocking run loop is required to wait for the PDF to be generated.
            
            rendering = true
            
            let runloop = RunLoop.current
                                
            while rendering && runloop.run(mode: .default, before: .distantFuture) {
                
            }
            webView.frameLoadDelegate = nil
            
            if rendering {
                completionHandler(.failure(Errors.runLoopExit))
                return
            }
            
            guard let pdfData = delegate.outputData else {
                completionHandler(.failure(Errors.pdfOperationFailed))
                return
            }
            completionHandler(.success(pdfData))
        }
        
    }
}
