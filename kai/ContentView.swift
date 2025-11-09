import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var viewModel: PomodoroViewModel

    var body: some View {
        TabView {
            PomodoroView(viewModel: viewModel)
                .tabItem {
                    Label("Pomodoro", systemImage: "timer")
                }

            HistoryView(viewModel: viewModel)
                .tabItem {
                    Label("Histórico", systemImage: "clock.arrow.circlepath")
                }

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Configurações", systemImage: "gear")
                }
        }
        .onAppear {
            // Guarda a referência da janela quando a view aparecer
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                    AppDelegate.currentWindow = window
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PomodoroViewModel())
}
