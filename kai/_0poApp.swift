//
//  _0poApp.swift
//  kai
//
//  Created by Jônatas Alves on 09/11/25.
//

import SwiftUI
import ServiceManagement

@main
struct _0poApp: App {
    @StateObject private var viewModel = PomodoroViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Passa o viewModel para o AppDelegate quando inicializar
        DispatchQueue.main.async {
            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                delegate.viewModel = PomodoroViewModel.shared
            }
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .frame(minWidth: 500, minHeight: 600)
                .environmentObject(viewModel)
                .onAppear {
                    PomodoroViewModel.shared = viewModel
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 700)
        .handlesExternalEvents(matching: Set(arrayLiteral: "main"))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Nova Janela") {
                    // Previne criação de múltiplas janelas
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(true)
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.isRunning ? "timer" : "timer.circle")
                if viewModel.isRunning {
                    Text(formatTime(viewModel.remainingTime))
                        .font(.system(.body, design: .monospaced))
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: PomodoroViewModel?
    private var observer: NSObjectProtocol?
    static var currentWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Escuta a notificação de timer completado
        observer = NotificationCenter.default.addObserver(
            forName: .timerCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleTimerCompleted()
        }

        // Observa quando janelas são criadas/fechadas
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )

        // Verifica se deve mostrar alerta de login startup
        checkFirstLaunch()
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window.level == .normal {
            AppDelegate.currentWindow = window
        }
    }

    private func checkFirstLaunch() {
        let hasAskedForLoginItem = UserDefaults.standard.bool(forKey: "hasAskedForLoginItem")

        if !hasAskedForLoginItem {
            // Aguarda um pouco para garantir que a janela está carregada
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showLoginItemAlert()
                UserDefaults.standard.set(true, forKey: "hasAskedForLoginItem")
            }
        }
    }

    private func showLoginItemAlert() {
        let alert = NSAlert()
        alert.messageText = "Iniciar KAI ao fazer login?"
        alert.informativeText = "Gostaria de iniciar o KAI automaticamente quando fizer login no Mac? O app ficará sempre disponível na barra de menu."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Sim, iniciar automaticamente")
        alert.addButton(withTitle: "Não, obrigado")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Usuário escolheu sim
            enableLoginItem()
        }
    }

    private func enableLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                UserDefaults.standard.set(true, forKey: "launchAtLogin")
            } catch {
                print("Falha ao registrar login item: \(error)")
            }
        } else {
            // Para versões antigas do macOS, usa método alternativo
            UserDefaults.standard.set(true, forKey: "launchAtLogin")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // App continua rodando mesmo sem janelas abertas
    }

    private func handleTimerCompleted() {
        // Força ativação do app
        NSApp.activate(ignoringOtherApps: true)

        // Abre ou traz a janela para frente
        openMainWindow()

        // Mostra alerta após um pequeno delay para garantir que a janela está aberta
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showCompletionAlert()
        }
    }

    private func openMainWindow() {
        // Primeiro, força o app para frente
        NSApp.activate(ignoringOtherApps: true)

        // Tenta usar a janela guardada primeiro
        if let window = AppDelegate.currentWindow {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return
        }

        // Se não tem janela guardada, procura por janelas normais
        let mainWindows = NSApplication.shared.windows.filter { window in
            window.level == .normal && !window.title.isEmpty
        }

        if let window = mainWindows.first {
            AppDelegate.currentWindow = window
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else {
            // Se não existe janela, abre uma nova via URL scheme
            if let url = URL(string: "KAI://main") {
                NSWorkspace.shared.open(url)
            }

            // Aguarda e tenta novamente
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let window = NSApplication.shared.windows.first(where: { $0.level == .normal && !$0.title.isEmpty }) {
                    AppDelegate.currentWindow = window
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
            }
        }
    }

    private func showCompletionAlert() {
        guard let viewModel = viewModel else { return }

        let alert = NSAlert()
        alert.messageText = "⏱️ Timer Concluído!"

        let nextPhase = getNextPhaseDescription(viewModel: viewModel)
        alert.informativeText = nextPhase

        alert.alertStyle = .informational
        alert.addButton(withTitle: "Iniciar Próximo")
        alert.addButton(withTitle: "Mais Tarde")

        // Faz o alerta aparecer na frente de tudo
        if let window = AppDelegate.currentWindow ?? NSApplication.shared.windows.first(where: { $0.isVisible && $0.level == .normal }) {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    // Usuário clicou "Iniciar Próximo"
                    Task { @MainActor in
                        viewModel.start()
                    }
                }
            }
        } else {
            // Fallback: mostra alerta modal independente
            DispatchQueue.main.async {
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    Task { @MainActor in
                        viewModel.start()
                    }
                }
            }
        }
    }

    private func getNextPhaseDescription(viewModel: PomodoroViewModel) -> String {
        if viewModel.mode == .simple {
            return "Sessão de timer concluída! Deseja iniciar outro timer?"
        }

        if viewModel.currentCyclePosition >= 8 {
            return "Ciclo Pomodoro completo! Deseja iniciar um novo ciclo?"
        }

        if viewModel.currentCyclePosition % 2 == 1 {
            return "Pomodoro concluído! Próximo: Pausa de \(Int(viewModel.remainingTime / 60)) minutos"
        } else {
            return "Pausa concluída! Próximo: Pomodoro de \(Int(viewModel.remainingTime / 60)) minutos"
        }
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
