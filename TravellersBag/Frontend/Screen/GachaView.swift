//
//  GachaView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/28.
//

import SwiftUI
import SwiftData

struct GachaView: View {
    @Environment(\.modelContext) private var operation
    @StateObject private var viewModel: GachaViewModel = .init()
    @State private var gachaItems: [GachaItem] = []
    @Query private var accounts: [HoyoAccount]
    @State private var selectedAccount: HoyoAccount? = nil
    @State private var showWaitingSheet: Bool = false
    
    var body: some View {
        if accounts.isEmpty {
            ContentUnavailableView("gacha.blocked.needAccount", systemImage: "hand.raised")
        } else {
            NavigationStack {
                if viewModel.uiState.gachaRecords.count > 0 {
                    ScrollView {
                        LazyVStack {
                            Text(viewModel.uiState.gachaRecords.count.description)
                        }
                    }
                } else {
                    Image(systemName: "tray")
                        .resizable().foregroundStyle(.accent)
                        .frame(width: 72, height: 72)
                    Text("gacha.empty.title").font(.title.bold())
                    Button(
                        action: {
                            startSync()
                        },
                        label: {
                            Label("gacha.action.sync", systemImage: "square.and.arrow.down.fill").padding()
                        }
                    ).buttonStyle(.borderedProminent)
                }
            }
            .onAppear {
                selectedAccount = accounts.first!
                viewModel.queryRecords(accounts.first!, context: operation)
            }
            .toolbar {
                ToolbarItem {
                    Button(
                        action: { startSync() },
                        label: { Image(systemName: "square.and.arrow.down.fill").help("gacha.action.sync") }
                    )
                }
            }
            .sheet(isPresented: $showWaitingSheet, content: { WaitingSheet })
            .alert(
                viewModel.uiState.alertMate.title,
                isPresented: $viewModel.uiState.alertMate.showIt,
                actions: {},
                message: { Text(viewModel.uiState.alertMate.msg) }
            )
        }
    }
    
    private func startSync() {
        showWaitingSheet = true
        Task.detached {
            await viewModel.updateDataFromCloud(
                selectedAccount!,
                originalList: viewModel.uiState.gachaRecords,
                onWrite: { item in
                    await MainActor.run {
                        operation.insert(item)
                    }
                },
                onFailed: {
                    DispatchQueue.main.async {
                        self.showWaitingSheet = false
                    }
                },
                onFinished: { msg, acc in
                    await MainActor.run {
                        showWaitingSheet = false
                        viewModel.uiState.alertMate.showAlert(msg: msg)
                        viewModel.queryRecords(acc, context: operation)
                    }
                }
            )
        }
    }
    
    private var WaitingSheet: some View {
        return NavigationStack {
            Text("gacha.def.title").font(.title.bold())
            ProgressView().progressViewStyle(LinearProgressViewStyle())
            Text("gacha.def.waiting")
                .multilineTextAlignment(.center)
                .font(.callout).foregroundStyle(.secondary)
        }
        .padding()
    }
}
