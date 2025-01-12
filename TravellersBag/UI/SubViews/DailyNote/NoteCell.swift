//
//  NoteCell.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/12.
//

import SwiftUI
import SwiftyJSON
import Kingfisher

extension DailyNoteView {
    struct AbnormalPane: View {
        var delete: () -> Void
        
        var body: some View {
            VStack {
                Image("dailynote_empty").resizable().frame(width: 72, height: 72)
                Text("daily.abnormal.title").font(.title2).bold().padding(.bottom, 8)
                Button("daily.abnormal.delete", action: delete)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
        }
    }
}

extension DailyNoteView {
    struct NoteCell: View {
        var dailyContext: JSON
        var archonTasks: [ArchonTask] = []
        var expeditionTasks: [ExpeditionTask] = []
        var account: String
        var delete: () -> Void
        var refresh: () -> Void
        
        init(dailyContext: JSON, account: String, deleteEvt: @escaping () -> Void, refreshEvt: @escaping () -> Void) {
            self.dailyContext = dailyContext
            self.account = account
            self.delete = deleteEvt
            self.refresh = refreshEvt
            // 数据处理
            archonTasks.removeAll()
            for i in dailyContext["archon_quest_progress"]["list"].arrayValue {
                archonTasks.append(
                    ArchonTask(
                        id: i["id"].intValue, chapter_title: i["chapter_title"].stringValue, chapter_num: i["chapter_num"].stringValue,
                        status: i["status"].stringValue, chapter_type: i["chapter_type"].intValue)
                )
            }
            expeditionTasks.removeAll()
            for i in dailyContext["expeditions"].arrayValue {
                expeditionTasks.append(
                    ExpeditionTask(
                        avatar_side_icon: i["avatar_side_icon"].stringValue.replacingOccurrences(of: "\\", with: ""), status: i["status"].stringValue,
                        remained_time: i["remained_time"].stringValue, id: UUID().uuidString)
                )
            }
        }
        
        @State private var alert = AlertMate()
        @State private var useBtn = false
        
        var body: some View {
            VStack {
                //顶部标题栏
                HStack {
                    Text(account).font(.title3).bold()
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .onTapGesture {
                            useBtn = false
                            refresh()
                        }
                    Image(systemName: "trash")
                        .onTapGesture {
                            useBtn = true
                            alert.showAlert(msg: "要删除这个便签吗？")
                        }
                }.padding(.bottom, 4)
                // 便签内容区
                VStack(alignment: .leading) {
                    // 任务表
                    if dailyContext["archon_quest_progress"]["is_finish_all_mainline"].boolValue {
                        HStack(spacing: 8, content: {
                            Image(systemName: "flag.checkered").font(.title2)
                            Text("daily.display.mainline").font(.title2).bold()
                            Spacer()
                            Text("daily.display.mainline_off").foregroundStyle(.secondary)
                        })
                    } else {
                        ForEach(archonTasks) { task in
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
                            if dailyContext["resin_recovery_time"].stringValue == "0" {
                                Text("daily.display.resin_off").foregroundStyle(.secondary)
                            } else {
                                Text(
                                    String.localizedStringWithFormat(
                                        NSLocalizedString("daily.display.resin_on", comment: ""),
                                        seconds2text(
                                            second: dailyContext["resin_recovery_time"].stringValue))
                                ).foregroundStyle(.secondary)
                            }
                        })
                        Spacer()
                        HStack {
                            Text(String(dailyContext["current_resin"].intValue)).foregroundStyle(.tint)
                            Text("app.a")
                            Text(String(dailyContext["max_resin"].intValue))
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
                            Text(String(dailyContext["remain_resin_discount_num"].intValue)).foregroundStyle(.tint)
                            Text("app.a")
                            Text(String(dailyContext["resin_discount_num_limit"].intValue))
                        }
                    }
                    // 洞天宝钱
                    HStack {
                        Image(systemName: "bitcoinsign").font(.title2)
                        VStack(alignment: .leading, content: {
                            Text("daily.display.coin").font(.title3).bold()
                            if dailyContext["home_coin_recovery_time"].stringValue == "0" {
                                Text("daily.display.coin_off").foregroundStyle(.secondary)
                            } else {
                                Text(
                                    String.localizedStringWithFormat(
                                        NSLocalizedString("daily.display.coin_on", comment: ""),
                                        seconds2text(
                                            second: dailyContext["home_coin_recovery_time"].stringValue))
                                ).foregroundStyle(.secondary)
                            }
                        })
                        Spacer()
                        HStack {
                            Text(String(dailyContext["current_home_coin"].intValue)).foregroundStyle(.tint)
                            Text("app.a")
                            Text(String(dailyContext["max_home_coin"].intValue))
                        }
                    }
                    // 每日委托
                    HStack {
                        Image(systemName: "scope").font(.title2)
                        VStack(alignment: .leading, content: {
                            Text("daily.display.task").font(.title3).bold()
                            HStack {
                                Text(String(dailyContext["daily_task"]["finished_num"].intValue)).foregroundStyle(.tint)
                                Text("app.a")
                                Text(String(dailyContext["daily_task"]["total_num"].intValue))
                            }
                        })
                        Spacer()
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("daily.display.stored_attendance", comment: ""),
                                dailyContext["daily_task"]["stored_attendance"].stringValue)
                        ).foregroundStyle(.secondary)
                    }
                    // 参量质变仪
                    HStack {
                        VStack(alignment: .leading, content: {
                            Text("daily.display.transformer").font(.title3).bold()
                            if dailyContext["transformer"]["recovery_time"]["reached"].boolValue {
                                Text("daily.display.transformer_off").foregroundStyle(.secondary)
                            } else {
                                Text(
                                    String.localizedStringWithFormat(
                                        NSLocalizedString("daily.display.transformer_on", comment: ""),
                                        String(dailyContext["transformer"]["recovery_time"]["Day"].intValue),
                                        String(dailyContext["transformer"]["recovery_time"]["Hour"].intValue),
                                        String(dailyContext["transformer"]["recovery_time"]["Minute"].intValue)
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
                            Text(String(dailyContext["current_expedition_num"].intValue)).foregroundStyle(.tint)
                            Text("app.a")
                            Text(String(dailyContext["max_expedition_num"].intValue))
                        }.padding(4)
                        ForEach(expeditionTasks) { task in
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
                                            seconds2text(second: task.remained_time))
                                    ).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                Text("daily.display.refreshTip").font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
            .alert(alert.msg, isPresented: $alert.showIt, actions: {
                if useBtn {
                    Button("def.confirm", role: .destructive, action: { alert.showIt = false; useBtn = false; delete() })
                }
            })
        }
        
        /// 将秒转换为【xx分xx秒】的形式
        private func seconds2text(second: String) -> String {
            let target = Int(second)!
            let hours = target / 3600
            let minutes = (target % 3600) / 60
            //let seconds = target % 60
            if hours > 0 {
                return String(format: "%02d小时%02d分钟", hours, minutes)
            } else if minutes > 0 {
                return String(format: "%02d分钟", minutes)
            } else {
                return "即将完成"
            }
        }
    }
}
