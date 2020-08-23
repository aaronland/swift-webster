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

let result = w.render(source: source_url)
    
if case .failure(let error) = result {
    fatalError("Failed to generate PDF file, \(error.localizedDescription)")
}

if case .success(let data) = result {
    // Do something with data here
}
```

## Credits

This build's on @msmollin's original [webster](https://github.com/msmollin/webster) and currently exists as a separate project because it is full of Swift Package Manager -isms and I am not sure what the best way to create a PR is yet.

## See also

* https://github.com/aaronland/webster-cli
