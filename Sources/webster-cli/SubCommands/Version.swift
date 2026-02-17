import ArgumentParser

let version = "0.0.5"

struct Version: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Print version number")
    
    func run() async throws {
        print(version)
    }
}
