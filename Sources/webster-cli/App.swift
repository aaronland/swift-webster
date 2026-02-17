import Foundation
import ArgumentParser

@main
struct LabelParser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "webster",
    subcommands: [Render.self, Version.self ],
    defaultSubcommand: Render.self,
  )
}
