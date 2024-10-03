//
//  AvatarDetail.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/3.
//

import SwiftUI
import SwiftyJSON
import Kingfisher

struct AvatarDetail: View {
    let intro: AvatarIntro
    let detail: JSON?
    let aditional: JSON?
    var constellations: [Constellation] = []
    var skills: [AvatarSkill] = []
    
    init(intro: AvatarIntro, detail: JSON?) {
        self.intro = intro
        self.detail = detail
        aditional = HoyoResKit.default.avatars.filter({ $0["Id"].intValue == intro.id }).first
        constellations.removeAll()
        skills.removeAll()
        if detail != nil {
            for i in detail!["constellations"].arrayValue {
                var localImgPath: String? = nil
                if aditional != nil {
                    let useLocalImg = HoyoResKit.default.getImageWithNameAndType(
                        type: "Talent",
                        name: aditional!["SkillDepot"]["Talents"].arrayValue.filter( { $0["Id"].intValue == i["id"].intValue })
                            .first!["Icon"].stringValue).split(separator: "@")
                    if String(useLocalImg[0]) == "L" {
                        localImgPath = String(useLocalImg[1])
                    } else { localImgPath = nil }
                }
                constellations.append(
                    Constellation(
                        id: i["id"].intValue, name: i["name"].stringValue, icon: i["icon"].stringValue.replacingOccurrences(of: "\\", with: ""),
                        localIcon: (aditional != nil) ? localImgPath : nil, is_actived: i["is_actived"].boolValue, effect: i["effect"].stringValue
                    )
                )
            }
            for i in detail!["skills"].arrayValue {
                if i["skill_type"].intValue != 1 {
                    continue
                } else {
                    var localImgPath: String? = nil
                    var affixes: [SkillAffixList] = []
                    for j in i["skill_affix_list"].arrayValue {
                        affixes.append(SkillAffixList(name: j["name"].stringValue, value: j["value"].stringValue))
                    }
                    if aditional != nil {
                        var name = aditional!["SkillDepot"]["Skills"].arrayValue.filter({ $0["Id"].intValue == i["skill_id"].intValue })
                            .first?["Icon"].stringValue
                        if name == nil {
                            name = aditional!["SkillDepot"]["EnergySkill"]["Icon"].string
                        }
                        if name != nil {
                            let useLocalImg = HoyoResKit.default.getImageWithNameAndType(
                                type: "Talent",
                                name: name!).split(separator: "@")
                            if String(useLocalImg[0]) == "L" {
                                localImgPath = String(useLocalImg[1])
                            } else { localImgPath = nil }
                        } else {
                            localImgPath = nil
                        }
                    }
                    skills.append(
                        AvatarSkill(
                            id: i["skill_id"].intValue, level: i["level"].intValue, icon: i["icon"].stringValue,
                            localIcon: (aditional != nil) ? localImgPath : nil,skill_affix_list: affixes, skill_type: 1,
                            name: i["name"].stringValue, desc: i["desc"].stringValue
                        )
                    )
                }
            }
        }
    }
    
    var body: some View {
        if let surely = detail {
            BasicInfoPane
            ScrollView {}
        } else {
            VStack {
                Image("avatar_need_login").resizable().scaledToFit().frame(width: 72, height: 72).padding(.bottom, 8)
                Text("avatar.detail.no_avatar")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .frame(minWidth: 400)
        }
    }
    
    var BasicInfoPane: some View {
        let iconGroup = intro.icon.split(separator: "@")
        let weaponGroup = intro.weapon.icon.split(separator: "@")
        return VStack {
            HStack(spacing: 8, content: {
                ZStack {
                    switch intro.rarity {
                    case 5:
                        Image("UI_QUALITY_ORANGE").resizable().frame(width: 56, height: 56)
                    case 4:
                        Image("UI_QUALITY_PURPLE").resizable().frame(width: 56, height: 56)
                    default:
                        Image("UI_QUALITY_NONE").resizable().frame(width: 56, height: 56)
                    }
                    if String(iconGroup[0]) == "C" {
                        KFImage(URL(string: String(iconGroup[1])))
                            .loadDiskFileSynchronously(true)
                            .resizable()
                            .frame(width: 56, height: 56)
                    } else {
                        Image(nsImage: NSImage(contentsOfFile: String(iconGroup[1])) ?? NSImage())
                            .resizable()
                            .frame(width: 56, height: 56)
                    }
                }
                VStack(alignment: .leading, content: {
                    Text(intro.name).font(.title3).bold()
                    Text(String.localizedStringWithFormat(NSLocalizedString("avatar.display.lv", comment: ""), String(intro.level)))
                    Text(String.localizedStringWithFormat(NSLocalizedString("avatar.display.fetter", comment: ""), String(intro.fetter)))
                })
                Spacer()
                HStack(spacing: 4, content: {
                    ForEach(skills) { skill in
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
                    }
                })
            })
            HStack(spacing: 8, content: {
                ForEach(constellations) { skill in
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
                }
                Spacer()
            })
            Divider()
            HStack(spacing: 8, content: {
                ZStack {
                    switch intro.weapon.rarity {
                    case 5:
                        Image("UI_QUALITY_ORANGE").resizable().frame(width: 56, height: 56)
                    case 4:
                        Image("UI_QUALITY_PURPLE").resizable().frame(width: 56, height: 56)
                    default:
                        Image("UI_QUALITY_NONE").resizable().frame(width: 56, height: 56)
                    }
                    if String(weaponGroup[0]) == "C" {
                        KFImage(URL(string: String(weaponGroup[1])))
                            .loadDiskFileSynchronously(true)
                            .resizable()
                            .frame(width: 56, height: 56)
                    } else {
                        Image(nsImage: NSImage(contentsOfFile: String(weaponGroup[1])) ?? NSImage())
                            .resizable()
                            .frame(width: 56, height: 56)
                    }
                }
                VStack(alignment: .leading, content: {
                    Text(intro.weapon.name).font(.title3).bold()
                    Text(String.localizedStringWithFormat(NSLocalizedString("avatar.display.lv", comment: ""), String(intro.weapon.level)))
                    Text(String.localizedStringWithFormat(
                        NSLocalizedString("avatar.display.affix_level", comment: ""), String(intro.weapon.affix_level))
                    )
                })
                Spacer()
            })
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
    }
}
