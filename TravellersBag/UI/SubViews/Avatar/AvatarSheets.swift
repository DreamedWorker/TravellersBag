//
//  AvatarSheets.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/4.
//

import SwiftUI
import SwiftyJSON
import Kingfisher

/// 角色武器详情表
struct WeaponSheet: View {
    let weaponDetail: JSON?
    let weaponIntro: AvatarEquipedWeapon?
    let weaponGroup: String?
    let propName: (String) -> String
    let hide: () -> Void
    
    init(weaponDetail: JSON?, weaponIntro: AvatarEquipedWeapon?, propName: @escaping (String) -> String, hide: @escaping () -> Void) {
        self.weaponDetail = weaponDetail
        self.weaponIntro = weaponIntro
        weaponGroup = weaponIntro?.icon
        self.propName = propName
        self.hide = hide
    }
    
    var body: some View {
        NavigationStack {
            if let weaponGroup = weaponGroup, let weaponIntro = weaponIntro, let weaponDetail = weaponDetail {
                Text(weaponIntro.name).font(.title).bold()
                VStack(alignment: .leading) {
                    HStack(spacing: 8, content: {
                        ZStack {
                            switch weaponIntro.rarity {
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
                        VStack(alignment: .leading, content: {
                            Text(weaponIntro.name).font(.title3).bold()
                            Text(String.localizedStringWithFormat(NSLocalizedString("avatar.display.lv", comment: ""), String(weaponIntro.level)))
                            Text(String.localizedStringWithFormat(
                                NSLocalizedString("avatar.display.affix_level", comment: ""), String(weaponIntro.affix_level))
                            )
                        })
                        Spacer()
                    })
                    Text(weaponDetail["desc"].stringValue).font(.callout).padding(.top, 4)
                }
                .padding(.vertical, 8)
                GroupBox("avatar.weapon.main_prop", content: {
                    HStack {
                        Text(propName(String(weaponDetail["main_property"]["property_type"].intValue)))
                        Spacer()
                        Text(weaponDetail["main_property"]["final"].stringValue).foregroundStyle(.secondary)
                    }.padding(4)
                }).padding(.bottom, 4)
                GroupBox("avatar.weapon.sub_prop", content: {
                    HStack {
                        Text(propName(String(weaponDetail["sub_property"]["property_type"].intValue)))
                        Spacer()
                        Text(weaponDetail["sub_property"]["final"].stringValue).foregroundStyle(.secondary)
                    }.padding(4)
                }).padding(.bottom, 2)
            } else {
                Image(systemName: "exclamationmark.octagon")
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button("def.confirm", action: hide)
            })
        }
    }
}

/// 角色命座详情表
struct ConstellationSheet: View {
    var single: Constellation?
    let hide: () -> Void
    
    init(single: Constellation?, hide: @escaping () -> Void) {
        self.single = single
        self.hide = hide
    }
    
    var body: some View {
        NavigationStack {
            if let single = single {
                Text(single.name).font(.title).bold()
                VStack(alignment: .leading) {
                    Form {
                        HStack {
                            Text("avatar.constellation.active")
                            Spacer()
                            Text((single.is_actived) ? "app.yes" : "app.no").foregroundStyle(.secondary)
                        }
                    }.scrollDisabled(true).formStyle(.grouped).padding(.bottom, 4)
                    ScrollView {
                        Text(AttributedString(colorfulString(from: single.effect.replacingOccurrences(of: "\\n", with: "\n"))))
                    }.padding(.top, 8)
                }
            } else {
                Image(systemName: "exclamationmark.octagon")
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button("def.confirm", action: hide)
            })
        }
    }
}

struct SkillSheet: View {
    let skill: AvatarSkill
    let hide: () -> Void
    
    init(skill: AvatarSkill, hide: @escaping () -> Void) {
        self.skill = skill
        self.hide = hide
    }
    
    var body: some View {
        NavigationStack {
            Text(skill.name).font(.title).bold()
            ScrollView {
                GroupBox("avatar.skill.info", content: {
                    ForEach(skill.skill_affix_list, id: \.name) { affix in
                        HStack {
                            Text(affix.name)
                            Spacer()
                            Text(affix.value).foregroundStyle(.secondary)
                        }
                        .padding(2)
                    }
                })
                VStack(alignment: .leading, content: {
                    HStack {
                        Text(
                            AttributedString(
                                colorfulString(
                                    from: String(skill.desc.replacingOccurrences(of: "\\n", with: "\n").split(separator: "<i>")[0])
                                )
                            )
                        ).padding(2)
                        Spacer()
                    }
                    if !skill.name.contains("普通攻击") {
                        HStack {
                            Text(String(skill.desc.split(separator: "<i>")[1]).replacingOccurrences(of: "</i>", with: ""))
                                .foregroundStyle(.secondary)
                                .italic()
                            Spacer()
                        }
                    }
                })
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button("def.confirm", action: hide)
            })
        }
    }
}
