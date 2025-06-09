//
//  AchieveGroupEntry.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/9.
//

import SwiftUI

struct AchieveGroupEntry: View {
    let entry: AchievementGroupElement
    let summary: (total: Int, completed: Int)
    
    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: getAchieveIcon(name: "\(entry.icon).png"))
                .resizable()
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, content: {
                Text(entry.name).bold()
                let progress = Double((Double(summary.completed) / Double(summary.total)) * 100)
                Text("\(summary.completed)/\(summary.total) - \(Int(progress))%")
                    .font(.footnote).foregroundStyle(.secondary)
            })
        }
    }
    
    private func getAchieveIcon(name: String) -> NSImage {
        if let url = PicResource.getRequiredImage(type: "AchievementIcon", name: name) {
            return NSImage(contentsOf: url)!
        } else {
            return NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: nil)!
        }
    }
}
