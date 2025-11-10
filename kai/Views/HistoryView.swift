import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @State private var selectedGroupId: UUID?
    @State private var showingDeleteAlert = false
    @State private var groupToDelete: UUID?

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()

    // Formata TimeInterval em horas, minutos e segundos
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)min \(secs)s"
            } else {
                return "\(hours)h \(secs)s"
            }
        } else if minutes > 0 {
            return "\(minutes)min \(secs)s"
        } else {
            return "\(secs)s"
        }
    }

    // Busca o grupo atualizado sempre que renderizar
    private var selectedGroup: PomodoroGroup? {
        guard let id = selectedGroupId else { return nil }
        return viewModel.groupedSessions.first { $0.id == id }
    }

    var body: some View {
        NavigationView {
            List(selection: $selectedGroupId) {
                if viewModel.groupedSessions.isEmpty {
                    Text("Nenhuma sessão registrada ainda.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.groupedSessions) { group in
                        GroupRow(
                            group: group,
                            dateFormatter: dateFormatter,
                            formattedDuration: formatDuration(group.totalDuration)
                        )
                            .tag(group.id)
                            .contextMenu {
                                Button(role: .destructive) {
                                    groupToDelete = group.id
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Deletar", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Histórico")

            // Painel de detalhes
            if let group = selectedGroup {
                GroupDetailView(
                    group: group,
                    dateFormatter: dateFormatter,
                    onDelete: {
                        groupToDelete = group.id
                        showingDeleteAlert = true
                    }
                )
            } else {
                Text("Selecione um item para ver detalhes")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert("Deletar Sessão", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Deletar", role: .destructive) {
                if let id = groupToDelete {
                    viewModel.deleteGroup(id)
                    // Limpa a seleção se for o item selecionado
                    if selectedGroupId == id {
                        selectedGroupId = nil
                    }
                }
            }
        } message: {
            Text("Tem certeza que deseja deletar esta sessão? Esta ação não pode ser desfeita.")
        }
    }
}

struct GroupRow: View {
    let group: PomodoroGroup
    let dateFormatter: DateFormatter
    let formattedDuration: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(group.label.rawValue)
                    .font(.headline)

                Spacer()

                if group.isFullyCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if group.interruptedCount > 0 {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                }
            }

            HStack {
                Text(group.sessions.count == 1 ? "Timer Simples" : "Pomodoro (\(group.sessions.count) sessões)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if group.sessions.count > 1 {
                    Text("\(group.completedCount)/\(group.sessions.count) completadas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(dateFormatter.string(from: group.startTime))
                .font(.footnote)
                .foregroundColor(.gray)

            Text("Duração total: \(formattedDuration)")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct GroupDetailView: View {
    let group: PomodoroGroup
    let dateFormatter: DateFormatter
    let onDelete: () -> Void

    // Formata TimeInterval em horas, minutos e segundos
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)min \(secs)s"
            } else {
                return "\(hours)h \(secs)s"
            }
        } else if minutes > 0 {
            return "\(minutes)min \(secs)s"
        } else {
            return "\(secs)s"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.label.rawValue)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(group.sessions.count == 1 ? "Timer Simples" : "Ciclo Pomodoro")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help("Deletar sessão")
                }

                Divider()

                // Resumo
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resumo")
                        .font(.headline)

                    HStack {
                        Label("Início", systemImage: "clock")
                        Spacer()
                        Text(dateFormatter.string(from: group.startTime))
                    }

                    if let endTime = group.endTime {
                        HStack {
                            Label("Término", systemImage: "clock.fill")
                            Spacer()
                            Text(dateFormatter.string(from: endTime))
                        }
                    }

                    HStack {
                        Label("Duração total", systemImage: "timer")
                        Spacer()
                        Text(formatDuration(group.totalDuration))
                    }

                    HStack {
                        Label("Status", systemImage: "info.circle")
                        Spacer()
                        if group.isFullyCompleted {
                            Text("Completado")
                                .foregroundColor(.green)
                        } else {
                            Text("\(group.completedCount) de \(group.sessions.count) completadas")
                                .foregroundColor(.orange)
                        }
                    }

                    Divider()
                }

                // Sessões individuais
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sessões")
                        .font(.headline)

                    ForEach(Array(group.sessions.enumerated()), id: \.element.id) { index, session in
                        SessionDetailRow(
                            session: session,
                            index: index,
                            dateFormatter: dateFormatter,
                            formattedDuration: formatDuration(session.duration)
                        )
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SessionDetailRow: View {
    let session: PomodoroSession
    let index: Int
    let dateFormatter: DateFormatter
    let formattedDuration: String

    var sessionTypeLabel: String {
        if session.type == .simple {
            return "Timer"
        } else if let pos = session.cyclePosition {
            if pos % 2 == 1 {
                return "Pomodoro #\((pos + 1) / 2)"
            } else if pos == 8 {
                return "Pausa longa"
            } else {
                return "Pausa curta"
            }
        }
        return "Sessão #\(index + 1)"
    }

    var statusIcon: (name: String, color: Color) {
        if session.completed {
            return ("checkmark.circle.fill", .green)
        } else if session.duration > 0 {
            return ("pause.circle.fill", .orange)
        } else {
            return ("xmark.circle.fill", .red)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: statusIcon.name)
                    .foregroundColor(statusIcon.color)

                Text(sessionTypeLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(session.status.rawValue)
                    .font(.caption)
                    .foregroundColor(statusIcon.color)
            }

            HStack {
                Text(dateFormatter.string(from: session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Text(formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}
