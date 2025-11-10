import Foundation
import Combine
import UserNotifications
import SwiftUI
import AppKit

extension Notification.Name {
    static let timerCompleted = Notification.Name("timerCompleted")
}

@MainActor
final class PomodoroViewModel: ObservableObject {
    static var shared: PomodoroViewModel!

    enum Mode: String, CaseIterable, Identifiable {
        case simple = "Timer Simples"
        case pomodoro = "Pomodoro"
        var id: String { rawValue }
    }

    // MARK: - Public States
    @Published var mode: Mode = .pomodoro {
        didSet {
            // Quando muda de modo, atualiza o tempo se não estiver rodando
            if !isRunning {
                updateTimeForCurrentMode()
            }
        }
    }
    @Published var label: PomodoroSession.ActivityLabel = .estudo
    @Published var remainingTime: TimeInterval = 25 * 1
    @Published var isRunning = false
    @Published var completedPomodoros = 0
    @Published var isCycleCompleted = false
    @Published var sessions: [PomodoroSession] = [] // Histórico
    @Published var autoOpenWindow = true // Abre janela automaticamente ao completar

    // MARK: - Private State
    private var timer: Timer?
    private var currentCycle = 1
    private var sessionStartTime: Date?
    private var currentGroupId: UUID?
    var currentCyclePosition = 1 // Tornado público para acessar no AppDelegate
    private var initialTime: TimeInterval = 25 * 1 // Tempo inicial da sessão atual

    // MARK: - Timer durations (em minutos, configuráveis)
    @Published var pomodoroDuration: Int = 25 {
        didSet {
            saveTimerDurations()
            updateRemainingTimeIfNeeded()
        }
    }
    @Published var shortBreakDuration: Int = 5 {
        didSet {
            saveTimerDurations()
            updateRemainingTimeIfNeeded()
        }
    }
    @Published var longBreakDuration: Int = 15 {
        didSet {
            saveTimerDurations()
            updateRemainingTimeIfNeeded()
        }
    }
    // Timer simples com horas, minutos e segundos
    @Published var simpleTimerHours: Int = 0 {
        didSet {
            saveTimerDurations()
            updateRemainingTimeIfNeeded()
        }
    }
    @Published var simpleTimerMinutes: Int = 25 {
        didSet {
            saveTimerDurations()
            updateRemainingTimeIfNeeded()
        }
    }
    @Published var simpleTimerSeconds: Int = 0 {
        didSet {
            saveTimerDurations()
            updateRemainingTimeIfNeeded()
        }
    }

    // Conversão para segundos (usado internamente)
    private var pomodoroDurationSeconds: TimeInterval {
        TimeInterval(pomodoroDuration * 60)
    }
    private var shortBreakDurationSeconds: TimeInterval {
        TimeInterval(shortBreakDuration * 60)
    }
    private var longBreakDurationSeconds: TimeInterval {
        TimeInterval(longBreakDuration * 60)
    }
    private var simpleTimerDurationSeconds: TimeInterval {
        TimeInterval((simpleTimerHours * 3600) + (simpleTimerMinutes * 60) + simpleTimerSeconds)
    }

    // MARK: - Computed Properties
    var currentSessionDuration: TimeInterval {
        return initialTime
    }

    // Atualiza o tempo baseado no modo atual
    private func updateTimeForCurrentMode() {
        if mode == .pomodoro {
            remainingTime = pomodoroDurationSeconds
            initialTime = pomodoroDurationSeconds
            // Reseta o ciclo ao mudar para pomodoro
            currentCyclePosition = 1
            completedPomodoros = 0
            currentGroupId = nil
        } else {
            remainingTime = simpleTimerDurationSeconds
            initialTime = simpleTimerDurationSeconds
        }
    }

    // Atualiza o remainingTime quando as configurações mudam (apenas se não estiver rodando)
    private func updateRemainingTimeIfNeeded() {
        guard !isRunning else { return }

        if mode == .pomodoro {
            // Determina qual deveria ser o tempo baseado na posição do ciclo
            if currentCyclePosition >= 8 {
                // Após pausa longa, volta para pomodoro
                remainingTime = pomodoroDurationSeconds
                initialTime = pomodoroDurationSeconds
            } else if currentCyclePosition % 2 == 1 {
                // Posições ímpares (1, 3, 5, 7) = trabalho
                remainingTime = pomodoroDurationSeconds
                initialTime = pomodoroDurationSeconds
            } else if (completedPomodoros % 4 == 0 && completedPomodoros > 0) || currentCyclePosition == 8 {
                // Pausa longa (após 4 pomodoros)
                remainingTime = longBreakDurationSeconds
                initialTime = longBreakDurationSeconds
            } else {
                // Pausa curta
                remainingTime = shortBreakDurationSeconds
                initialTime = shortBreakDurationSeconds
            }
        } else {
            // Timer simples - atualiza para o tempo configurado
            remainingTime = simpleTimerDurationSeconds
            initialTime = simpleTimerDurationSeconds
        }
    }

    var groupedSessions: [PomodoroGroup] {
        var groups: [UUID: PomodoroGroup] = [:]
        var simpleSessions: [PomodoroSession] = []

        for session in sessions {
            if session.type == .pomodoro, let groupId = session.groupId {
                if var group = groups[groupId] {
                    group.sessions.append(session)
                    group.endTime = session.endTime
                    groups[groupId] = group
                } else {
                    groups[groupId] = PomodoroGroup(
                        id: groupId,
                        label: session.label,
                        startTime: session.startTime,
                        endTime: session.endTime,
                        sessions: [session]
                    )
                }
            } else if session.type == .simple {
                simpleSessions.append(session)
            }
        }

        // Converter grupos em array e adicionar timers simples como grupos individuais
        var result = Array(groups.values)
        for simpleSession in simpleSessions {
            result.append(PomodoroGroup(
                id: simpleSession.id,
                label: simpleSession.label,
                startTime: simpleSession.startTime,
                endTime: simpleSession.endTime,
                sessions: [simpleSession]
            ))
        }

        return result.sorted { $0.startTime > $1.startTime }
    }

    // MARK: - Init
    init() {
        loadSessions()
        loadTimerDurations()
        // Define o tempo inicial baseado nas configurações carregadas e modo atual
        if mode == .pomodoro {
            remainingTime = pomodoroDurationSeconds
            initialTime = pomodoroDurationSeconds
        } else {
            remainingTime = simpleTimerDurationSeconds
            initialTime = simpleTimerDurationSeconds
        }
    }

    // Função para limpar sessões antigas incompatíveis
    func clearOldSessions() {
        sessions.removeAll()
        saveSessions()
    }

    // Função para deletar um grupo específico
    func deleteGroup(_ groupId: UUID) {
        sessions.removeAll { session in
            if let gid = session.groupId {
                return gid == groupId
            }
            return session.id == groupId
        }
        saveSessions()
    }

    // MARK: - Core Logic
    func start() {
        guard !isRunning else { return }
        isRunning = true
        isCycleCompleted = false
        sessionStartTime = Date()

        // Gera novo groupId ao iniciar um novo ciclo Pomodoro
        if mode == .pomodoro && currentGroupId == nil {
            currentGroupId = UUID()
            currentCyclePosition = 1
        }

        if remainingTime <= 0 {
            remainingTime = (mode == .pomodoro) ? pomodoroDurationSeconds : simpleTimerDurationSeconds
        }

        // Guarda o tempo inicial para cálculo de progresso
        initialTime = remainingTime

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                cycleCompleted()
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        stopTimer()

        // salva sessão mesmo incompleta
        recordSession(completed: false)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        stop()
        remainingTime = (mode == .pomodoro) ? pomodoroDurationSeconds : simpleTimerDurationSeconds
        initialTime = remainingTime
        currentCycle = 1
        completedPomodoros = 0
        isCycleCompleted = false
        currentGroupId = nil
        currentCyclePosition = 1
    }

    private func cycleCompleted() {
        stopTimer() // Para o timer sem salvar
        isCycleCompleted = true
        recordSession(completed: true) // Salva apenas uma vez, como completa

        if mode == .pomodoro {
            // Se acabou de completar a pausa longa (posição 8), reseta para novo ciclo
            if currentCyclePosition >= 8 {
                currentGroupId = nil
                currentCyclePosition = 0
                completedPomodoros = 0
                remainingTime = pomodoroDurationSeconds
            } else {
                // Incrementa posição no ciclo
                currentCyclePosition += 1

                // Conta pomodoros completados (apenas nas posições ímpares = trabalho)
                if currentCyclePosition % 2 == 0 {
                    completedPomodoros += 1
                }

                // alterna entre pomodoro e pausas
                if completedPomodoros % 4 == 0 && completedPomodoros > 0 {
                    remainingTime = longBreakDurationSeconds
                } else if currentCyclePosition % 2 == 0 {
                    remainingTime = shortBreakDurationSeconds
                } else {
                    remainingTime = pomodoroDurationSeconds
                }
            }

            initialTime = remainingTime
            currentCycle += 1
        } else {
            remainingTime = 0
            initialTime = 0
            currentGroupId = nil
        }

        notifyCompletion()
        bringAppToFront()

        // Notifica para abrir a janela principal se configurado
        if autoOpenWindow {
            NotificationCenter.default.post(name: .timerCompleted, object: nil)
        }
    }

    // MARK: - Session recording
    private func recordSession(completed: Bool) {
        guard let start = sessionStartTime else { return }

        let elapsed = (mode == .pomodoro ? pomodoroDurationSeconds : simpleTimerDurationSeconds) - remainingTime
        let session = PomodoroSession(
            startTime: start,
            endTime: Date(),
            duration: elapsed,
            type: mode == .pomodoro ? .pomodoro : .simple,
            label: label,
            completed: completed,
            groupId: mode == .pomodoro ? currentGroupId : nil,
            cyclePosition: mode == .pomodoro ? currentCyclePosition : nil
        )

        sessions.insert(session, at: 0)
        saveSessions()

        sessionStartTime = nil
    }

    // MARK: - Notifications & Focus
    private func notifyCompletion() {
        let content = UNMutableNotificationContent()
        content.title = "⏱ Sessão concluída"
        content.body = "A sessão de \(label.rawValue) terminou!"
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func bringAppToFront() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // MARK: - Persistência
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: "PomodoroSessions")
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "PomodoroSessions"),
           let decoded = try? JSONDecoder().decode([PomodoroSession].self, from: data) {
            sessions = decoded
        }
    }

    private func saveTimerDurations() {
        UserDefaults.standard.set(pomodoroDuration, forKey: "PomodoroDuration")
        UserDefaults.standard.set(shortBreakDuration, forKey: "ShortBreakDuration")
        UserDefaults.standard.set(longBreakDuration, forKey: "LongBreakDuration")
        UserDefaults.standard.set(simpleTimerHours, forKey: "SimpleTimerHours")
        UserDefaults.standard.set(simpleTimerMinutes, forKey: "SimpleTimerMinutes")
        UserDefaults.standard.set(simpleTimerSeconds, forKey: "SimpleTimerSeconds")
    }

    private func loadTimerDurations() {
        if UserDefaults.standard.object(forKey: "PomodoroDuration") != nil {
            pomodoroDuration = UserDefaults.standard.integer(forKey: "PomodoroDuration")
        }
        if UserDefaults.standard.object(forKey: "ShortBreakDuration") != nil {
            shortBreakDuration = UserDefaults.standard.integer(forKey: "ShortBreakDuration")
        }
        if UserDefaults.standard.object(forKey: "LongBreakDuration") != nil {
            longBreakDuration = UserDefaults.standard.integer(forKey: "LongBreakDuration")
        }
        if UserDefaults.standard.object(forKey: "SimpleTimerHours") != nil {
            simpleTimerHours = UserDefaults.standard.integer(forKey: "SimpleTimerHours")
        }
        if UserDefaults.standard.object(forKey: "SimpleTimerMinutes") != nil {
            simpleTimerMinutes = UserDefaults.standard.integer(forKey: "SimpleTimerMinutes")
        }
        if UserDefaults.standard.object(forKey: "SimpleTimerSeconds") != nil {
            simpleTimerSeconds = UserDefaults.standard.integer(forKey: "SimpleTimerSeconds")
        }
    }
}
