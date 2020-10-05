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

Prior to iOS 14 and MacOS 10.16 this package uses [NSPrintOperation](https://developer.apple.com/documentation/appkit/nsprintoperation) to render a `WebView`.

_Really what we want is to be able to pass the `NSPrintOperation` method something like an abstract "writer" similar to the Go language [io.Writer](https://golang.org/pkg/io/) interface but this is not possible in Swift. Perhaps in future releases the [WKWebView.createPDF](https://developer.apple.com/documentation/webkit/wkwebview/3650490-createpdf) method will adopt the publish/subscribe model used in Apple's [Combine](https://developer.apple.com/documentation/combine) framework but today it does not._

## Credits

This build's on @msmollin's original [webster](https://github.com/msmollin/webster) and currently exists as a separate project because it is full of Swift Package Manager -isms and I am not sure what the best way to create a PR is yet.

## See also

* https://github.com/aaronland/webster-cli
