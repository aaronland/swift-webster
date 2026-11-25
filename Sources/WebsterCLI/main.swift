import Foundation
import ArgumentParser
import Webster
import Logging

enum CLIError: Error {
    case invalidURL
}

struct WebsterCLI: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "webster")

    @Argument(help: "The URL you want to generate a PDF from.")
    var source: String

    @Argument(help: "The path where your PDF document will be created.")
    var destination: String

    @Option(help: "The DPI (dots per inch) of your output document.")
    var dpi: Double = 72.0

    @Option(help: "The width (in inches) of your document.")
    var width: Double = 8.5

    @Option(help: "The height (in inches) of your document.")
    var height: Double = 11.0

    @Option(help: "The margin (in inches) for each page in your document.")
    var margin: Double = 1.0

    @Option(help: "The bleed (in inches) for each page in your document.")
    var bleed: Double = 0.0

    @Flag(help: "Enable verbose (debug) logging.")
    var verbose: Bool = false

    func run() {

        var source_url: URL!
        var target_url: URL!

        switch newURL(url: source) {
        case .failure(let error):
            fatalError(error.localizedDescription)
        case .success(let u):
            source_url = u
        }

        switch newURL(url: destination) {
        case .failure(let error):
            fatalError(error.localizedDescription)
        case .success(let u):
            guard u.isFileURL else {
                fatalError("Destination must be a file path or file:// URI")
            }
            target_url = u
        }

        let w = Webster()

        w.dpi = dpi
        w.width = width
        w.height = height
        w.margin = margin
        w.bleed = bleed

        if verbose {
            w.setLogLevel(level: .debug)
        }

        func on_complete(result: Result<Data, Error>) -> Void {

            switch result {
            case .failure(let error):
                fatalError("Failed to generate PDF file, \(error.localizedDescription)")
            case .success(let data):

                do {
                    try data.write(to: target_url)
                } catch (let error) {
                    fatalError("Failed to save PDF file, \(error.localizedDescription)")
                }
            }
        }

        w.render(source: source_url, completionHandler: on_complete)
    }

    private func newURL(url: String) -> Result<URL, Error> {

        if let u = URL(string: url), u.scheme != nil {
            return .success(u)
        }

        // No scheme: treat as a filesystem path, resolved against the current directory.
        let path = (url as NSString).expandingTildeInPath
        return .success(URL(fileURLWithPath: path).standardizedFileURL)
    }
}

WebsterCLI.main()
