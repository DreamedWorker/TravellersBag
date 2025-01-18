//
//  DailyNoteWidget.swift
//  NoteWidgetExtension
//
//  Created by 鸳汐 on 2025/1/18.
//

import SwiftUI
import WidgetKit

struct DailyNoteWidgetEntry: TimelineEntry {
    var date: Date
    var genshinUID: String
    var detail: NoteContext
}

struct DailyNoteProvider: IntentTimelineProvider {
    typealias Entry = DailyNoteWidgetEntry
    typealias Intent = DailyNoteConfigIntent
    
    func getSnapshot(for configuration: DailyNoteConfigIntent, in context: Context, completion: @escaping (DailyNoteWidgetEntry) -> Void) {
        let entry = DailyNoteWidgetEntry(date: Date(), genshinUID: "-1", detail: .init())
        completion(entry)
    }
    
    func getTimeline(
        for configuration: DailyNoteConfigIntent,
        in context: Context,
        completion: @escaping (Timeline<DailyNoteWidgetEntry>) -> Void
    ) {
        @Sendable func buildSimpleTimeline() {
            var entries: [DailyNoteWidgetEntry] = []
            let currentDate = Date()
            for hourOffset in 0 ..< 3 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let entry = DailyNoteWidgetEntry(date: entryDate, genshinUID: configuration.genshinUID ?? "0", detail: .init())
                entries.append(entry)
            }
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
        if let uid = configuration.genshinUID {
            DispatchQueue.global(qos: .background).async {
                if LocalService.shared.checkIfIsAllowed(uid: uid) {
                    Task {
                        do {
                            let data = try await WidgetService.default.fetchWidget(account: LocalService.shared.getCurrentAccount(uid: uid))
                            LocalService.shared.write2file(uid: uid, date: Date(), data: data)
                            let displayData = try JSONDecoder().decode(NoteContext.self, from: data)
                            var entries: [DailyNoteWidgetEntry] = []
                            let currentDate = Date()
                            for hourOffset in 0 ..< 3 {
                                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                                let entry = DailyNoteWidgetEntry(date: entryDate, genshinUID: uid, detail: displayData)
                                entries.append(entry)
                            }
                            let timeline = Timeline(entries: entries, policy: .atEnd)
                            completion(timeline)
                        } catch {
                            buildSimpleTimeline()
                        }
                    }
                } else {
                    buildSimpleTimeline()
                }
            }
        } else {
            buildSimpleTimeline()
        }
    }
    
    func placeholder(in context: Context) -> DailyNoteWidgetEntry {
        DailyNoteWidgetEntry(date: Date(), genshinUID: "-1", detail: .init())
    }
}

struct DailyNoteView: View {
    let entry: DailyNoteProvider.Entry
    
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
    
    var body: some View {
        VStack {
            HStack {
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("widget.dailynote.content.uid", comment: ""), entry.genshinUID)
                ).font(.footnote)
                Spacer()
                Text(entry.date, style: .time).foregroundStyle(.secondary).font(.footnote)
            }
            HStack {
                VStack {
                    HStack {
                        Image(systemName: "moon.circle.fill").font(.largeTitle).bold()
                        VStack(alignment: .leading) {
                            Text("widget.dailynote.content.resin").font(.callout)
                            HStack {
                                Text(String(entry.detail.current_resin)).foregroundStyle(.tint).font(.title2)
                                Text("/").font(.title2)
                                Text(String(entry.detail.max_resin)).foregroundStyle(.secondary).font(.title2)
                            }
                        }
                    }
                    Spacer()
                    HStack {
                        if entry.detail.resin_recovery_time == "0" {
                            Text("widget.dailynote.content.resinRecovered").font(.callout).foregroundStyle(.green).padding()
                        } else {
                            Text(String.localizedStringWithFormat(NSLocalizedString("widget.dailynote.content.resinGoing", comment: ""), seconds2text(second: entry.detail.resin_recovery_time))).font(.footnote).padding(2)
                        }
                    }
                    //.foregroundStyle(.secondary.opacity(0.45))
                    .background(.gray.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign").font(.callout)
                        Text("widget.dailynote.content.coin").font(.callout)
                        Spacer()
                        Text(String(entry.detail.current_home_coin)).font(.callout)
                        Text("/").font(.callout)
                        Text(String(entry.detail.max_home_coin)).font(.callout)
                    }.padding(2)
                    HStack(spacing: 4) {
                        Image(systemName: "scope").font(.callout)
                        Text("widget.dailynote.content.scope").font(.callout)
                        Spacer()
                        Text(String(entry.detail.finished_task_num)).font(.callout)
                        Text("/")
                        Text(String(entry.detail.total_task_num)).font(.callout)
                    }.padding(2)
                    HStack(spacing: 4) {
                        Image(systemName: "point.filled.topleft.down.curvedto.point.bottomright.up").font(.callout)
                        Text("widget.dailynote.content.expedition").font(.callout)
                        Spacer()
                        Text(String(entry.detail.current_expedition_num)).font(.callout)
                        Text("/").font(.callout)
                        Text(String(entry.detail.max_expedition_num)).font(.callout)
                    }.padding(2)
                    HStack {
                        ForEach(entry.detail.expeditions, id: \.avatar_side_icon) { single in
                            Circle()
                                .foregroundStyle(single.status == "Finished" ? .green : .yellow)
                                .padding(2)
                                .frame(width: 16, height: 16)
                        }
                    }.padding(2)
                    Spacer()
                }
                .padding(4)
                .background(BackgroundStyle())
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

struct DailyNoteWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: "daily-note-wg",
            intent: DailyNoteConfigIntent.self,
            provider: DailyNoteProvider(),
            content: { it in
                if #available(macOS 14.0, *) {
                    DailyNoteView(entry: it)
                        .containerBackground(.fill.tertiary, for: .widget)
                } else {
                    DailyNoteView(entry: it)
                        .padding()
                        .background()
                }
            }
        )
        .configurationDisplayName("widget.dailynote.name")
        .description("widget.dailynote.description")
        .supportedFamilies([.systemMedium])
    }
}
