import AppKit
import SwiftUI

struct DashboardPopoverView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings
    let openSettingsAction: (() -> Void)?

    init(openSettingsAction: (() -> Void)? = nil) {
        self.openSettingsAction = openSettingsAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if !appState.isConfigured {
                setupState
            } else {
                if let errorMessage = appState.errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                if let snapshot = appState.snapshot {
                    StatsCardView(
                        snapshot: snapshot,
                        isRefreshing: appState.isRefreshing,
                        refreshAction: {
                            Task { await appState.refreshSnapshot() }
                        }
                    )

                    TopListView(title: "Top Blocked Domains", items: snapshot.topBlockedDomains)

                    TopListView(title: "Top Clients", items: snapshot.topClients)
                } else if appState.isRefreshing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)

                        Text("Loading Pi-hole stats...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text("No stats loaded yet. Refresh to fetch the latest Pi-hole snapshot.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                controls

                if let controlFeedback = appState.controlFeedback {
                    controlFeedbackBadge(controlFeedback)
                }
            }

            footer
        }
        .padding(18)
        .frame(width: 380)
        .background(GravityWellPopoverBackground())
        .preferredColorScheme(.dark)
        .task {
            appState.startPollingIfConfigured()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            GravityWellHeaderLogo()

            Text("GravityWell")
                .font(.title2.weight(.semibold))

            Spacer()

            if appState.isConfigured {
                Button("Open Dashboard") {
                    appState.openDashboard()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
    }

    private var setupState: some View {
        Text("Enter your Pi-hole URL and API credential in Settings to start monitoring.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(blockingControlTitle, systemImage: blockingControlImage)
                        .font(.headline)
                        .foregroundStyle(blockingControlColor)

                    Text(blockingControlSubtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer()

                if appState.displayStatus == .blockingDisabled {
                    Button("Resume") {
                        Task { await appState.performControl(.enableBlocking) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(appState.isControlInFlight)
                } else {
                    Menu {
                        Button("Pause for 5 Minutes") {
                            Task { await appState.performControl(.disableBlocking(seconds: 300)) }
                        }

                        Button("Pause for 30 Minutes") {
                            Task { await appState.performControl(.disableBlocking(seconds: 1_800)) }
                        }

                        Button("Pause for 1 Hour") {
                            Task { await appState.performControl(.disableBlocking(seconds: 3_600)) }
                        }
                    } label: {
                        Text(Image(systemName: "pause.circle")) + Text("  Pause")
                    }
                    .menuStyle(.button)
                    .disabled(appState.isControlInFlight || appState.displayStatus != .online)
                }
            }
        }
    }

    private var blockingControlTitle: String {
        switch appState.displayStatus {
        case .blockingDisabled:
            "Blocking Paused"
        case .online:
            "Blocking Active"
        case .offline, .authenticationFailed, .tlsError, .apiError, .unknownError:
            "Blocking Status Unknown"
        }
    }

    private var blockingControlImage: String {
        switch appState.displayStatus {
        case .blockingDisabled:
            "pause.circle.fill"
        case .online:
            "checkmark.circle.fill"
        case .offline, .authenticationFailed, .tlsError, .apiError, .unknownError:
            "exclamationmark.circle.fill"
        }
    }

    private var blockingControlColor: Color {
        switch appState.displayStatus {
        case .blockingDisabled:
            .red
        case .online:
            .green
        case .offline, .authenticationFailed, .tlsError, .apiError, .unknownError:
            .orange
        }
    }

    private var blockingControlSubtitle: String {
        if appState.displayStatus == .blockingDisabled, let disabledUntil = appState.blockingDisabledUntil {
            return "Disabled until \(Formatters.time(disabledUntil))"
        }

        if appState.displayStatus != .online {
            return "Unable to confirm DNS filtering status"
        }

        return "DNS filtering is protecting this network"
    }

    private var footer: some View {
        HStack {
            Button("Settings...") {
                if let openSettingsAction {
                    openSettingsAction()
                } else {
                    openSettings()
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }

    @ViewBuilder
    private func controlFeedbackBadge(_ feedback: MonitoringControlFeedback) -> some View {
        switch feedback {
        case .blockingDisabled:
            EmptyView()
        case .blockingEnabled:
            EmptyView()
        case .failed(let message):
            PopoverFeedbackBadge(
                message: message,
                systemImage: "exclamationmark.triangle.fill",
                color: .orange
            )
        }
    }
}

private struct GravityWellHeaderLogo: View {
    var body: some View {
        if let image = Self.image {
            Image(nsImage: image)
                .resizable()
                .renderingMode(.original)
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 28)
                .accessibilityHidden(true)
        } else {
            Image(systemName: "circle.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 28)
                .accessibilityHidden(true)
        }
    }

    private static var image: NSImage? {
        if let url = Bundle.main.url(forResource: "gravity-well", withExtension: "svg") {
            return NSImage(contentsOf: url)
        }

        if let image = NSImage(named: "gravity-well") {
            return image
        }

        if let url = Bundle.main.url(forResource: "AppIcon1024-White", withExtension: "png") {
            return NSImage(contentsOf: url)
        }

        return NSImage(named: "AppIcon1024-White")
    }
}

private struct GravityWellPopoverBackground: View {
    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    Color(white: 0.18).opacity(0.72),
                    Color(white: 0.07).opacity(0.92),
                    .black
                ],
                center: .center,
                startRadius: 18,
                endRadius: 330
            )

            RadialGradient(
                colors: [
                    Color.cyan.opacity(0.18),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 260
            )
        }
    }
}

private struct PopoverFeedbackBadge: View {
    let message: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(message, systemImage: systemImage)
            .font(.callout)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    DashboardPopoverView()
        .environment(AppState())
}
