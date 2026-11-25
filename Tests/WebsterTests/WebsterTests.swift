import Testing
import Foundation
@testable import Webster

@Suite(.serialized)
struct WebsterTests {

    @MainActor
    @Test func defaults() {
        let w = Webster()
        #expect(w.width == 8.5)
        #expect(w.height == 11.0)
        #expect(w.marginTop == 1.0)
        #expect(w.marginBottom == 1.0)
        #expect(w.marginLeft == 1.0)
        #expect(w.marginRight == 1.0)
        #expect(w.bleed == 0.0)
        #expect(w.timeout == 60.0)
        #expect(w.imageTimeout == 20.0)
    }

    @MainActor
    @Test func createsMultipleInstances() {
        // Logging bootstrap must be safe to trigger more than once.
        _ = Webster()
        _ = Webster()
    }

    // WebKit navigation does not complete inside the test host process, so
    // rendering is verified end to end through the built `webster` executable.
    @Test func cliRendersLocalHTMLToPDF() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let html = dir.appendingPathComponent("in.html")
        let pdf = dir.appendingPathComponent("out.pdf")
        try "<html><body><h1>Hello</h1></body></html>".write(to: html, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = try websterExecutable()
        process.arguments = [html.path, pdf.path]
        try process.run()
        process.waitUntilExit()

        #expect(process.terminationStatus == 0)
        let data = try Data(contentsOf: pdf)
        #expect(data.starts(with: Data("%PDF".utf8)))
    }

    private func websterExecutable() throws -> URL {
        // swift test builds all products into <package>/.build/debug.
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let url = root.appendingPathComponent(".build/debug/webster")
        try #require(FileManager.default.isExecutableFile(atPath: url.path))
        return url
    }
}
