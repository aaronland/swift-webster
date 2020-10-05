import Foundation
import WebKit

class WebViewDelegate: NSObject, WebFrameLoadDelegate {
    
    public var dpi: CGFloat = 72.0
    public var margin: CGFloat = 1.0
    public var width: CGFloat = 6.0
    public var height: CGFloat = 9.0
    public var outputData: Data?
    
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        
        NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printing)
        
        defer {
            NotificationCenter.default.post(name: Notification.Name("status"), object: Status.printed)
        }
                            
        // https://developer.apple.com/documentation/appkit/nsprintoperation
                
        let printInfo: NSPrintInfo = NSPrintInfo()
        let baseMargin: CGFloat    = margin * dpi
        
        printInfo.paperSize    = NSMakeSize(width * dpi, height * dpi)
        printInfo.topMargin    = baseMargin
        printInfo.leftMargin   = baseMargin
        printInfo.rightMargin  = baseMargin
        printInfo.bottomMargin = baseMargin
        
        let targetData = NSMutableData()
        guard let documentView = sender.mainFrame.frameView.documentView else {
            return
        }
        let printOp = NSPrintOperation.pdfOperation(with: documentView, inside: documentView.bounds, to: targetData, printInfo: printInfo)
        
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false
        printOp.run()
        
        outputData = targetData as Data
    }
}
