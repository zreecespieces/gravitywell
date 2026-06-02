import SwiftUI

@main
struct GravityWellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(appDelegate.appState)
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Refresh") {
                    Task { await appDelegate.appState.refreshSnapshot() }
                }
                .keyboardShortcut("r")

                Divider()
            }
        }
    }
}
