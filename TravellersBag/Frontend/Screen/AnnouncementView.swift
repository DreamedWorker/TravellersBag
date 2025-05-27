//
//  AnnouncementView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/20.
//

import SwiftUI
import SwiftData

struct AnnouncementView: View {
    @Query private var accounts: [HoyoAccount]
    @StateObject private var viewModel = AnnoViewModel()
    
    var body: some View {
        NavigationStack {
            if !viewModel.uiState.isLoading {
                ScrollView(showsIndicators: false) {
                    LazyVStack {
                        let gachaAnnoList = viewModel.uiState.annoFeed!.data.list
                            .filter({ $0.typeID == 1 }).first!.list
                            .filter({ $0.tagLabel == .扭蛋 })
                        Carousel(neoList: gachaAnnoList, gachaPools: viewModel.uiState.gachaFeed)
                        AnnoHotActivity()
                    }
                }
            } else {
                ContentUnavailableView("app.wait.normal", systemImage: "timer")
                    .onAppear {
                        Task {
                            await viewModel.loadGachaFeed() // 先获取祈愿池数据 是否成功均不影响页面正常加载
                            await viewModel.loadFeed()
                        }
                    }
            }
        }
        .alert(
            viewModel.uiState.alert.title,
            isPresented: $viewModel.uiState.alert.showIt,
            actions: {},
            message: { Text(viewModel.uiState.alert.msg) }
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    AnnouncementView()
}
