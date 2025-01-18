//
//  AvatarDisplayUnit.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/5.
//

import SwiftUI
import Kingfisher

/// 命座显示单元
struct ConstellationUnit: View {
    let skill: Constellation
    @State var showDetail = false
    
    var body: some View {
        ZStack {
            Rectangle().foregroundStyle(.secondary.opacity(0.4)).frame(width: 36, height: 36)
            if let localImg = skill.localIcon {
                Image(nsImage: NSImage(contentsOfFile: localImg) ?? NSImage())
                    .resizable().frame(width: 36, height: 36).colorScheme(.dark)
            } else {
                KFImage(URL(string: skill.icon))
                    .loadDiskFileSynchronously(true)
                    .resizable().frame(width: 36, height: 36).colorScheme(.dark)
            }
            if !skill.is_actived {
                Image("skill_not_active").resizable().frame(width: 16, height: 16).colorScheme(.dark)
            }
        }
        .help(skill.name)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail, content: {
            ConstellationSheet(single: skill, hide: { showDetail = false })
        })
    }
}

/// 天赋显示单元
struct SkillUnit: View {
    let skill: AvatarSkill
    @State var showDetail = false
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle().foregroundStyle(.secondary.opacity(0.4)).frame(width: 36, height: 36)
                if let localImg = skill.localIcon {
                    Image(nsImage: NSImage(contentsOfFile: localImg) ?? NSImage())
                        .resizable().frame(width: 36, height: 36).colorScheme(.dark)
                } else {
                    KFImage(URL(string: skill.icon))
                        .loadDiskFileSynchronously(true)
                        .resizable().frame(width: 36, height: 36).colorScheme(.dark)
                }
            }
            .help(skill.name)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(String.localizedStringWithFormat(NSLocalizedString("avatar.display.lv", comment: ""), String(skill.level)))
                .font(.callout)
        }
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail, content: {
            SkillSheet(skill: skill, hide: { showDetail = false })
        })
    }
}

