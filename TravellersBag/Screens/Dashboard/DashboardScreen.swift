//
//  DashboardScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/20.
//

import SwiftUI
import WaterfallGrid

struct DashboardScreen: View {
    @StateObject private var viewModel = DashboardModel()
    @State private var showRefreshAlert = false
    let columns: [GridItem] = [
        .init(.flexible()), .init(.flexible()), .init(.flexible())
    ]
    
    var body: some View {
        if viewModel.showUI {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Text("dashboard.main.title").font(.title).bold()
                        Spacer()
                        Button("dashboard.main.load", action: {
                            showRefreshAlert = true
                        }).buttonStyle(BorderedProminentButtonStyle())
                    }.padding()
                    LazyVGrid(columns: columns, content: {
                        DashboardUnits.LaunchGame()
                        DashboardUnits.BasicInfo(partData: viewModel.basicData?["stats"])
                    })
                }
                WorldExploration(regions: viewModel.basicData?["world_explorations"].array)
            }
            .alert(
                "app.notice", isPresented: $showRefreshAlert,
                actions: {
                    Button("app.cancel", action: { showRefreshAlert = false })
                    Button("app.confirm", action: {
                        viewModel.showUI = false
                        Task {
                            do {
                                try await viewModel.fetchContextAndSave(account: GlobalUIModel.exported.defAccount!)
                            } catch {
                                DispatchQueue.main.async {
                                    GlobalUIModel.exported.makeAnAlert(
                                        type: 3, msg: NSLocalizedString("dashboard.error.fetch_data", comment: ""))
                                }
                            }
                        }
                    })
                },
                message: { Text("dashboard.alert.refresh_p") }
            )
        } else {
            VStack {
                Image("expecting_new_world").resizable().scaledToFit().frame(width: 72, height: 72)
                Text("dashboard.empty.title").font(.title2).bold().padding(.top, 4)
                Text("dashboard.empty.context")
                Button("dashboard.empty.refresh", action: { viewModel.refreshState() }).buttonStyle(BorderedProminentButtonStyle())
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .frame(maxWidth: 500)
        }
    }
}
