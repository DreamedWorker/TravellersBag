//
//  NoticeScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/18.
//

import SwiftUI
import WaterfallGrid
import Kingfisher
import SwiftyJSON

struct NoticeScreen: View {
    @StateObject private var viewModel = NoticeModel()
    @State private var uiPart: NoticePart = .Game
    
    let column: [GridItem] = [
        .init(.flexible()), .init(.flexible()), .init(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "app.gift").font(.title2)
                        Text("notice.main.current_gacha").font(.title2).bold()
                        Spacer()
                    }.padding()
                    GachaTime(gachaNote: viewModel.announcementContext.filter({ $0.subtitle.contains("祈愿")}).first)
                    PartView(
                        parts: viewModel.announcementContext.filter({ $0.subtitle.contains("祈愿")}),
                        goTo: { want in return viewModel.getNoticeDetailEntry(id: want)}
                    ).padding(.horizontal, 4).padding(.bottom, 4)
                }
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                .padding(.horizontal, 16).padding(.top, 8)
                TabView(
                    selection: $uiPart,
                    content: {
                        PartView(
                            parts: viewModel.announcementContext.filter({ $0.type == 1 }).filter({ !$0.subtitle.contains("祈愿") }),
                            goTo: { want in return viewModel.getNoticeDetailEntry(id: want)})
                        .tabItem({ Text("notice.tag.game") }).tag(NoticePart.Game)
                        PartView(
                            parts: viewModel.announcementContext.filter({ $0.type == 2 }).filter({ !$0.subtitle.contains("祈愿") }),
                            goTo: { want in return viewModel.getNoticeDetailEntry(id: want)})
                        .tabItem({ Text("notice.tag.notice") }).tag(NoticePart.Notice)
                    }
                )
            }
            .navigationTitle(Text("home.sider.notice"))
            .toolbar {
                ToolbarItem {
                    Button(
                        action: { Task { await viewModel.refreshSource() }},
                        label: { Image(systemName: "arrow.clockwise").help("notice.menu.refresh") }
                    )
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchNews()
                await viewModel.fetchNewsDetail()
            }
        }
    }
    
    struct PartView: View {
        let column: [GridItem] = [
            .init(.flexible()), .init(.flexible()), .init(.flexible())
        ]
        let parts: [NoticeEntry]?
        let goTo: (Int) -> JSON?
        
        var body: some View {
            if let part = parts {
                LazyVGrid(columns: column, content: {
                    ForEach(part, id: \.annId) { a in
                        NavigationLink(
                            destination: { NoticeDetail(single: goTo(a.annId)) },
                            label: {
                                VStack {
                                    KFImage(URL(string: a.banner))
                                        .loadDiskFileSynchronously(true)
                                        .placeholder({ ProgressView() })
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                    Text(a.subtitle).font(.title3).bold()
                                    Text(a.title).padding(.bottom, 4)
                                }
                                .padding(0)
                            }
                        )
                    }
                })
            }
        }
    }
    
    struct GachaTime: View {
        let gachaNote: NoticeEntry?
        
        var body: some View {
            if let note = gachaNote {
                VStack(alignment: .leading, content: {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                        Text("notice.main.gacha_time")
                        Spacer()
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("notice.main.gacha_time_p", comment: ""), note.start, note.end)
                        ).font(.callout).foregroundStyle(.secondary)
                    }
                    ProgressView(
                        value: 1 - (Float(dateSpacer(s1: Date.now, s2: note.end)) / Float(dateSpacer(s1: note.start, s2: note.end))),
                        total: 1.0)
                }).padding(.horizontal, 16)
            }
        }
        
        private func dateSpacer(s1: Date, s2: String) -> Int {
            let b = string2date(str: s2)
            let r = Calendar.current.dateComponents([.day], from: s1, to: b).day ?? 0
            return r
        }
        
        private func dateSpacer(s1: String, s2: String) -> Int {
            let b = string2date(str: s2); let a = string2date(str: s1)
            let r = Calendar.current.dateComponents([.day], from: a, to: b).day ?? 0
            return r
        }
        
        private func string2date(str: String) -> Date {
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return format.date(from: str)!
        }
    }
    
    private enum NoticePart {
        case Notice
        case Game
    }
}
