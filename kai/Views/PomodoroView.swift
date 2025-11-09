import SwiftUI
import UserNotifications

struct PomodoroView: View {
    @ObservedObject var viewModel: PomodoroViewModel

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private var progress: Double {
        let totalTime = viewModel.currentSessionDuration
        guard totalTime > 0 else { return 0 }
        return 1 - (viewModel.remainingTime / totalTime)
    }

    private var accentColor: Color {
        viewModel.isRunning ? .blue : .gray
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header: Modo e Atividade
                VStack(spacing: 12) {
                    // Modo
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Modo")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Picker("Modo", selection: $viewModel.mode) {
                            Text("Timer Simples").tag(PomodoroViewModel.Mode.simple)
                            Text("Pomodoro").tag(PomodoroViewModel.Mode.pomodoro)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Categoria
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Atividade")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Picker("Atividade", selection: $viewModel.label) {
                            ForEach(PomodoroSession.ActivityLabel.allCases, id: \.self) { label in
                                Text(label.rawValue).tag(label)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Timer circular
                ZStack {
                    // Círculo de fundo
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 220, height: 220)

                    // Círculo de progresso
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: progress)

                    // Tempo
                    VStack(spacing: 6) {
                        Text(formatTime(viewModel.remainingTime))
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        if viewModel.isRunning {
                            Text("Em andamento")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                        }
                    }
                }
                .padding(.vertical, 12)

                // Indicadores Pomodoro
                if viewModel.mode == .pomodoro {
                    VStack(spacing: 10) {
                        Text("Progresso do Ciclo")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        HStack(spacing: 10) {
                            ForEach(0..<4, id: \.self) { index in
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(index < viewModel.completedPomodoros ?
                                                  Color.green : Color.gray.opacity(0.15))
                                            .frame(width: 36, height: 36)

                                        if index < viewModel.completedPomodoros {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("\(index + 1)")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Text("#\(index + 1)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }

                // Controles
                VStack(spacing: 10) {
                    // Botão principal
                    Button(action: {
                        withAnimation {
                            viewModel.isRunning ? viewModel.stop() : viewModel.start()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .semibold))

                            Text(viewModel.isRunning ? "Pausar" : "Iniciar")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: viewModel.isRunning ?
                                    [Color.orange, Color.red] :
                                    [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // Botões secundários
                    HStack(spacing: 10) {
                        Button(action: {
                            viewModel.reset()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Resetar")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color.gray.opacity(0.15))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            viewModel.stop()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Parar")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
}

#Preview {
    PomodoroView(viewModel: PomodoroViewModel())
}
