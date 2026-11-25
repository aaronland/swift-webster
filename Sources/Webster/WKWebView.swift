import Foundation
import WebKit
import AppKit

/// Prints a loaded `WKWebView` to a paginated PDF file using `NSPrintOperation`.
///
/// `WKWebView.createPDF` produces a single page sized to the content, and a bare
/// `printOperation.run()` never returns for a web view. Running the operation
/// against a window (`runModal(for:)`) with the save disposition produces
/// properly paginated output.
@MainActor
final class WKWebViewDelegate: NSObject, WKNavigationDelegate {

    var marginTop: CGFloat = 1.0
    var marginBottom: CGFloat = 1.0
    var marginLeft: CGFloat = 1.0
    var marginRight: CGFloat = 1.0
    var marginLeftOdd: CGFloat?
    var marginLeftEven: CGFloat?
    var marginRightOdd: CGFloat?
    var marginRightEven: CGFloat?
    var bleed: CGFloat = 0.0
    var imageTimeout: TimeInterval = 20.0
    var width: CGFloat = 8.5
    var height: CGFloat = 11.0
    var target: URL!
    var window: NSWindow!

    /// Set if loading or printing failed.
    var error: Error?

    /// Called once when printing has finished or loading/printing has failed.
    var onFinished: (() -> Void)?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        // didFinish fires before images have necessarily loaded (and lazy images
        // never load while off-screen), so wait for them before printing.
        let script = """
        // Pages may carry their own @page margins (often !important); ours win.
        const style = document.createElement('style');
        style.textContent = css;
        document.head.appendChild(style);
        const images = Array.from(document.images);
        images.forEach(img => { img.loading = 'eager'; });
        const loaded = Promise.all(images.map(img => img.complete ? null : new Promise(resolve => {
            img.addEventListener('load', resolve);
            img.addEventListener('error', resolve);
        })));
        const timeout = new Promise(resolve => setTimeout(resolve, imageTimeoutSeconds * 1000));
        await Promise.race([loaded, timeout]);
        if (document.fonts) { await document.fonts.ready; }
        return images.length;
        """

        let css = pageCSS()
        let imageTimeoutSeconds = imageTimeout
        Task { @MainActor [weak self] in
            _ = try? await webView.callAsyncJavaScript(script, arguments: ["css": css, "imageTimeoutSeconds": imageTimeoutSeconds], in: nil, contentWorld: .page)
            self?.printPages(webView)
        }
    }

    // Horizontal geometry in inches, including bleed. WebKit lays the document out
    // once and ignores `@page :left` / `:right` margins after the first page, so
    // content is laid out for odd pages using a width that fits both page kinds,
    // and even pages are shifted afterwards (see `shiftEvenPages`).
    private var pageWidth: CGFloat { width + bleed * 2.0 }
    private var leftOdd: CGFloat { (marginLeftOdd ?? marginLeft) + bleed }
    private var rightOdd: CGFloat { (marginRightOdd ?? marginRight) + bleed }
    private var leftEven: CGFloat { (marginLeftEven ?? marginLeft) + bleed }
    private var rightEven: CGFloat { (marginRightEven ?? marginRight) + bleed }
    private var contentWidth: CGFloat { pageWidth - max(leftOdd + rightOdd, leftEven + rightEven) }
    private var layoutLeft: CGFloat { leftOdd }
    private var layoutRight: CGFloat { pageWidth - leftOdd - contentWidth }

    private func pageCSS() -> String {
        func inches(_ v: CGFloat) -> String { "\(Double(v))in" }
        return "@page { margin: \(inches(marginTop + bleed)) \(inches(layoutRight)) \(inches(marginBottom + bleed)) \(inches(layoutLeft)) !important; }"
    }

    /// Redraws the PDF with the content of even pages moved horizontally. Text and
    /// vector content are preserved, but link annotations are not.
    private func shiftEvenPages(at url: URL) -> Bool {
        let dx = (leftEven - leftOdd) * 72.0
        if dx == 0 { return true }

        guard let source = CGPDFDocument(url as CFURL), source.numberOfPages > 0 else { return false }

        let shifted = url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString + ".pdf")
        var mediaBox = source.page(at: 1)?.getBoxRect(.mediaBox) ?? .zero
        guard let context = CGContext(shifted as CFURL, mediaBox: &mediaBox, nil) else { return false }

        for number in 1...source.numberOfPages {
            guard let page = source.page(at: number) else { continue }
            var box = page.getBoxRect(.mediaBox)
            context.beginPage(mediaBox: &box)
            if number % 2 == 0 {
                context.translateBy(x: dx, y: 0)
            }
            context.drawPDFPage(page)
            context.endPage()
        }
        context.closePDF()

        do {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: shifted)
            return true
        } catch {
            try? FileManager.default.removeItem(at: shifted)
            return false
        }
    }

    private func printPages(_ webView: WKWebView) {

        let printOpts: [NSPrintInfo.AttributeKey: Any] = [
            .jobDisposition: NSPrintInfo.JobDisposition.save,
            .jobSavingURL: target!
        ]

        let printInfo = NSPrintInfo(dictionary: printOpts)
        // NSPrintInfo works in points (1/72 inch).
        let pointsPerInch: CGFloat = 72.0

        let w = (width + bleed * 2.0) * pointsPerInch
        let h = (height + bleed * 2.0) * pointsPerInch

        printInfo.paperSize = NSSize(width: w, height: h)
        let top = (marginTop + bleed) * pointsPerInch
        let bottom = (marginBottom + bleed) * pointsPerInch
        let left = layoutLeft * pointsPerInch
        let right = layoutRight * pointsPerInch
        printInfo.topMargin = top
        printInfo.leftMargin = left
        printInfo.rightMargin = right
        printInfo.bottomMargin = bottom

        let printOp = webView.printOperation(with: printInfo)
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false

        // The print view needs an explicit frame or nothing is rendered.
        printOp.view?.frame = NSRect(x: 0, y: 0, width: w - left - right, height: h - top - bottom)

        printOp.runModal(for: window,
                         delegate: self,
                         didRun: #selector(printOperationDidRun(_:success:contextInfo:)),
                         contextInfo: nil)
    }

    // AppKit may invoke this callback off the main thread, so it can't be main-actor isolated.
    @objc nonisolated func printOperationDidRun(_ printOperation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
        Task { @MainActor [weak self] in
            self?.printFinished(success: success)
        }
    }

    private func printFinished(success: Bool) {
        if !success || !shiftEvenPages(at: target!) {
            error = Errors.printFailed
        }
        onFinished?()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fail(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        fail(error)
    }

    private func fail(_ error: Error) {
        self.error = error
        onFinished?()
    }
}
