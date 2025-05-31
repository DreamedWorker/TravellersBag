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
    
    var body: some View {
        NavigationStack {
            if !viewModel.uiState.isLoading {
                ScrollView(showsIndicators: false) {
                    VStack {
                        let gachaAnnoList = viewModel.uiState.annoFeed!.data.list
                            .filter({ $0.typeID == 1 }).first!.list
                            .filter({ $0.tagLabel == .扭蛋 })
                        Carousel(neoList: gachaAnnoList, gachaPools: viewModel.uiState.gachaFeed)
                        AnnoHotActivity()
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())]) {
                            let type1 = viewModel.uiState.annoFeed!.data.list
                                .filter({ $0.typeID == 1 }).first!.list
                                .filter({ $0.tagLabel != .扭蛋 })
                            let type2 = viewModel.uiState.annoFeed!.data.list
                                .filter({ $0.typeID == 2 }).first!.list
                            let type3 = type1 + type2
                            ForEach(type3, id: \.annID) { a in
                                NoticeNormalDetail(a: a) { annId in
                                    if let details = viewModel.uiState.annoDetail {
                                        if let content = details.data.list.filter({ $0.annId == annId }).first {
                                            return content
                                        }
                                        return nil
                                    }
                                    return nil
                                }
                            }
                        }
                    }
                }
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

extension AnnouncementView {
    struct NoticeNormalDetail: View {
        let a: AnnounceRepo.AnnoStruct.AnnoList
        let showDetail: (Int) -> AnnoDetailStruct.DetailList.AnnoUnit?
        @State private var showSheet: Bool = false
        
        private func convertDateString(_ input: String) -> String {
            let inputFormat = "yyyy-MM-dd HH:mm:ss"
            let outputFormat = "yyyy/MM/dd HH:mm"
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = inputFormat
            guard let date = dateFormatter.date(from: input) else {
                return input
            }
            dateFormatter.dateFormat = outputFormat
            return dateFormatter.string(from: date)
        }
        
        var body: some View {
            VStack {
                KFImage(URL(string: a.banner))
                    .loadDiskFileSynchronously(true)
                    .resizable()
                    .frame(height: 72)
                Text(a.subtitle).bold()
                Text(a.title).font(.footnote).foregroundStyle(.secondary)
                    .padding(.bottom, 4).lineLimit(1).padding(.horizontal, 2)
                HStack {
                    Spacer()
                    Text(a.typeLabel.rawValue).font(.footnote).foregroundStyle(.secondary)
                }.padding(.horizontal, 2)
                HStack() {
                    Label(
                        String.localizedStringWithFormat(
                            NSLocalizedString("anno.label.date", comment: ""),
                            convertDateString(a.startTime),
                            convertDateString(a.endTime)
                        ),
                        systemImage: "calendar"
                    ).font(.footnote)
                    Spacer()
                }.padding(.horizontal, 2).padding(.bottom, 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .onTapGesture {
                showSheet = true
            }
            .sheet(isPresented: $showSheet, content: {
                NavigationStack {
                    AnnoDetailViewer(detail: showDetail(a.annID))
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction, content: {
                        Button("app.close", action: {
                            showSheet = false
                        })
                    })
                }
            })
        }
    }
}

#Preview {
    AnnouncementView()
}
