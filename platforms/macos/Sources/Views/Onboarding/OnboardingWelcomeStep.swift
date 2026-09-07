import SwiftUI

struct OnboardingWelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "network")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)

            Text("欢迎使用 PortKiller")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("查找并结束任意端口上的进程。\n轻松管理你的开发服务器。")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()
        }
        .padding(32)
    }
}
