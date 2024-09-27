//
//  AchievementEntry.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/27.
//

import SwiftUI

struct AchievementEntry: View {
    let entry: AchieveItem
    let changeState: (AchieveItem) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Toggle(isOn: .constant(entry.finished), label: {}).toggleStyle(.checkbox)
            VStack(alignment: .leading, content: {
                Text(entry.title!)
                Text(entry.des!).foregroundStyle(.secondary).font(.footnote)
            })
            Spacer()
            if entry.finished {
                Text(
                    String.localizedStringWithFormat(
                        NSLocalizedString("achieve.content.finished_at", comment: ""),
                        num2time(time: Int(entry.timestamp)))
                ).foregroundStyle(.secondary).font(.callout)
            }
            Button(
                action: {
                    let mid = entry
                    entry.finished = !entry.finished
                    entry.timestamp = Int64(Date().timeIntervalSince1970)
                    changeState(mid)
                },
                label: { Image(systemName: (entry.finished) ? "xmark" : "checkmark") }
            )
            ZStack {
                Image("UI_QUALITY_ORANGE").resizable().frame(width: 36, height: 36)
                Image("原石").resizable().frame(width: 36, height: 36)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(String(entry.reward)).foregroundStyle(.white).font(.footnote)
                        Spacer()
                    }.background(.gray.opacity(0.6))
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    func num2time(time: Int) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.string(from: Date(timeIntervalSince1970: TimeInterval(time)))
    }
}
