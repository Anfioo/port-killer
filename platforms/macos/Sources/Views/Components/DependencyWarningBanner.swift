import SwiftUI

struct DependencyWarningBanner: View {
    @State private var isInstalling = false

    var body: some View {
        AlertBanner(
            icon: "exclamationmark.triangle.fill",
            title: "缺少依赖",
            message: "端口转发需要 kubectl"
        ) {
            if isInstalling {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button("安装") {
                    installDependencies()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func installDependencies() {
        isInstalling = true
        Task {
            _ = await DependencyChecker.shared.checkAndInstallMissing()
            await MainActor.run { isInstalling = false }
        }
    }
}
