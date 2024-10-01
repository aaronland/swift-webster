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
    
    private var logger = Logger(label: "webster")
    private var rendering = false
    private var working = false
    
    public init() {
        
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        
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
    
    public func setLogLevel(level: Logger.Level) -> Void {
        self.logger.logLevel = level
        self.logger.debug("Log level set to \(level)")
    }
    
    public func render(source: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void {
        
        working = true
        
        self.renderAsync(source: source, completionHandler: completionHandler)
        
        let runloop = RunLoop.current
        
        while working && runloop.run(mode: .default, before: .distantFuture) {
            self.logger.debug("Working")
        }
        
        self.logger.debug("Done rendering")
        return
    }
    
    private func renderAsync(source: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void {
        
        defer {
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.complete)
        }
        
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
        
        let printOpts: [NSPrintInfo.AttributeKey : Any] = [
            NSPrintInfo.AttributeKey.jobDisposition : NSPrintInfo.JobDisposition.save,
            NSPrintInfo.AttributeKey.jobSavingURL   : target
        ]
              
        //
        
        let printInfo: NSPrintInfo = NSPrintInfo(dictionary: printOpts)
        let baseMargin: CGFloat = (margin + bleed) * dpi
        
        let w = width + (bleed * 2.0)
        let h = height + (bleed * 2.0)
        
        printInfo.paperSize    = NSMakeSize(w * dpi, h * dpi)
        printInfo.topMargin    = baseMargin
        printInfo.leftMargin   = baseMargin
        printInfo.rightMargin  = baseMargin
        printInfo.bottomMargin = baseMargin
       
        rendering = true

        // 10.16 -isms need more testing; not working as expected
        // meaning methods don't fail but PDF files are not created
        
        // https://www.artemnovichkov.com/blog/async-await-offline
        
        if #available(OSX 10.16, *) {
            
            self.logger.debug("Render \(source) with WKWebView")
            
            let webView = WKWebView()

            let delegate = WKWebViewDelegate(printInfo: printInfo, completionHandler: completionHandler)
            
            webView.navigationDelegate = delegate
            webView.loadURL(url: source)
            
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.bbq)
            
        } else {
            
            // before iOS 14, MacOS 11
            
            self.logger.debug("Render \(source) with WebView (deprecated)")
            
            let webView = WebView()
            let delegate = WebViewDelegate()
            
            /*
             
             Ideally we would just write directly to pdf_data but this is
             not possible with NSPrintOperation so instead we will create a
             temporary file, write to that then read the data and remove the
             temporary file on the way out. This is not ideal but it makes
             for a cleaner interface for using this package and not assuming
             that files are always been written (20200823/straup)
             
             */
                        
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
            delegate.width = CGFloat(width + (bleed * 2.0))
            delegate.height = CGFloat(height + (bleed * 2.0))
            delegate.margin = CGFloat(margin)
            delegate.target = target
            
            webView.frameLoadDelegate = delegate
            
            webView.frame = NSRect(x: 0.0, y: 0.0, width: 800, height: 640)
            webView.mainFrame.load(URLRequest(url: source))
        }
        
        NotificationCenter.default.post(name: Notification.Name("status"), object: Status.omg)

        var pdf_data: Data!
        
            // Blocking run loop is required to wait for the PDF to be generated.
                        
            let runloop = RunLoop.current
            
            while rendering && runloop.run(mode: .default, before: .distantFuture) {
                logger.debug("Rendering")
            }
            
            if rendering {
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
