import SwiftUI

struct ErrorStateView: View {
    let message: String

    var body: some View {
        Label {
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.callout)
        .foregroundStyle(.orange)
        .padding(10)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ErrorStateView(message: "Could not reach Pi-hole. Check that the URL is correct and your Mac can access the server.")
        .padding()
}
