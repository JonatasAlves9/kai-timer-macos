import Foundation

struct PomodoroGroup: Identifiable, Hashable {
    let id: UUID
    let label: PomodoroSession.ActivityLabel
    let startTime: Date
    var endTime: Date?
    var sessions: [PomodoroSession]

    var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var completedCount: Int {
        sessions.filter { $0.completed }.count
    }

    var interruptedCount: Int {
        sessions.filter { !$0.completed && $0.duration > 0 }.count
    }

    var isFullyCompleted: Bool {
        !sessions.isEmpty && sessions.allSatisfy { $0.completed }
    }

    // Hashable conformance
    static func == (lhs: PomodoroGroup, rhs: PomodoroGroup) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PomodoroSession: Identifiable, Codable, Hashable {
    enum SessionType: String, Codable {
        case pomodoro, simple
    }

    enum ActivityLabel: String, CaseIterable, Codable {
        case estudo = "Estudo"
        case trabalho = "Trabalho"
        case saude = "Saúde"
        case lazer = "Lazer"
        case leitura = "Leitura"
    }

    enum SessionStatus: String, Codable {
        case completed = "Completada"
        case interrupted = "Interrompida"
        case partial = "Parcial"
    }

    var id = UUID()
    let startTime: Date
    var endTime: Date?
    let duration: TimeInterval
    let type: SessionType
    let label: ActivityLabel
    let completed: Bool
    let groupId: UUID? // Para agrupar sessões de um mesmo ciclo Pomodoro
    let cyclePosition: Int? // Posição no ciclo (1-8: onde 1,3,5,7 = pomodoro e 2,4,6 = pausa curta, 8 = pausa longa)

    var status: SessionStatus {
        if completed {
            return .completed
        } else if duration > 0 {
            return .interrupted
        } else {
            return .partial
        }
    }
}
