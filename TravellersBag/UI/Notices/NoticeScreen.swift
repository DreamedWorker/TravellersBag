//
//  NoticeScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/6.
//

import SwiftUI
import CoreData
import AlertToast

private enum NoticePart {
    case GameActivity
    case GameNotice
}

struct NoticeScreen: View {
    @StateObject private var viewModel = NoticeModel()
    @Environment(\.managedObjectContext) private var context
    @State private var selectedScope: NoticePart = .GameNotice
    
    func viewFetchDaily() {
        Task {
            do {
                try await viewModel.fetchDailyNote()
            } catch {
                DispatchQueue.main.async {
                    self.viewModel.errMsg = error.localizedDescription
                    self.viewModel.showError = true
                }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            HStack {
                Text("notice.title").font(.title2)
                Spacer()
            }.padding(.bottom, 4)
            Grid(alignment: .topLeading) {
                GridRow {
                    launchWine
                    dailyNote.onAppear { viewFetchDaily() }
                }
            }.frame(maxWidth: .infinity)
            TabView(selection: $selectedScope, content: {
                AnnouncementPart(specificList: viewModel.announcements.filter{ $0.typeLabel == "活动公告" })
                    .tabItem({ Text("notice.container.tab_note") })
                    .tag(NoticePart.GameNotice)
                AnnouncementPart(specificList: viewModel.announcements.filter{ $0.typeLabel == "游戏公告" })
                    .tabItem({ Text("notice.container.tab_game") })
                    .tag(NoticePart.GameActivity)
            }).padding(.vertical, 8)
        }
        .toolbar(content: {
            ToolbarItem(content: {
                Button(
                    action: {
                        viewModel.announcements.removeAll()
                        Task {
                            do {
                                try await viewModel.refreshAnnouncement()
                            } catch {
                                DispatchQueue.main.async {
                                    self.viewModel.showError = true
                                    self.viewModel.errMsg = error.localizedDescription
                                }
                            }
                        }
                    },
                    label: { Image(systemName: "arrow.clockwise").help("notice.toolbar.refresh") }
                )
            })
        })
        .padding(16)
        .onAppear {
            viewModel.context = context
            viewModel.fetchList()  // 即使这么做，依然需要判断是否为空
            Task {
                do {
                    try await viewModel.fetchAnnouncement()
                } catch {
                    DispatchQueue.main.async {
                        self.viewModel.errMsg = error.localizedDescription
                        self.viewModel.showError = true
                    }
                }
            }
        }
        .toast(isPresenting: $viewModel.showError, alert: { AlertToast(type: .error(.red), title: viewModel.errMsg) })
    }
    
    var launchWine: some View { // 打开兼容层的卡片
        CardView {
            VStack {
                HStack {
                    Image(systemName: "gamecontroller").font(.system(size: 18))
                    Spacer()
                }.padding(.bottom, 8)
                HStack {
                    Text("notice.card.launching.title").font(.system(size: 14)).bold().foregroundStyle(.cyan)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Button("notice.card.launching.start", action: { viewModel.openWineApp() })
                }
            }
            .frame(width: 270, height: 145).padding(4)
        }
    }
    
    var dailyNote: some View {
        CardView {
            VStack {
                if viewModel.showDailyNote { // 能执行到这里说明没有问题
                    HStack {
                        Text(String.localizedStringWithFormat(NSLocalizedString("notice.card.daily.title", comment: ""), viewModel.defaultHoyo!.genshinUID ?? ""))
                        Spacer()
                        Button(action: { viewModel.refreshDaily() }, label: { Image(systemName: "arrow.clockwise")} )
                    }.padding(.top, 2)
                    DailyNoteTile(
                        imgName: "浓缩树脂",
                        title: NSLocalizedString("notice.card.daily.resin", comment: ""),
                        state: "\(viewModel.noteJSON!["current_resin"].intValue)/\(viewModel.noteJSON!["max_resin"].intValue)",
                        useVStack: false
                    )
                    Grid {
                        GridRow {
                            DailyNoteTile(
                                imgName: "洞天宝钱",
                                title: NSLocalizedString("notice.card.daily.home_coin", comment: ""),
                                state: "\(viewModel.noteJSON!["current_home_coin"].intValue)/\(viewModel.noteJSON!["max_home_coin"].intValue)",
                                useVStack: true
                            )
                            DailyNoteTile(
                                imgName: "每日任务",
                                title: NSLocalizedString("notice.card.daily.tasks", comment: ""),
                                state: "\(viewModel.noteJSON!["finished_task_num"].intValue)/\(viewModel.noteJSON!["total_task_num"].intValue)",
                                useVStack: true
                            )
                            DailyNoteTile(
                                imgName: "探索派遣",
                                title: NSLocalizedString("notice.card.daily.expedition", comment: ""),
                                state: "\(viewModel.getExpeditionState())/\(viewModel.noteJSON!["max_expedition_num"].intValue)",
                                useVStack: true
                            )
                        }
                    }
                    Spacer()
                } else {
                    Image(systemName: "note.text.badge.plus").font(.system(size: 16))
                    Text("notice.card.daily.nothing_to_show").padding(.bottom, 4)
                    Button("notice.card.daily.fetch", action: { viewFetchDaily() })
                }
            }.frame(width: 270, height: 145).padding(4)
        }
    }
}

#Preview {
    NoticeScreen()
}
