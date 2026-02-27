import Foundation
import WebKit
import Logging

@available(macOS 13.0, *)
public class Webster {

    public var dpi: Double = 72.0
    public var width: Double = 8.5
    public var height: Double = 11.0
    public var bleed: Double = 0.0
    public var margin: Double = 1.0

    private var logger: Logger?
    private var activeJobs = [RenderJob]()

    public init(_ logger: Logger? = nil) {
        self.logger = logger
    }

    @MainActor
    public func render(source: URL,
                       completionHandler: @escaping (Result<Data, Error>) -> Void) {
        logger?.debug("Render \(source.absoluteString)")

        let group = DispatchGroup()
            group.enter()   // we will leave in the job’s finish()

            let job = RenderJob(url: source,
                                completionHandler: completionHandler,
                                owner: self,
                                logger: logger,
                                group: group)
            activeJobs.append(job)

            // Wait until the job signals `group.leave()`
            _ = group.wait(timeout: .distantFuture)
    }

    fileprivate func jobDidFinish(_ job: RenderJob) {
        self.logger?.debug("Did finish \(job)")
        // Drop the strong reference – the job will be de‑allocated.
        if let idx = activeJobs.firstIndex(where: { $0 === job }) {
            activeJobs.remove(at: idx)
        }
    }
}

@available(macOS 13.0, *)
@MainActor
private class RenderJob {
    let webView: WKWebView
    private let completion: (Result<Data, Error>) -> Void
    private weak var owner: Webster?

    var logger: Logger?
    
    // MARK: – Lazy delegate so that `self` is fully initialised
    private lazy var delegate: WKWebViewPDFDelegate = {
        WKWebViewPDFDelegate(completionHandler: { @Sendable [weak self] result in
            self?.finish(result)
        })
    }()

    private let group: DispatchGroup

        init(url: URL,
             completionHandler: @escaping (Result<Data, Error>) -> Void,
             owner: Webster,
             logger: Logger? = nil,
             group: DispatchGroup) {

            self.completion = completionHandler
            self.owner = owner
            self.webView = WKWebView(frame: .init(x: 0, y: 0, width: 800, height: 640))
            self.logger = logger
            self.group = group

            webView.navigationDelegate = delegate
            logger?.debug("Load \(url)")
            webView.load(URLRequest(url: url))
        }

        private func finish(_ result: Result<Data, Error>) {
            self.logger?.debug("Did finish w \(result)")
            completion(result)
            owner?.jobDidFinish(self)
            group.leave()               // <‑‑ signal completion
        }
}

@available(macOS 13.0, *)
private class WKWebViewPDFDelegate: NSObject, WKNavigationDelegate {

    private let onComplete: (Result<Data, Error>) -> Void
    var logger: Logger?
    
    init(completionHandler: @escaping (Result<Data, Error>) -> Void, logger: Logger? = nil) {
        self.onComplete = completionHandler
        self.logger = logger
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Evaluate the size of the content
        self.logger?.debug("YO")
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak webView] (heightObj, error) in
            guard let webView = webView,
                  let height = heightObj as? CGFloat,
                  error == nil else { return }

            webView.evaluateJavaScript("document.body.scrollWidth") { (widthObj, error) in
                guard let width = widthObj as? CGFloat,
                      error == nil else { return }

                let cfg = WKPDFConfiguration()
                cfg.rect = CGRect(origin: .zero, size: CGSize(width: width, height: height))

                webView.createPDF(configuration: cfg) { result in
                    switch result {
                    case .success(let data):
                        self.onComplete(.success(data))
                    case .failure(let err):
                        self.onComplete(.failure(err))
                    }
                }
            }
        }
    }
}
