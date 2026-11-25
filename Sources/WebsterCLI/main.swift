import Foundation
import ArgumentParser
import Webster
import Logging

struct WebsterCLI: ParsableCommand {

    static let configuration = CommandConfiguration(commandName: "webster")

    @Argument(help: "The URL you want to generate a PDF from.")
    var source: String

    @Argument(help: "The path where your PDF document will be created.")
    var destination: String

    @Option(help: "The width (in inches) of your document.")
    var width: Double = 8.5

    @Option(help: "The height (in inches) of your document.")
    var height: Double = 11.0

    @Option(help: "The default margin (in inches) for all sides of each page. Overridden by --margin-SIDE.")
    var margin: Double = 1.0

    @Option(name: .customLong("margin-top"), help: "The top margin (in inches). Defaults to --margin.")
    var marginTop: Double?

    @Option(name: .customLong("margin-bottom"), help: "The bottom margin (in inches). Defaults to --margin.")
    var marginBottom: Double?

    @Option(name: .customLong("margin-left"), help: "The left margin (in inches). Defaults to --margin.")
    var marginLeft: Double?

    @Option(name: .customLong("margin-right"), help: "The right margin (in inches). Defaults to --margin.")
    var marginRight: Double?

    @Option(name: .customLong("margin-left-odd"), help: "The left margin (in inches) for odd pages. Overrides --margin-left.")
    var marginLeftOdd: Double?

    @Option(name: .customLong("margin-left-even"), help: "The left margin (in inches) for even pages. Overrides --margin-left.")
    var marginLeftEven: Double?

    @Option(name: .customLong("margin-right-odd"), help: "The right margin (in inches) for odd pages. Overrides --margin-right.")
    var marginRightOdd: Double?

    @Option(name: .customLong("margin-right-even"), help: "The right margin (in inches) for even pages. Overrides --margin-right.")
    var marginRightEven: Double?

    @Option(help: "The bleed (in inches) for each page in your document.")
    var bleed: Double = 0.0

    @Option(name: .customLong("image-timeout"), help: "The maximum time (in seconds) to wait for images to load.")
    var imageTimeout: Double = 20.0

    @Option(name: .customLong("page-timeout"), help: "The maximum time (in seconds) to wait for a page to load and print.")
    var pageTimeout: Double = 60.0

    @Flag(help: "Enable verbose (debug) logging.")
    var verbose: Bool = false

    @MainActor
    func render() {

        let source_url = newURL(url: source)
        let target_url = newURL(url: destination)

        guard target_url.isFileURL else {
            fatalError("Destination must be a file path or file:// URI")
        }

        let w = Webster()

        w.width = width
        w.height = height
        w.marginTop = marginTop ?? margin
        w.marginBottom = marginBottom ?? margin
        w.marginLeft = marginLeft ?? margin
        w.marginRight = marginRight ?? margin
        w.marginLeftOdd = marginLeftOdd
        w.marginLeftEven = marginLeftEven
        w.marginRightOdd = marginRightOdd
        w.marginRightEven = marginRightEven
        w.bleed = bleed
        w.imageTimeout = imageTimeout
        w.timeout = pageTimeout

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

    private func newURL(url: String) -> URL {

        if let u = URL(string: url), u.scheme != nil {
            return u
        }

        // No scheme: treat as a filesystem path, resolved against the current directory.
        let path = (url as NSString).expandingTildeInPath
        return URL(fileURLWithPath: path).standardizedFileURL
    }
}

// Top-level code in main.swift runs on the main actor, as WebKit requires.
let command = WebsterCLI.parseOrExit()
command.render()
