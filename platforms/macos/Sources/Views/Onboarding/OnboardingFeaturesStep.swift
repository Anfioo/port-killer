import SwiftUI

struct OnboardingFeaturesStep: View {
    private let features: [(icon: String, title: String, description: String, color: Color)] = [
        ("magnifyingglass", "端口扫描", "在一个地方查看所有监听端口", .blue),
        ("xmark.circle.fill", "快速结束", "一键终止进程", .red),
        ("star.fill", "收藏", "固定常用端口以便快速访问", .yellow),
        ("eye.fill", "关注端口", "端口变为活跃时收到通知", .purple),
        ("globe", "Cloudflare 隧道", "公开分享本地端口", .orange),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("你可以做什么")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 4)

            ForEach(features, id: \.title) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(feature.color)
                        .frame(width: 28, alignment: .center)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .fontWeight(.medium)
                        Text(feature.description)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
