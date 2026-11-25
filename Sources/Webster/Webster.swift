import Foundation
import WebKit
import Logging

public enum Errors: Error {
    case runLoopExit
    case printFailed
}

@MainActor
public final class Webster {
    
    /// Width in inches of the PDF file to create
    public var width: Double = 8.5
    
    /// Height in inches of the PDF file to create
    public var height: Double = 11.0

    /// Size of page bleed in inches to add to all four sides of each page
    public var bleed: Double = 0.0
    
    /// Margins in inches of the PDF file to create
    public var marginTop: Double = 1.0
    public var marginBottom: Double = 1.0
    public var marginLeft: Double = 1.0
    public var marginRight: Double = 1.0

    /// Optional left and right margins in inches for odd and even pages.
    /// When set they override `marginLeft` and `marginRight` for those pages.
    public var marginLeftOdd: Double?
    public var marginLeftEven: Double?
    public var marginRightOdd: Double?
    public var marginRightEven: Double?
    
    /// Maximum time in seconds to wait for a page to load and print
    public var timeout: TimeInterval = 60.0

    /// Maximum time in seconds to wait for images to load before printing
    public var imageTimeout: TimeInterval = 20.0
    
    private var logger = Logger(label: "webster")
    
    // LoggingSystem.bootstrap may only be called once per process.
    private static let bootstrapLogging: Void = {
        LoggingSystem.bootstrap { label in StreamLogHandler.standardError(label: label) }
    }()
    
    public init() {
        _ = Webster.bootstrapLogging
    }
    
    public func setLogLevel(level: Logger.Level) -> Void {
        self.logger.logLevel = level
        self.logger.debug("Log level set to \(level)")
    }
    
    /// Renders `source` to a PDF and calls `completionHandler` with the result.
    ///
    /// This blocks the calling (main) thread, spinning its run loop, until
    /// rendering finishes or `timeout` elapses.
    public func render(source: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void {
          
        // WKWebView must be hosted in a window for the print operation to run.
        // AppKit also needs an NSApplication to exist (e.g. when hosted by a test runner).
        _ = NSApplication.shared
        
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 640),
                              styleMask: [.borderless],
                              backing: .buffered,
                              defer: false)
        window.isReleasedWhenClosed = false
        
        let webView = WKWebView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView = webView
        
        let delegate = WKWebViewDelegate()
        delegate.window = window
        
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
        
        delegate.width = CGFloat(width)
        delegate.height = CGFloat(height)
        delegate.marginTop = CGFloat(marginTop)
        delegate.marginBottom = CGFloat(marginBottom)
        delegate.marginLeft = CGFloat(marginLeft)
        delegate.marginRight = CGFloat(marginRight)
        delegate.marginLeftOdd = marginLeftOdd.map { CGFloat($0) }
        delegate.marginLeftEven = marginLeftEven.map { CGFloat($0) }
        delegate.marginRightOdd = marginRightOdd.map { CGFloat($0) }
        delegate.marginRightEven = marginRightEven.map { CGFloat($0) }
        delegate.bleed = CGFloat(bleed)
        delegate.imageTimeout = imageTimeout
        delegate.target = target
        
        var finished = false
        
        delegate.onFinished = { [logger] in
            logger.debug("Rendering finished")
            finished = true
        }
        
        webView.navigationDelegate = delegate
        
        if source.isFileURL {
            webView.loadFileURL(source, allowingReadAccessTo: source.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: source))
        }
        
        // Blocking run loop is required to wait for the PDF to be generated.
        
        let runloop = RunLoop.current
        let deadline = Date().addingTimeInterval(timeout)
        
        while !finished && Date() < deadline && runloop.run(mode: .default, before: deadline) {
            
        }
        
        if !finished {
            completionHandler(.failure(Errors.runLoopExit))
            return
        }
        
        if let error = delegate.error {
            completionHandler(.failure(error))
            return
        }
        
        do {
            completionHandler(.success(try Data(contentsOf: target)))
        } catch (let error) {
            completionHandler(.failure(error))
        }
    }
}
