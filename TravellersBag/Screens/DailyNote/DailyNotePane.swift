//
//  DailyNotePane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/30.
//

import SwiftUI
import Kingfisher

struct DailyNotePane: View {
    @StateObject private var viewModel = DailyModel.shared
    @State private var hasAccount: Bool = GlobalUIModel.exported.hasDefAccount()
    
    var body: some View {
        VStack {
            if hasAccount {
                if viewModel.showUI {
                    ScrollView {
                        Form {
                            // 任务表
                            if viewModel.dailyContext!["archon_quest_progress"]["is_finish_all_mainline"].boolValue {
                                HStack(spacing: 8, content: {
                                    Image(systemName: "flag.checkered").font(.title2)
                                    Text("daily.display.mainline").font(.title2).bold()
                                    Spacer()
                                    Text("daily.display.mainline_off").foregroundStyle(.secondary)
                                })
                            } else {
                                ForEach(viewModel.archonTasks) { task in
                                    HStack(spacing: 8, content: {
                                        Image(systemName: "flag.checkered").font(.title2)
                                        VStack(alignment: .leading, content: {
                                            Text("daily.display.mainline").font(.title3).bold()
                                            HStack (spacing: 8, content: {
                                                Text(task.chapter_num).foregroundStyle(.secondary)
                                                Text(task.chapter_title)
                                            })
                                        })
                                        Spacer()
                                        Text("daily.display.mainline_on").foregroundStyle(.secondary)
                                    })
                                }
                            }
                            // 原粹树脂
                            HStack {
                                Image(systemName: "moon.circle.fill").font(.title2)
                                VStack(alignment: .leading, content: {
                                    Text("daily.display.resin").font(.title3).bold()
                                    if viewModel.dailyContext!["resin_recovery_time"].stringValue == "0" {
                                        Text("daily.display.resin_off").foregroundStyle(.secondary)
                                    } else {
                                        Text(
                                            String.localizedStringWithFormat(
                                                NSLocalizedString("daily.display.resin_on", comment: ""),
                                                viewModel.seconds2text(
                                                    second: viewModel.dailyContext!["resin_recovery_time"].stringValue))
                                        ).foregroundStyle(.secondary)
                                    }
                                })
                                Spacer()
                                HStack {
                                    Text(String(viewModel.dailyContext!["current_resin"].intValue)).foregroundStyle(.tint)
                                    Text("app.a")
                                    Text(String(viewModel.dailyContext!["max_resin"].intValue))
                                }
                            }
                            // 周本
                            HStack {
                                Image(systemName: "house").font(.title2)
                                VStack(alignment: .leading, content: {
                                    Text("daily.display.resin_discount").font(.title3).bold()
                                    Text("daily.display.resin_discount_p").foregroundStyle(.secondary)
                                })
                                Spacer()
                                HStack {
                                    Text(String(viewModel.dailyContext!["remain_resin_discount_num"].intValue)).foregroundStyle(.tint)
                                    Text("app.a")
                                    Text(String(viewModel.dailyContext!["resin_discount_num_limit"].intValue))
                                }
                            }
                            // 洞天宝钱
                            HStack {
                                Image(systemName: "bitcoinsign").font(.title2)
                                VStack(alignment: .leading, content: {
                                    Text("daily.display.coin").font(.title3).bold()
                                    if viewModel.dailyContext!["home_coin_recovery_time"].stringValue == "0" {
                                        Text("daily.display.coin_off").foregroundStyle(.secondary)
                                    } else {
                                        Text(
                                            String.localizedStringWithFormat(
                                                NSLocalizedString("daily.display.coin_on", comment: ""),
                                                viewModel.seconds2text(
                                                    second: viewModel.dailyContext!["home_coin_recovery_time"].stringValue))
                                        ).foregroundStyle(.secondary)
                                    }
                                })
                                Spacer()
                                HStack {
                                    Text(String(viewModel.dailyContext!["current_home_coin"].intValue)).foregroundStyle(.tint)
                                    Text("app.a")
                                    Text(String(viewModel.dailyContext!["max_home_coin"].intValue))
                                }
                            }
                            // 每日委托
                            HStack {
                                Image(systemName: "scope").font(.title2)
                                VStack(alignment: .leading, content: {
                                    Text("daily.display.task").font(.title3).bold()
                                    HStack {
                                        Text(String(viewModel.dailyContext!["daily_task"]["finished_num"].intValue)).foregroundStyle(.tint)
                                        Text("app.a")
                                        Text(String(viewModel.dailyContext!["daily_task"]["total_num"].intValue))
                                    }
                                })
                                Spacer()
                                Text(
                                    String.localizedStringWithFormat(
                                        NSLocalizedString("daily.display.stored_attendance", comment: ""),
                                        viewModel.dailyContext!["daily_task"]["stored_attendance"].stringValue)
                                ).foregroundStyle(.secondary)
                            }
                            // 参量质变仪
                            HStack {
                                //Image("transformer").resizable().scaledToFit().frame(width: 24, height: 24)
                                VStack(alignment: .leading, content: {
                                    Text("daily.display.transformer").font(.title3).bold()
                                    if viewModel.dailyContext!["transformer"]["recovery_time"]["reached"].boolValue {
                                        Text("daily.display.transformer_off").foregroundStyle(.secondary)
                                    } else {
                                        Text(
                                            String.localizedStringWithFormat(
                                                NSLocalizedString("daily.display.transformer_on", comment: ""),
                                                String(viewModel.dailyContext!["transformer"]["recovery_time"]["Day"].intValue),
                                                String(viewModel.dailyContext!["transformer"]["recovery_time"]["Hour"].intValue),
                                                String(viewModel.dailyContext!["transformer"]["recovery_time"]["Minute"].intValue)
                                            )
                                        ).foregroundStyle(.secondary)
                                    }
                                })
                            }
                            // 探索派遣
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("daily.display.expedition")
                                    Spacer()
                                    Text(String(viewModel.dailyContext!["current_expedition_num"].intValue)).foregroundStyle(.tint)
                                    Text("app.a")
                                    Text(String(viewModel.dailyContext!["max_expedition_num"].intValue))
                                }.padding(4)
                                ForEach(viewModel.expeditionTasks) { task in
                                    HStack(spacing: 8) {
                                        KFImage(URL(string: task.avatar_side_icon))
                                            .loadDiskFileSynchronously(true)
                                            .resizable()
                                            .frame(width: 32, height: 32)
                                        if task.status == "Finished" {
                                            Text("daily.display.expedition_off").foregroundStyle(.green)
                                        } else {
                                            Text(
                                                String.localizedStringWithFormat(
                                                    NSLocalizedString("daily.display.expedition_on", comment: ""),
                                                    viewModel.seconds2text(second: task.remained_time))
                                            ).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }.formStyle(.grouped).scrollDisabled(true)
                    }
                } else {
                    VStack {
                        Image("expecting_new_world").resizable().scaledToFit().frame(width: 72, height: 72).padding(.bottom, 4)
                        Text("daily.no_content.title").font(.title2).bold().padding(.bottom, 8)
                        Button("daily.no_content.do", action: {
                            Task { await viewModel.updateNoteInfo() }
                        }).buttonStyle(BorderedProminentButtonStyle())
                    }
                    .onAppear { viewModel.readContext() }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                    .frame(minWidth: 400)
                }
            } else {
                VStack {
                    Image("expecting_but_nothing").resizable().scaledToFit().frame(width: 72, height: 72).padding(.bottom, 4)
                    Text("daily.no_account.title").font(.title2).bold().padding(.bottom, 8)
                    Button("dashboard.empty.refresh", action: {
                        GlobalUIModel.exported.refreshDefAccount()
                        hasAccount = GlobalUIModel.exported.hasDefAccount()
                    }).buttonStyle(BorderedProminentButtonStyle())
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                .frame(minWidth: 400)
            }
        }
        .toolbar {
            ToolbarItem {
                Button(
                    action: {
                        if hasAccount {
                            viewModel.showUI = false
                            Task { await viewModel.updateNoteInfo() }
                        } else {
                            GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("daily.no_account.title", comment: ""))
                        }
                    },
                    label: { Image(systemName: "arrow.clockwise").help("daily.refresh") }
                )
            }
        }
    }
}
