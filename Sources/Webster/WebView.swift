import Foundation
import WebKit

// All of this changes in OS X 10.16/11 when WebKit is formally replaced by
// WKWebKit and WKWebKit.WebView finally gets a createPDF method...
// https://developer.apple.com/documentation/webkit/wkwebview/3650490-createpdf

class WebViewDelegate: NSObject, WebFrameLoadDelegate {
    
    public var dpi: CGFloat = 72.0
    public var margin: CGFloat = 1.0
    public var width: CGFloat = 6.0
    public var height: CGFloat = 9.0
    public var target: URL!
    
    private var destination = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    private var filename: String = "webster.pdf"
    
    override init() {
        target = destination.appendingPathComponent(filename)
    }
    
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        
        NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printing)
        
        defer {
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.complete)
        }
                    
        let printOpts: [NSPrintInfo.AttributeKey : Any] = [
            NSPrintInfo.AttributeKey.jobDisposition : NSPrintInfo.JobDisposition.save,
            NSPrintInfo.AttributeKey.jobSavingURL   : target!
        ]
                
        let printInfo: NSPrintInfo = NSPrintInfo(dictionary: printOpts)
        let baseMargin: CGFloat    = margin * dpi
        
        printInfo.paperSize    = NSMakeSize(width * dpi, height * dpi)
        printInfo.topMargin    = baseMargin
        printInfo.leftMargin   = baseMargin
        printInfo.rightMargin  = baseMargin
        printInfo.bottomMargin = baseMargin
        
        let printOp: NSPrintOperation = NSPrintOperation(view: sender.mainFrame.frameView.documentView, printInfo: printInfo)
        
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false
        printOp.run()
    }
}
