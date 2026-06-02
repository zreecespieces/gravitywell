import SwiftUI

struct TopListView: View {
    let title: String
    let items: [MonitoringTopItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            if items.isEmpty {
                Text("No data yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 8) {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()

                            Text(item.name)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer(minLength: 8)

                            Text(Formatters.compactInteger(item.count))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .font(.callout)
                    }
                }
            }
        }
    }
}

#Preview {
    TopListView(
        title: "Top Blocked Domains",
        items: [
            MonitoringTopItem(name: "doubleclick.net", count: 1200),
            MonitoringTopItem(name: "app-measurement.com", count: 840),
            MonitoringTopItem(name: "google-analytics.com", count: 512)
        ]
    )
    .padding()
}
