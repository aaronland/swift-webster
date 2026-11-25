# swift-webster

Swift package for generating a PDF file from a URL (rendered by WebKit).

## Example

```
import Webster

guard let source_url = URL(string: "https://example.com") else {
    fatalError("Invalid source URL.")
}

let w = Webster()

w.width = 11.0
w.height = 8.5
w.marginTop = 0.5
w.marginBottom = 0.5
w.marginLeft = 0.5
w.marginRight = 0.5

let on_complete = { (result: Result<Data, Error>) in

    if case .failure(let error) = result {
        fatalError("Failed to generate PDF file, \(error.localizedDescription)")
    }

    if case .success(let data) = result {
        // Do something with data here
    }
}

w.render(source: source_url, completionHandler: on_complete)
```

## Command line tool

The package also builds a `webster` executable.

```
$ swift build -c release
$ .build/release/webster [options] <source> <destination>
```

```
$ webster --width 8.5 --height 11 --margin 0.5 https://example.com example.pdf
$ webster --width 6 --height 9 --margin-left-odd 0.75 --margin-left-even 0.5 page.html book.pdf
```

* `<source>` is a URL, a `file:///` URI or a local path to an HTML file.
* `<destination>` is a plain path or a `file:///` URI.

### Options

| Option | Default | Description |
|---|---|---|
| `--width` | 8.5 | Page width in inches. |
| `--height` | 11.0 | Page height in inches. |
| `--margin` | 1.0 | Margin in inches for all sides. |
| `--margin-top`, `--margin-bottom`, `--margin-left`, `--margin-right` | `--margin` | Override a single side. |
| `--margin-left-odd`, `--margin-left-even` | `--margin-left` | Left margin for odd or even pages. |
| `--margin-right-odd`, `--margin-right-even` | `--margin-right` | Right margin for odd or even pages. |
| `--bleed` | 0.0 | Bleed in inches. |
| `--image-timeout` | 20.0 | Seconds to wait for images to load before printing. |
| `--page-timeout` | 60.0 | Seconds to wait for the whole page to load and print. Keep it above `--image-timeout`. |
| `--verbose` | off | Debug logging. |
| `-h`, `--help` | | Show help. |

Margins set here override any `@page` margin in the page's own CSS.

## Notes

### Requires macOS 12 or later

This package renders with [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview) and prints it with [NSPrintOperation](https://developer.apple.com/documentation/appkit/nsprintoperation) via `WKWebView.printOperation(with:)` (macOS 12+). The deprecated `WebView` API is no longer used.

### How pagination works

WebKit offers two ways to make a PDF, and only one gives real pages:

* `WKWebView.createPDF` renders the whole web page as one tall PDF page. It does not paginate, so it isn't used here.
* `WKWebView.printOperation(with:)` returns an `NSPrintOperation` that paginates properly using the page size and margins. But calling its `run()` method on a web view never returns.

So Webster uses the print operation and works around the hang: it puts the web view in an off-screen `NSWindow` and starts the operation with `runModal(for:)`. The operation is set to save to a file (the `save` job disposition) instead of showing a print panel. The result is a paginated PDF at the configured page size and margins.

`--margin` sets all sides; `--margin-SIDE` overrides one side, and `--margin-left-odd`/`-even` and `--margin-right-odd`/`-even` override the left and right margins for odd or even pages. WebKit lays out the whole document at one width, so the content width is the narrowest that fits both page kinds and even pages are shifted afterwards by redrawing the PDF (text and vectors are kept; link annotations are not).

`NSPrintOperation` can't print directly to a `Data` instance so the `render` method creates a temporary file, writes to it, reads the data and removes the temporary file on exit.

### `render` blocks

`render` spins the current run loop until printing finishes and must be called from the main thread. It gives up after `timeout` seconds (default 60) with `Errors.runLoopExit`. `imageTimeout` (default 20) is how long to wait for images to load before printing; keep it below `timeout`.

### Tests

Run the tests with `swift test`.

Most tests call the library directly. The test that actually renders a PDF can't: WebKit never finishes loading a page when it is run inside the test process. That test instead launches the built `webster` command line tool as a separate process, has it convert a small local HTML file, and checks that a valid PDF is produced.

## Credits

This build's on @msmollin's original [webster](https://github.com/msmollin/webster) and currently exists as a separate project because it is full of Swift Package Manager -isms and I am not sure what the best way to create a PR is yet.
