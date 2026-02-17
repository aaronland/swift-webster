import Foundation
import ArgumentParser

@main
struct LabelParser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "webster",
    subcommands: [Print.self, Version.self ],
    defaultSubcommand: Print.self,
  )
}
