//
//  AchieveItemEntry.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/9.
//

import SwiftUI
import SwiftData

struct AchieveItemEntry: View {
    let item: AchieveItem
    let operation: ModelContext
    
    var body: some View {
        HStack {
            Toggle(isOn: .constant(item.finished), label: {})
                .toggleStyle(.checkbox)
                .controlSize(.large)
            VStack(alignment: .leading) {
                Text(item.title)
                Text(item.des).foregroundStyle(.secondary).font(.footnote)
            }
            Spacer()
            if item.finished {
                Text(item.timestamp.formatTimestamp()).font(.callout)
            }
            ZStack {
                Image("UI_QUALITY_ORANGE").resizable().frame(width: 36, height: 36)
                Image("原石").resizable().frame(width: 36, height: 36)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(String(item.reward)).foregroundStyle(.white).font(.footnote)
                        Spacer()
                    }.background(.gray.opacity(0.6))
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Button(
                action: {
                    item.finished = !item.finished
                    item.timestamp = Int(Date().timeIntervalSince1970)
                    try! operation.save()
                },
                label: { Image(systemName: (item.finished) ? "xmark" : "checkmark") }
            )
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.background))
    }
}
