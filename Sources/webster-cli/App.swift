import Foundation
import ArgumentParser

@available(macOS 13.0, *)
@main
struct LabelParser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "webster",
    subcommands: [Render.self, Version.self ],
    defaultSubcommand: Render.self,
  )
}
