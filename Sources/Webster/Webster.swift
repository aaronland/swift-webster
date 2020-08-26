import Foundation
import WebKit
import Logging

public enum Status {
    case printing
    case complete
}

public enum Errors: Error {
    case runLoopExit
    case notImplemented
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
    
    private let logger = Logger(label: "webster", factory: StreamLogHandler.standardError)
    
    public init() {
                
    }
    
    public func render(source: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void {

        print("RENDER")
        
        if #available(iOS 14.0, macCatalyst 14.0, *) {
            
            completionHandler(.failure(Errors.notImplemented))
            return
            
            /*
            let webView = WKWebView()
            let delegate = WKWebViewDelegate(completionHandler: completionHandler)
            
            webView.navigationDelegate = delegate
            
            webView.load(URLRequest(url: source))
            return
            */
        }
        
        print("BEFORE")
        
        // before iOS 14, MacOS 11
        
            let webView = WebView()
            let delegate = WebViewDelegate()
            
        /*
         
         Ideally we would just write directly to pdf_data but I am unsure
         about how to do that with NSPrintOperation (see notes in WebView.swift)
         so instead we will create a temporary file, write to that then
         read the data and remove the temporary file on the way out. This
         is not ideal but it makes for a cleaner interface for using this
         package and not assuming that files are always been written.
         (20200823/straup)
         */
        
        var pdf_data: Data!
        
        let temp_dir = URL(fileURLWithPath: NSTemporaryDirectory(),
                                                       isDirectory: true)
        
        let fname = UUID().uuidString + ".pdf"

        let target = temp_dir.appendingPathComponent(fname)
        
        defer {
            do {
                try FileManager.default.removeItem(at: target)
            } catch (let error) {
                logger.warning("Failed to remove \(target.absoluteString), \(error.localizedDescription)")
            }
        }
        
        delegate.dpi = CGFloat(dpi)
        delegate.width = CGFloat(width)
        delegate.height = CGFloat(height)
        delegate.margin = CGFloat(margin)
        delegate.target = target
        
        webView.frameLoadDelegate = delegate
        
        webView.frame = NSRect(x: 0.0, y: 0.0, width: 800, height: 640)
        webView.mainFrame.load(URLRequest(url: source))
        
        // Blocking run loop is required to wait for the PDF to be generated.
        
        var working = true
        let runloop = RunLoop.current
           
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "status"),
                                               object: nil,
                                               queue: .main) { (notification) in
            
            let status = notification.object as! Status

            switch status {
            case Status.complete:
                    working = false
            default:
                ()
            }
        }
        
        while working && runloop.run(mode: .default, before: .distantFuture) {
            
        }
        
        if working {
            print("WHAT")
            completionHandler(.failure(Errors.runLoopExit))
            return
        }
                
        do {
            try pdf_data = Data(contentsOf: target)
        } catch (let error) {
            completionHandler(.failure(error))
            return
        }
        
        completionHandler(.success(pdf_data))
        return

    }
}
