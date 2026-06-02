import SwiftUI
import AppKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var credentialDraft = ""
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var isTestingConnection = false

    var body: some View {
        @Bindable var appState = appState

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection("Pi-hole Connection") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Pi-hole URL", text: $appState.baseURLString)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.leading)
                            .cursor(.iBeam)
                            .frame(width: 420, alignment: .leading)

                        Text("Example: https://pi-hole.local")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        SecureField(
                            "Pi-hole password",
                            text: $credentialDraft,
                            prompt: Text(appState.hasStoredCredential ? "••••••••" : "Pi-hole password")
                        )
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.leading)
                            .cursor(.iBeam)
                            .frame(width: 420, alignment: .leading)

                        Text(appState.hasStoredCredential ? "Leave blank to keep the saved credential, or enter a new password to replace it." : "Use your Pi-hole web password or a Pi-hole application password.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button("Save Connection") {
                            saveConnection()
                        }
                        .keyboardShortcut(.defaultAction)

                        Button("Test Connection") {
                            testConnection()
                        }
                        .disabled(isTestingConnection)

                        Button("Remove Credential", role: .destructive) {
                            removeCredential()
                        }
                        .disabled(!appState.hasStoredCredential)
                    }

                    if isTestingConnection {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)

                            Text("Testing Pi-hole connection...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                    if let statusMessage {
                        FeedbackBadge(message: statusMessage, systemImage: "checkmark.circle.fill", color: .green)
                    }

                    if let errorMessage {
                        FeedbackBadge(message: errorMessage, systemImage: "exclamationmark.triangle.fill", color: .red)
                    }
                }

                SettingsSection("Polling") {
                    HStack {
                        Text("Poll interval")
                        Spacer()
                        Picker("Poll interval", selection: $appState.pollInterval) {
                            ForEach(PollInterval.allCases) { interval in
                                Text(interval.title).tag(interval)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }

                SettingsSection("Menu Bar") {
                    HStack {
                        Text("Display mode")
                        Spacer()
                        Picker("Display mode", selection: $appState.menuBarDisplayMode) {
                            ForEach(MenuBarDisplayMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }

                SettingsSection("Security") {
                    Toggle("Allow self-signed certificates", isOn: $appState.selfSignedCertificatesAllowed)

                    Text("Off by default. Enable only for Pi-hole instances you trust on your private network or Tailscale tailnet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                }

                SettingsSection("Launch") {
                    Toggle("Launch at login", isOn: $appState.launchAtLoginEnabled)

                    if let launchAtLoginErrorMessage = appState.launchAtLoginErrorMessage {
                        Text(launchAtLoginErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 560, height: 520)
    }

    private func saveConnection() {
        statusMessage = nil
        errorMessage = nil

        Task {
            do {
                try await appState.saveConnection(credentialDraft: credentialDraft)
                credentialDraft = ""
                statusMessage = "Connection settings saved."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func removeCredential() {
        statusMessage = nil
        errorMessage = nil

        do {
            try appState.deleteCredential()
            credentialDraft = ""
            statusMessage = "Credential removed from Keychain."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func testConnection() {
        statusMessage = nil
        errorMessage = nil
        isTestingConnection = true

        Task {
            do {
                let provider = try await appState.makeActiveMonitoringProvider(credentialOverride: credentialDraft)
                try await provider.authenticate()
                _ = try await provider.fetchSnapshot()

                await MainActor.run {
                    statusMessage = "Connection successful."
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isTestingConnection = false
                }
            }
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        } label: {
            Text(title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CursorModifier: ViewModifier {
    let cursor: NSCursor
    @State private var isCursorPushed = false

    func body(content: Content) -> some View {
        content
            .onHover { isHovering in
                if isHovering {
                    cursor.push()
                    isCursorPushed = true
                } else if isCursorPushed {
                    NSCursor.pop()
                    isCursorPushed = false
                }
            }
            .onDisappear {
                if isCursorPushed {
                    NSCursor.pop()
                    isCursorPushed = false
                }
            }
    }
}

private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        modifier(CursorModifier(cursor: cursor))
    }
}

private struct FeedbackBadge: View {
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
    SettingsView()
        .environment(AppState())
}
