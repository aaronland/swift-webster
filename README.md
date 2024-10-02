# swift-webster

Swift package for generating a PDF file from a URL (rendered by WebKit).

## Example

```
import Webster

guard let source_url = URL(string: "https://example.com") else {
    fatalError("Invalid source URL.")
}

let w = Webster()

w.dpi = 72.0
w.width = 11.0
w.height = 8.5
w.margin = 0.5

on_complete = func(result: Result<Data, Error) -> Void {

    if case .failure(let error) = result {
        fatalError("Failed to generate PDF file, \(error.localizedDescription)")
    }

    if case .success(let data) = result {
        // Do something with data here
    }
}

w.render(source: source_url, completionHandler: on_complete)
```

## Notes

### This package uses deprecated APIs

This package uses deprecated APIs notably [WebView](https://developer.apple.com/documentation/webkit/webview).

Specifically, this package is uses [NSPrintOperation](https://developer.apple.com/documentation/appkit/nsprintoperation) to render a `WebView`. Ideally I would like `NSPrintOperation` to print directly to a `Data` instance but it's not possible to do this. Instead the `render` method creates a temporary file, writes to it, reads the data and removes the temporary file on exit. This introduces extra overhead but, hopefully, keeps the interface a little more agnostic about how the resultant PDF document is used.

### There is a WKWebView branch

There is a [wkwebview](https://github.com/aaronland/swift-webster/tree/wkwebview) branch that uses the newer [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview) APIs however it does not work. I can not determine for sure if the problem is with my code or with Apple's MacOS APIs. It seems like the latter but I would be happy for it to be the former. This branch has two separate delegates, neither of which work as desired.

The [first](https://github.com/aaronland/swift-webster/blob/wkwebview/Sources/Webster/WKWebViewNSPrintDelegate.swift) calls `webView.printOperation` as recommended by the documentation. However when the `printOperation.run()` method is invoked it never completes. Apparently, I am supposed to invoke the `printOperation.runModal` method but that depends on a `NSWindow` instance which is not present in the final `webView` instance.

The [second](https://github.com/aaronland/swift-webster/blob/wkwebview/Sources/Webster/WKWebViewPDFDelegate.swift) calls `webView.createPDF` as recommended by the documentation but this produces a single PDF file the size of the final web page's dimensions. Maybe this is the expected behaviour?

Any pointers or suggestions for how to address either of these issues would be welcome.

## Credits

This build's on @msmollin's original [webster](https://github.com/msmollin/webster) and currently exists as a separate project because it is full of Swift Package Manager -isms and I am not sure what the best way to create a PR is yet.

## See also

* https://github.com/aaronland/webster-cli
