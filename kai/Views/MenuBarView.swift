import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var viewModel: PomodoroViewModel
    @Environment(\.openWindow) private var openWindow

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Timer Display
            VStack(spacing: 8) {
                Text(viewModel.label.rawValue)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(formatTime(viewModel.remainingTime))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(viewModel.mode == .pomodoro ? "Pomodoro" : "Timer Simples")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)

            Divider()

            // Indicadores Pomodoro
            if viewModel.mode == .pomodoro {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < viewModel.completedPomodoros ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.bottom, 4)
            }

            // Controles
            HStack(spacing: 8) {
                Button(action: {
                    viewModel.isRunning ? viewModel.stop() : viewModel.start()
                }) {
                    Label(viewModel.isRunning ? "Pausar" : "Iniciar",
                          systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            // Ações
            VStack(spacing: 4) {
                Button("Abrir Janela Principal") {
                    openWindow(id: "main")
                }

                Button("Sair") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 250)
    }
}
