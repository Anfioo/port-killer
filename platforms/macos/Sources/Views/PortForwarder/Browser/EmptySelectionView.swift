import SwiftUI

struct EmptySelectionView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("服务详情")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()

            VStack {
                Spacer()
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text("选择一个服务")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .background(Color.primary.opacity(0.02))
    }
}
