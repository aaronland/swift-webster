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
    
    // var on_complete: (Result<Data, Error>) -> Void
    
    public var dpi: CGFloat = 72.0
    public var margin: CGFloat = 1.0
    public var bleed: CGFloat = 0.0
    public var width: CGFloat = 6.0
    public var height: CGFloat = 9.0
    public var target: URL!
    
    private var destination = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private var filename: String = "webster.pdf"
    
    override init() {
        target = destination.appendingPathComponent(filename)
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
        
        let printOpts: [NSPrintInfo.AttributeKey : Any] = [
            NSPrintInfo.AttributeKey.jobDisposition : NSPrintInfo.JobDisposition.save,
            NSPrintInfo.AttributeKey.jobSavingURL   : target!
        ]
         
        print("TARGET \(target)")
        
        let printInfo: NSPrintInfo = NSPrintInfo(dictionary: printOpts)
        let baseMargin: CGFloat = (margin + bleed) * dpi
        
        let w = width + (bleed * 2.0)
        let h = height + (bleed * 2.0)
        
        printInfo.paperSize    = NSMakeSize(w * dpi, h * dpi)
        printInfo.topMargin    = baseMargin
        printInfo.leftMargin   = baseMargin
        printInfo.rightMargin  = baseMargin
        printInfo.bottomMargin = baseMargin

        let printOp: NSPrintOperation = NSPrintOperation(view: webView, printInfo: printInfo)
        // let printOp = webView.printOperation(with: printInfo)
        
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false
        printOp.run()
        return
    }
}

@available(macOS 11.0, *)
public class WKWebViewPDFDelegate: NSObject, WKNavigationDelegate {
    
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
        
        NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printing)
        
        defer {
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printed)
        }
        
         let cfg = WKPDFConfiguration()
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

    }
}
