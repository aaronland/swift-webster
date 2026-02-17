import Foundation
import WebKit
import Logging

public enum Status {
    case printing
    case printed
    case complete
    case omg
    case wtf
    case bbq
}

public enum Errors: Error {
    case runLoopExit
    case notImplemented
    case unknownDimensions
}

@available(macOS 11.0, *)
public class Webster {
    
    /// Dots-per-inch of the PDF file to create
    public var dpi: Double = 72.0
    
    /// Width in inches of the PDF file to create
    public var width: Double = 8.5
    
    /// Height in inches of the PDF file to create
    public var height: Double = 11.0
    
    /// Size of page bleed in inches to add to all four sides of each page
    public var bleed: Double = 0.0
    
    /// Margin in inches of the PDF file to create
    public var margin: Double = 1.0
    
    private var logger: Logger?
    private var rendering = false
    private var working = false
    
    public init(_ logger: Logger? = nil) {
                
        self.logger = logger
        
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "status"),
                                               object: nil,
                                               queue: .main) { [self] (notification) in
            
            let status = notification.object as! Status
            logger?.debug("Received status notification: \(status)")
            
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
    
    @MainActor public func render(source: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void {
        
        working = true
        
        logger?.debug("Render \(source.absoluteString)")
        
        self.renderAsync(source: source, completionHandler: completionHandler)
        
        let runloop = RunLoop.current
        
        while working && runloop.run(mode: .default, before: .distantFuture) {
            self.logger?.debug("Working")
        }
        
        self.logger?.debug("Done rendering")
        return
    }
    
    @MainActor private func renderAsync(source: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void {
        
        defer {
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.complete)
        }
        
        self.logger?.debug("Render \(source.absoluteString)")
        
        let webView = WKWebView()
        let delegate = WKWebViewPDFDelegate(completionHandler: completionHandler)
        webView.navigationDelegate = delegate
        
        webView.frame = NSRect(x: 0.0, y: 0.0, width: 800, height: 640)
        
        logger?.debug("Load \(source.absoluteString)")
        webView.loadURL(url: source)
    }
}
