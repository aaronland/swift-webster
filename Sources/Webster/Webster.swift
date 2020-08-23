import Foundation
import WebKit
import Logging

public enum Status {
    case printing
    case complete
}

public enum Errors: Error {
    case runLoopExit
}

public class Webster {
    
    public var dpi: Double = 72.0
    
    public var width: Double = 8.5
    
    public var height: Double = 11.0
    
    public var margin: Double = 1.0
   
    private let webView = WebView()
    private let delegate = WebViewDelegate()
    
    private let logger = Logger(label: "webster", factory: StreamLogHandler.standardError)
    
    public init() {
                
    }
    
    public func render(source: URL) -> Result<Data, Error> {

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
        
        //This little bit gets us a runloop and spins it. Otherwise nothing above here works.
        
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
            return .failure(Errors.runLoopExit)
        }
        
        var data: Data!
        
        do {
            try data = Data(contentsOf: target)
        } catch (let error) {
            return .failure(error)
        }
        
        return .success(data)
        
    }
}
