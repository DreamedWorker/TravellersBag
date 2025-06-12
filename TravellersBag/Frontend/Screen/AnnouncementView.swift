//
//  AnnouncementView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/20.
//

import SwiftUI
import SwiftData
import Kingfisher

struct AnnouncementView: View {
    @Query private var accounts: [HoyoAccount]
    @StateObject private var viewModel = AnnoViewModel()
    @State private var selectedURL: AnnoDetailStruct.DetailList.AnnoUnit? = nil
    
    var body: some View {
        NavigationStack {
            if !viewModel.uiState.isLoading {
                ScrollView(showsIndicators: false) {
                    VStack {
                        let gachaAnnoList = viewModel.uiState.annoFeed!.data.list
                            .filter({ $0.typeID == 1 }).first!.list
                            .filter({ $0.tagLabel == .扭蛋 })
                        Carousel(neoList: gachaAnnoList, gachaPools: viewModel.uiState.gachaFeed)
                        AnnoHotActivity().padding(.bottom)
                        Divider()
                        HStack {
                            Text("anno.label.moreFlows").font(.title2.bold())
                            Spacer()
                            Link("anno.link.commnuity", destination: URL(string: "https://www.miyoushe.com/ys/")!)
                        }
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())]) {
                            let type1 = viewModel.uiState.annoFeed!.data.list
                                .filter({ $0.typeID == 1 }).first!.list
                                .filter({ $0.tagLabel != .扭蛋 })
                            let type2 = viewModel.uiState.annoFeed!.data.list
                                .filter({ $0.typeID == 2 }).first!.list
                            let type3 = type1 + type2
                            ForEach(type3, id: \.annID) { a in
                                NoticeNormalDetail(a: a)
                                    .onTapGesture {
                                        selectedURL = viewModel.getRequiredAnnoDetail(annId: a.annID)
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .sheet(item: $selectedURL, content: { con in
                    AnnoDetailViewer(detail: con)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction, content: {
                                Button("app.close") {
                                    selectedURL = nil
                                }
                            })
                        }
                })
            } else {
                ContentUnavailableView("app.wait.normal", systemImage: "timer")
                    .onAppear {
                        Task {
                            await viewModel.loadGachaFeed() // 先获取祈愿池数据 是否成功均不影响页面正常加载
                            await viewModel.loadAnnoDetail() // 获取通知详情 是否成功均不影响页面正常加载
                            await viewModel.loadFeed()
                        }
                    }
            }
        }
        .navigationTitle(Text("content.side.label.anno"))
        .background(Rectangle().fill(.background))
        .alert(
            viewModel.uiState.alert.title,
            isPresented: $viewModel.uiState.alert.showIt,
            actions: {},
            message: { Text(viewModel.uiState.alert.msg) }
        )
    }
}
