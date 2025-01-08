//
//  GachaTimeDisplay.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/8.
//

import SwiftUI

struct GachaTimeDisplay: View {
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
