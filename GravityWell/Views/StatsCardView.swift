import SwiftUI

struct StatsCardView: View {
    let snapshot: MonitoringSnapshot
    let isRefreshing: Bool
    let refreshAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.14), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: min(max(snapshot.percentBlocked / 100, 0), 1))
                        .stroke(
                            AngularGradient(
                                colors: [.cyan, .blue, .cyan],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text(Formatters.percent(snapshot.percentBlocked))
                        .font(.system(size: 19, weight: .semibold, design: .monospaced))
                }
                .frame(width: 76, height: 76)

                VStack(alignment: .leading, spacing: 6) {
                    StatRow(label: "Queries Today", value: Formatters.integer(snapshot.totalQueries))
                    StatRow(label: "Blocked Today", value: Formatters.integer(snapshot.blockedQueries))
                    StatRow(label: "Clients Seen", value: Formatters.integer(snapshot.clientsSeen))
                }
            }

            if !snapshot.queryActivity.isEmpty {
                QueryActivitySparkline(values: snapshot.queryActivity)
                    .frame(height: 34)
                    .padding(.top, 2)
                    .accessibilityLabel("Queries per minute for the last hour")
            }

            HStack(alignment: .bottom, spacing: 8) {
                Text("Last Updated: \(Formatters.time(snapshot.lastUpdated))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: refreshAction) {
                    if isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRefreshing)
                .help("Refresh stats")
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct QueryActivitySparkline: View {
    let values: [Int]

    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(values.max() ?? 0, 1)
            let points = values.enumerated().map { index, value in
                CGPoint(
                    x: xPosition(for: index, width: proxy.size.width),
                    y: proxy.size.height - CGFloat(value) / CGFloat(maxValue) * proxy.size.height
                )
            }

            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.cyan.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask(sparklineFill(points: points, size: proxy.size))

                sparklineStroke(points: points)
                    .stroke(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
            }
        }
    }

    private func xPosition(for index: Int, width: CGFloat) -> CGFloat {
        guard values.count > 1 else { return 0 }

        return CGFloat(index) / CGFloat(values.count - 1) * width
    }

    private func sparklineStroke(points: [CGPoint]) -> Path {
        Path { path in
            guard let firstPoint = points.first else { return }

            path.move(to: firstPoint)
            points.dropFirst().forEach { path.addLine(to: $0) }
        }
    }

    private func sparklineFill(points: [CGPoint], size: CGSize) -> Path {
        Path { path in
            guard let firstPoint = points.first, let lastPoint = points.last else { return }

            path.move(to: CGPoint(x: firstPoint.x, y: size.height))
            path.addLine(to: firstPoint)
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.addLine(to: CGPoint(x: lastPoint.x, y: size.height))
            path.closeSubpath()
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .monospacedDigit()
        }
        .font(.callout)
    }
}

#Preview {
    StatsCardView(
        snapshot: MonitoringSnapshot(
            providerName: "Pi-hole",
            status: .online,
            totalQueries: 12_483,
            blockedQueries: 2_341,
            percentBlocked: 18.7,
            clientsSeen: 9,
            topBlockedDomains: [],
            topClients: [],
            queryActivity: [3, 4, 4, 5, 8, 8, 6, 10, 13, 11, 8, 5],
            lastUpdated: Date()
        ),
        isRefreshing: false,
        refreshAction: {}
    )
    .padding()
}
