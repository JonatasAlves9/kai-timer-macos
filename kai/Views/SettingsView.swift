//
//  SettingsView.swift
//  kai
//
//  Created by Jônatas Alves on 09/11/25.
//

import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @State private var showingClearAlert = false
    @State private var launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")

    private var totalSessions: Int {
        viewModel.sessions.count
    }

    private var completedSessions: Int {
        viewModel.sessions.filter { $0.completed }.count
    }

    private var totalTime: TimeInterval {
        viewModel.sessions.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)

                    Text("KAI")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Configurações")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Estatísticas
                VStack(alignment: .leading, spacing: 12) {
                    Label("Estatísticas", systemImage: "chart.bar.fill")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        StatCard(
                            icon: "checkmark.circle.fill",
                            color: .green,
                            value: "\(completedSessions)",
                            label: "Completadas"
                        )

                        StatCard(
                            icon: "clock.fill",
                            color: .blue,
                            value: "\(totalSessions)",
                            label: "Total Sessões"
                        )

                        StatCard(
                            icon: "timer",
                            color: Color(red: 1.0, green: 0.6, blue: 0.4),
                            value: "\(Int(totalTime / 3600))h",
                            label: "Tempo Total"
                        )
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Notificações
                VStack(alignment: .leading, spacing: 12) {
                    Label("Notificações", systemImage: "bell.fill")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Abrir janela automaticamente")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Text("A janela abre quando o timer termina")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.autoOpenWindow)
                                .labelsHidden()
                                .tint(Color(red: 1.0, green: 0.6, blue: 0.4))
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Geral
                VStack(alignment: .leading, spacing: 12) {
                    Label("Geral", systemImage: "gear")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Iniciar ao fazer login")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Text("Inicia automaticamente quando você ligar o Mac")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $launchAtLogin)
                                .labelsHidden()
                                .tint(Color(red: 1.0, green: 0.6, blue: 0.4))
                                .onChange(of: launchAtLogin) { newValue in
                                    toggleLaunchAtLogin(enabled: newValue)
                                }
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Aparência
                VStack(alignment: .leading, spacing: 12) {
                    Label("Aparência", systemImage: "paintbrush.fill")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(spacing: 8) {
                        InfoRow(
                            icon: "circle.fill",
                            iconColor: .blue,
                            title: "Tema",
                            value: "Sistema"
                        )

                        Divider()

                        InfoRow(
                            icon: "textformat.size",
                            iconColor: .purple,
                            title: "Tamanho da Fonte",
                            value: "Padrão"
                        )
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Dados e Histórico
                VStack(alignment: .leading, spacing: 12) {
                    Label("Dados e Histórico", systemImage: "externaldrive.fill")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(spacing: 8) {
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Limpar Histórico")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)

                                    Text("Remove todas as sessões registradas")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Sobre
                VStack(alignment: .leading, spacing: 12) {
                    Label("Sobre", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(spacing: 8) {
                        InfoRow(
                            icon: "app.fill",
                            iconColor: .blue,
                            title: "Versão",
                            value: "1.0.0"
                        )

                        Divider()

                        InfoRow(
                            icon: "hammer.fill",
                            iconColor: Color(red: 1.0, green: 0.6, blue: 0.4),
                            title: "Build",
                            value: "2025.1"
                        )
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                VStack(spacing: 4) {
                    Text("KAI - Pomodoro Timer")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Versão 1.0.0")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.bottom, 20)
            }
            .padding(20)
        }
        .alert("Limpar Histórico", isPresented: $showingClearAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Limpar", role: .destructive) {
                viewModel.clearOldSessions()
            }
        } message: {
            Text("Tem certeza que deseja apagar todo o histórico? Esta ação não pode ser desfeita.")
        }
        .onAppear {
            // Sincroniza o estado ao aparecer
            launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }

    private func toggleLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
            } catch {
                print("Falha ao alterar login item: \(error)")
                // Reverte o toggle se falhar
                launchAtLogin = !enabled
            }
        } else {
            // Para versões antigas do macOS
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        }
    }
}

struct StatCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
