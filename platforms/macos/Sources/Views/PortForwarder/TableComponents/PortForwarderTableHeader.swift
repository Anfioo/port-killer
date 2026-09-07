import SwiftUI

struct PortForwarderTableHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("状态")
                .frame(width: 80, alignment: .leading)
            Text("名称")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("服务")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("端口")
                .frame(width: 80, alignment: .leading)
            Text("操作")
                .frame(width: 80, alignment: .center)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
