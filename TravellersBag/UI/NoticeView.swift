//
//  NoticeView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/8.
//

import SwiftUI
import SwiftyJSON
import Kingfisher

struct NoticeView: View {
    @StateObject private var vm = NoticeViewModel()
    
    var body: some View {
        NavigationStack {
            if vm.announcementContext.count == 0 || vm.announcementDetail.count == 0 {
                DefaultPane
            } else {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "app.gift").font(.title)
                        Text("notice.main.current_gacha").font(.title).bold()
                        Spacer()
                    }.padding()
                    GachaTimeDisplay(gachaNote: vm.announcementContext.filter({ $0.subtitle.contains("祈愿") }).first)
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())]) {
                        let gachas = vm.announcementContext.filter({ $0.subtitle.contains("祈愿") })
                        if gachas.count <= 3 {
                            ForEach(gachas) { a in
                                CurrentGacha(a: a, getContent: { want in return vm.getNoticeDetailEntry(id: a.id) })
                            }
                        } else { // 这里解决了祈愿显示超前的问题
                            if Date.now >= string2date(str: gachas.first!.end) {
                                ForEach(gachas[3...]) { a in
                                    CurrentGacha(a: a, getContent: { want in return vm.getNoticeDetailEntry(id: a.id) })
                                }
                            } else {
                                ForEach(gachas[..<3]) { a in
                                    CurrentGacha(a: a, getContent: { want in return vm.getNoticeDetailEntry(id: a.id) })
                                }
                            }
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 8)
                }
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                .padding(.top, 8)
                ScrollView {
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())]) {
                        let otherAnnouncements = vm.announcementContext.filter({ !$0.subtitle.contains("祈愿") })
                        ForEach(otherAnnouncements) { a in
                            NoticeNormalDetail(a: a, getNoticeDetail: { index in vm.getNoticeDetailEntry(id: index) })
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle(Text("home.sidebar.notice"))
        .onAppear {
            Task {
                await vm.fetchAnnouncements()
                await vm.fetchAnnouncementDetails()
            }
        }
        .toolbar {
            ToolbarItem {
                Button(
                    action: {
                        Task {
                            await vm.forceRefresh()
                        }
                    },
                    label: {
                        Image(systemName: "arrow.clockwise").help("def.refresh")
                    }
                )
            }
        }
        .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
    }
    
    private var DefaultPane: some View {
        return VStack {
            Image("dailynote_empty").resizable().frame(width: 72, height: 72)
            Text("notice.def.title").font(.title).bold().padding(.vertical, 4)
            Text("notice.def.subtitle").multilineTextAlignment(.center).padding(.bottom)
            Button("notice.def.retry", action: {
                Task {
                    await vm.fetchAnnouncements(useNetwork: true)
                    await vm.fetchAnnouncementDetails(useNetwork: true)
                }
            })
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
    }
    
    // 显示当期卡池的图片 点按后弹出sheet
    private struct CurrentGacha: View {
        @State var showSheet: Bool = false
        let a: NoticeEntry
        let getContent: (Int) -> JSON?
        
        var body: some View {
            VStack {
                KFImage(URL(string: a.banner))
                    .loadDiskFileSynchronously(true)
                    .placeholder({ ProgressView() })
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onTapGesture {
                showSheet = true
            }
            .sheet(isPresented: $showSheet, content: { NoticeDetailBrowser(entry: getContent(a.id), dismiss: { showSheet = false }) })
        }
    }
    
    private func string2date(str: String) -> Date {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return format.date(from: str)!
    }
}

#Preview {
    NoticeView()
}
