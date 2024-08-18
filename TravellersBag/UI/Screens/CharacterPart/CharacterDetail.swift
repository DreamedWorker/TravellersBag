//
//  CharacterDetail.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/18.
//

import SwiftUI
import Kingfisher

struct CharacterDetail: View {
    var character: EnkaAvatar?
    let characterController = CharacterModel.shared  // 这里只能调用其中的与更新UI无关的方法！！！
    let skillInfo: JSON?
    
    init(character: EnkaAvatar?) {
        self.character = character
        if let cha = character {
            skillInfo = try! JSON(data: characterController.getCharacterSkillIconList(id: cha.avatarId, map: cha.skillLevelMap))
        } else { skillInfo = nil }
    }
    
    var body: some View {
        if character != nil {
            ScrollView {
                characterBasic //显示概览信息
            }
        } else {
            VStack {
                Image("empty_or_select_first")
                Text("character.detail.select_first").font(.title2).bold()
            }.padding()
        }
    }
    
    /// 角色概览信息
    var characterBasic: some View {
        CardView {
            VStack {
                HStack {
                    KFImage(URL(string: characterController.getCharacterIcon(key: character!.avatarId, isSide: false))!)
                        .placeholder({ Image(systemName: "dot.radiowaves.left.and.right") })
                        .loadDiskFileSynchronously()
                        .resizable()
                        .frame(width: 64, height: 64)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.trailing, 16)
                    VStack(alignment: .leading) {
                        Text(characterController.getTranslationText(key: character!.avatarId)).font(.title3).bold()
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("character.detail.level", comment: ""), character!.avatarLevel)
                        ).font(.footnote)
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("character.detail.fetter", comment: ""), character!.fetterInfo)
                        ).font(.footnote)
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("character.detail.talents", comment: ""),
                            String(character!.skillCount))
                        ).font(.footnote)
                    }
                    Spacer()
                    HStack {
                        SkillInfo(url: skillInfo!["ai"].stringValue, level: skillInfo!["al"].stringValue)
                        SkillInfo(url: skillInfo!["si"].stringValue, level: skillInfo!["sl"].stringValue)
                        SkillInfo(url: skillInfo!["ei"].stringValue, level: skillInfo!["el"].stringValue)
                    }
                }.padding(.horizontal, 4)
            }.padding(2)//.background(.cyan.opacity(0.15))
        }.padding(16)
    }
}

private struct SkillInfo: View {
    let url: String
    let level: String
    
    var body: some View {
        VStack {
            KFImage(URL(string: url)!)
                .placeholder({ Image(systemName: "dot.radiowaves.left.and.right") })
                .loadDiskFileSynchronously()
                .resizable()
                .frame(width: 28, height: 28)
                .aspectRatio(contentMode: .fill)
                .background(.gray.opacity(0.5))
                .clipShape(Circle())
            Text(level)
        }
    }
}

#Preview {
    CharacterDetail(character: nil)
}
