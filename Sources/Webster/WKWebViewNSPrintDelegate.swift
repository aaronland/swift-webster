import Foundation
import WebKit

@available(macOS 11.0, *)
public class WKWebViewNSPrintDelegate: NSObject, WKNavigationDelegate {
        
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
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printed)
            // NotificationCenter.default.post(name: Notification.Name("status"), object: Status.complete)
        }
        
        let printOpts: [NSPrintInfo.AttributeKey : Any] = [
            NSPrintInfo.AttributeKey.jobDisposition : NSPrintInfo.JobDisposition.save,
            NSPrintInfo.AttributeKey.jobSavingURL   : target!
        ]
         
        // print("TARGET \(target)")
        
        let printInfo: NSPrintInfo = NSPrintInfo(dictionary: printOpts)
        let baseMargin: CGFloat = (margin + bleed) * dpi
        
        let w = width + (bleed * 2.0)
        let h = height + (bleed * 2.0)
        
        printInfo.paperSize    = NSMakeSize(w * dpi, h * dpi)
        printInfo.topMargin    = baseMargin
        printInfo.leftMargin   = baseMargin
        printInfo.rightMargin  = baseMargin
        printInfo.bottomMargin = baseMargin
                
        // This just runs() forever with no feedback (below):
        let printOp = webView.printOperation(with: printInfo)
        
        // This panics:
        // Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[WKWebView webFrame]: unrecognized selector sent to instance 0x7fe3a3a06550'
        // But anyway, webFrame is deprecated:
        // https://developer.apple.com/documentation/webkit/domdocument/1536374-webframe
        // let printOp: NSPrintOperation = NSPrintOperation(view: webView.webFrame.frameView.documentView, printInfo: printInfo)
        
        // This just prints a single blank page
        // let printOp: NSPrintOperation = NSPrintOperation(view: webView, printInfo: printInfo)
                
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false
        
        // printOp.view?.frame = NSRect(x: 0.0, y: 0.0, width: 300.0, height: 300.0)
        
        // https://developer.apple.com/documentation/appkit/nsprintoperation/1532039-runoperation
        printOp.run()
                
        // OMGWTF...
        // https://www.hackingwithswift.com/forums/macos/printing-almost-works-but/27196
        // https://forums.developer.apple.com/forums/thread/705138 <-- maybe this?
        // printOp.runModal(for: webView.window!, delegate: nil, didRun: nil, contextInfo: nil)

        return
    }
}
