import AppKit
import SwiftUI

struct MenuBarStatusLabel: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 4) {
            Image("AppIcon")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.primary)
                .frame(width: 18, height: 18)

            if appState.menuBarDisplayMode != .iconOnly {
                Text(appState.menuBarStatusText())
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
            }
        }
        .task {
            appState.startPollingIfConfigured()
        }
    }
}

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        DashboardPopoverView()
    }
}

#Preview {
    MenuBarView()
        .environment(AppState())
}
