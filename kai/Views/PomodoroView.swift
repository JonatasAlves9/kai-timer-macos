import SwiftUI
import UserNotifications

struct PomodoroView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @State private var showingTimeCustomizer = false

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    private var timeFontSize: CGFloat {
        let totalSeconds = Int(viewModel.remainingTime)
        let hours = totalSeconds / 3600
        // Reduz o tamanho da fonte quando há horas para caber no círculo
        return hours > 0 ? 44 : 52
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
        VStack(spacing: 0) {
            // Tabs de modo - centralizado no topo
            Picker("", selection: $viewModel.mode) {
                Text("Pomodoro").tag(PomodoroViewModel.Mode.pomodoro)
                Text("Timer Simples").tag(PomodoroViewModel.Mode.simple)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 80)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Seletor de Atividade
                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Picker("", selection: $viewModel.label) {
                            ForEach(PomodoroSession.ActivityLabel.allCases, id: \.self) { label in
                                Text(label.rawValue).tag(label)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
                    
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
                                .font(.system(size: timeFontSize, weight: .bold, design: .rounded))
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
                    
                    // Controle de tempo para Timer Simples
                    if viewModel.mode == .simple && !viewModel.isRunning {
                        VStack(spacing: 12) {
                            Text("Duração do Timer")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            // Presets rápidos
                            HStack(spacing: 6) {
                                ForEach([
                                    ("5m", 0, 5, 0),
                                    ("10m", 0, 10, 0),
                                    ("15m", 0, 15, 0),
                                    ("25m", 0, 25, 0),
                                    ("30m", 0, 30, 0),
                                    ("1h", 1, 0, 0)
                                ], id: \.0) { preset in
                                    Button(action: {
                                        viewModel.simpleTimerHours = preset.1
                                        viewModel.simpleTimerMinutes = preset.2
                                        viewModel.simpleTimerSeconds = preset.3
                                    }) {
                                        Text(preset.0)
                                            .font(.caption)
                                            .fontWeight(
                                                viewModel.simpleTimerHours == preset.1 &&
                                                viewModel.simpleTimerMinutes == preset.2 &&
                                                viewModel.simpleTimerSeconds == preset.3 ? .bold : .regular
                                            )
                                            .foregroundColor(
                                                viewModel.simpleTimerHours == preset.1 &&
                                                viewModel.simpleTimerMinutes == preset.2 &&
                                                viewModel.simpleTimerSeconds == preset.3 ? .white : .primary
                                            )
                                            .frame(minWidth: 36, minHeight: 28)
                                            .padding(.horizontal, 8)
                                            .background(
                                                viewModel.simpleTimerHours == preset.1 &&
                                                viewModel.simpleTimerMinutes == preset.2 &&
                                                viewModel.simpleTimerSeconds == preset.3 ?
                                                Color.blue : Color.gray.opacity(0.15)
                                            )
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // Botão para abrir personalização
                            Button(action: {
                                showingTimeCustomizer = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 12))
                                    Text("Personalizar tempo")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
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
        .sheet(isPresented: $showingTimeCustomizer) {
            TimeCustomizerSheet(viewModel: viewModel, isPresented: $showingTimeCustomizer)
        }
    }
}

// MARK: - Time Customizer Sheet
struct TimeCustomizerSheet: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Personalizar Tempo")
                    .font(.headline)

                Spacer()

                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top)

            Divider()

            // Controles de Horas, Minutos e Segundos
            HStack(spacing: 20) {
                // Horas
                VStack(spacing: 8) {
                    Button(action: {
                        if viewModel.simpleTimerHours < 23 {
                            viewModel.simpleTimerHours += 1
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(viewModel.simpleTimerHours < 23 ? .blue : .gray.opacity(0.3))
                            .frame(height: 24)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.simpleTimerHours >= 23)

                    VStack(spacing: 2) {
                        Text("\(String(format: "%02d", viewModel.simpleTimerHours))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        Text("horas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(minWidth: 80)

                    Button(action: {
                        if viewModel.simpleTimerHours > 0 {
                            viewModel.simpleTimerHours -= 1
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(viewModel.simpleTimerHours > 0 ? .blue : .gray.opacity(0.3))
                            .frame(height: 24)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.simpleTimerHours <= 0)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Text(":")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.secondary)

                // Minutos
                VStack(spacing: 8) {
                    Button(action: {
                        if viewModel.simpleTimerMinutes < 59 {
                            viewModel.simpleTimerMinutes += 1
                        } else {
                            viewModel.simpleTimerMinutes = 0
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(height: 24)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 2) {
                        Text("\(String(format: "%02d", viewModel.simpleTimerMinutes))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        Text("minutos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(minWidth: 80)

                    Button(action: {
                        if viewModel.simpleTimerMinutes > 0 {
                            viewModel.simpleTimerMinutes -= 1
                        } else {
                            viewModel.simpleTimerMinutes = 59
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(height: 24)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Text(":")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.secondary)

                // Segundos
                VStack(spacing: 8) {
                    Button(action: {
                        if viewModel.simpleTimerSeconds < 59 {
                            viewModel.simpleTimerSeconds += 1
                        } else {
                            viewModel.simpleTimerSeconds = 0
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(height: 24)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 2) {
                        Text("\(String(format: "%02d", viewModel.simpleTimerSeconds))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        Text("segundos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(minWidth: 80)

                    Button(action: {
                        if viewModel.simpleTimerSeconds > 0 {
                            viewModel.simpleTimerSeconds -= 1
                        } else {
                            viewModel.simpleTimerSeconds = 59
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(height: 24)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()

            // Botão confirmar
            Button(action: {
                isPresented = false
            }) {
                Text("Confirmar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 450, height: 350)
    }
}
