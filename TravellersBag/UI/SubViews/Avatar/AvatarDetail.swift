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
    var properties: [AvatarProperty] = []
    var reliquaries: [AvatarReliquary] = []
    let getPropNameById: (String) -> String
    
    let column: [GridItem] = [
        .init(.flexible()), .init(.flexible()), .init(.flexible())
    ]
    
    @State private var showAvatarInfo: Bool = false
    @State private var showWeaponDetail: Bool = false
    
    init(intro: AvatarIntro, detail: JSON?, getPropNameById: @escaping (String) -> String) {
        self.intro = intro
        self.detail = detail
        self.getPropNameById = getPropNameById
        aditional = ResHandler.default.avatars.filter({ $0["Id"].intValue == intro.id }).first
        constellations.removeAll()
        skills.removeAll()
        properties.removeAll()
        reliquaries.removeAll()
        if detail != nil {
            for i in detail!["constellations"].arrayValue {
                var localImgPath: String? = nil
                if aditional != nil {
                    let useLocalImg = ResHandler.default.getImageWithNameAndType(
                        type: "Talent",
                        name: aditional!["SkillDepot"]["Talents"].arrayValue.filter( { $0["Id"].intValue == i["id"].intValue })
                            .first!["Icon"].stringValue)
                    if useLocalImg.useLocal {
                        localImgPath = useLocalImg.resPath
                    } else {
                        localImgPath = nil
                    }
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
                            let useLocalImg = ResHandler.default.getImageWithNameAndType(
                                type: "Skill",
                                name: name!)
                            if useLocalImg.useLocal {
                                localImgPath = useLocalImg.resPath
                            } else {
                                localImgPath = nil
                            }
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
            for i in detail!["selected_properties"].arrayValue {
                properties.append(
                    AvatarProperty(
                        id: i["property_type"].intValue, add: i["add"].stringValue, final: i["final"].stringValue, base: i["base"].stringValue,
                        name: getPropNameById(String(i["property_type"].intValue))
                    )
                )
            }
            for i in detail!["relics"].arrayValue {
                let midMainProp = i["main_property"]
                let mainProp = ReliquaryProp(times: midMainProp["times"].intValue, value: midMainProp["value"].stringValue, property_type: midMainProp["property_type"].intValue)
                var midSubPropList: [ReliquaryProp] = []
                for j in i["sub_property_list"].arrayValue {
                    midSubPropList.append(ReliquaryProp(times: j["times"].intValue, value: j["value"].stringValue, property_type: j["property_type"].intValue))
                }
                reliquaries.append(
                    AvatarReliquary(
                        id: i["id"].intValue, rarity: i["rarity"].intValue, name: i["name"].stringValue, level: i["level"].intValue,
                        icon: i["icon"].stringValue.replacingOccurrences(of: "\\", with: ""), setName: i["set"]["name"].stringValue,
                        mainProp: mainProp, subProps: midSubPropList,
                        localIcon: ResHandler.default.getReliquaryIcon(id: String(i["id"].intValue)).resPath
                    )
                )
            }
        }
    }
    
    var body: some View {
        if let _ = detail {
            ScrollView {
                BasicInfoPane
                VStack {
                    HStack {
                        Text("avatar.display.prop").font(.title3)
                        Spacer()
                        Button(action: {
                            withAnimation(.linear, { showAvatarInfo.toggle() })
                        }, label: {
                            Image(systemName: showAvatarInfo ? "arrow.up" : "arrow.down").font(.callout)
                        })
                    }
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                    if showAvatarInfo {
                        Form {
                            ForEach(properties) { prop in
                                HStack {
                                    Text(prop.name)
                                    Spacer()
                                    if prop.add == "" {
                                        Text(prop.final).foregroundStyle(.secondary)
                                    } else {
                                        HStack(spacing: 8, content: {
                                            Text(prop.final).foregroundStyle(.secondary)
                                            Text(prop.add).foregroundStyle(.green.opacity(0.8)).font(.callout)
                                        })
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .scrollDisabled(true).formStyle(.grouped)
                        .frame(maxWidth: .infinity)
                    }
                }
                LazyVGrid(columns: column, content: {
                    ForEach(reliquaries) { reliquary in
                        VStack {
                            HStack(spacing: 8, content: {
                                ZStack {
                                    switch reliquary.rarity {
                                    case 5:
                                        Image("UI_QUALITY_ORANGE").resizable().frame(width: 32, height: 32)
                                    case 4:
                                        Image("UI_QUALITY_PURPLE").resizable().frame(width: 32, height: 32)
                                    default:
                                        Image("UI_QUALITY_NONE").resizable().frame(width: 32, height: 32)
                                    }
                                    if let surelyLocal = reliquary.localIcon {
                                        if surelyLocal.hasPrefix("/") {
                                            Image(nsImage: NSImage(contentsOfFile: surelyLocal) ?? NSImage())
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                        } else {
                                            KFImage(URL(string: reliquary.icon))
                                                .loadDiskFileSynchronously(true)
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                }
                                VStack(alignment: .leading, content: {
                                    Text(reliquary.name)
                                    Text(reliquary.setName).font(.callout).foregroundStyle(.secondary)
                                })
                                Spacer()
                            })
                            Divider()
                            HStack {
                                Text(getPropNameById(String(reliquary.mainProp.property_type)))
                                Spacer()
                                Text(reliquary.mainProp.value)
                            }.padding(.bottom, 4)
                            ForEach(reliquary.subProps, id: \.property_type) { subProp in
                                HStack {
                                    Text(getPropNameById(String(subProp.property_type)))
                                    Spacer()
                                    Text(subProp.value)
                                    Image(systemName: "\(subProp.times + 1).circle")
                                }
                            }
                        }
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                    }
                })
            }
            .padding(8)
            .sheet(
                isPresented: $showWeaponDetail,
                content: {
                    WeaponSheet(
                        weaponDetail: detail?["weapon"], weaponIntro: intro.weapon, propName: { it in return getPropNameById(it) },
                        hide: { showWeaponDetail = false }
                    )
                }
            )
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
        let iconGroup = intro.icon
        let weaponGroup = intro.weapon.icon
        return VStack(alignment: .leading) {
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
                    if iconGroup.hasPrefix("/") {
                        Image(nsImage: NSImage(contentsOfFile: iconGroup) ?? NSImage())
                            .resizable()
                            .frame(width: 56, height: 56)
                    } else {
                        KFImage(URL(string: iconGroup))
                            .loadDiskFileSynchronously(true)
                            .resizable()
                            .frame(width: 56, height: 56)
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, content: {
                    Text(intro.name).font(.title3).bold()
                    Text(String.localizedStringWithFormat(NSLocalizedString("avatar.display.lv", comment: ""), String(intro.level)))
                    Text(String.localizedStringWithFormat(NSLocalizedString("avatar.display.fetter", comment: ""), String(intro.fetter)))
                })
                Spacer()
                HStack(spacing: 4, content: {
                    ForEach(skills) { skill in
                        SkillUnit(skill: skill)
                    }
                })
            })
            HStack(spacing: 8, content: {
                ForEach(constellations) { skill in
                    ConstellationUnit(skill: skill)
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
                    if weaponGroup.hasPrefix("/") {
                        Image(nsImage: NSImage(contentsOfFile: weaponGroup) ?? NSImage())
                            .resizable()
                            .frame(width: 56, height: 56)
                    } else {
                        KFImage(URL(string: weaponGroup))
                            .loadDiskFileSynchronously(true)
                            .resizable()
                            .frame(width: 56, height: 56)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    showWeaponDetail = true
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
            Text("avatar.display.detail").font(.footnote).foregroundStyle(.secondary).padding(.top, 2)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
    }
}
