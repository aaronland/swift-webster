import Testing
import Foundation
@testable import Webster

@Suite(.serialized)
struct WebsterTests {

    @Test func defaults() {
        let w = Webster()
        #expect(w.dpi == 72.0)
        #expect(w.width == 8.5)
        #expect(w.height == 11.0)
        #expect(w.margin == 1.0)
        #expect(w.bleed == 0.0)
    }

    @Test func createsMultipleInstances() {
        // Logging bootstrap must be safe to trigger more than once.
        _ = Webster()
        _ = Webster()
    }

    @Test @MainActor func rendersLocalHTMLToPDF() throws {
        let html = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".html")
        try "<html><body><h1>Hello</h1></body></html>".write(to: html, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: html) }

        var result: Result<Data, Error>?
        Webster().render(source: html) { result = $0 }

        let data = try #require(result).get()
        #expect(data.starts(with: Data("%PDF".utf8)))
    }
}
