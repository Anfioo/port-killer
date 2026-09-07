import SwiftUI

struct OnboardingReadyStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)

            Text("一切就绪！")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("PortKiller 已准备就绪。\n在菜单栏中查找图标。")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            HStack(spacing: 24) {
                tipView(icon: "menubar.arrow.up.rectangle", text: "点击菜单栏图标\n快速访问")
                tipView(icon: "gearshape.fill", text: "访问设置\n进行更多自定义")
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(32)
    }

    private func tipView(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 140)
    }
}
