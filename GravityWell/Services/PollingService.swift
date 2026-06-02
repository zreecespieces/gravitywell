import Foundation

@MainActor
final class PollingService {
    private var task: Task<Void, Never>?

    var isRunning: Bool {
        task != nil
    }

    func start(interval: TimeInterval, action: @escaping @MainActor @Sendable () async -> Void) {
        stop()

        task = Task { @MainActor in
            while !Task.isCancelled {
                await action()

                do {
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    break
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
