import Foundation
import WebKit

class WebViewDelegate: NSObject, WebFrameLoadDelegate {
    
    public var dpi: CGFloat = 72.0
    public var margin: CGFloat = 1.0
    public var bleed: CGFloat = 0.0
    public var width: CGFloat = 6.0
    public var height: CGFloat = 9.0
    public var target: URL!
    
    private var destination = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private var filename: String = "webster.pdf"
    
    let print_info: NSPrintInfo
    
    init(printInfo: NSPrintInfo) {
        target = destination.appendingPathComponent(filename)
        print_info = printInfo
    }
    
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        
        NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printing)
        
        defer {
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printed)
        }
                            
        // https://developer.apple.com/documentation/appkit/nsprintoperation
        
        /*
        let printOpts: [NSPrintInfo.AttributeKey : Any] = [
            NSPrintInfo.AttributeKey.jobDisposition : NSPrintInfo.JobDisposition.save,
            NSPrintInfo.AttributeKey.jobSavingURL   : target!
        ]
                
        let printInfo: NSPrintInfo = NSPrintInfo(dictionary: printOpts)
        let baseMargin: CGFloat = (margin + bleed) * dpi
        
        let w = width + (bleed * 2.0)
        let h = height + (bleed * 2.0)
        
        printInfo.paperSize    = NSMakeSize(w * dpi, h * dpi)
        printInfo.topMargin    = baseMargin
        printInfo.leftMargin   = baseMargin
        printInfo.rightMargin  = baseMargin
        printInfo.bottomMargin = baseMargin
        */
        
        let printOp: NSPrintOperation = NSPrintOperation(view: sender.mainFrame.frameView.documentView, printInfo: print_info)
        
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false
        
        print("RUNNNNNN")
        printOp.run()
        print("DONNNNNE")
    }
}
