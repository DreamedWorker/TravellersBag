//
//  AccountTile.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/16.
//

import SwiftUI
import Kingfisher

struct AccountTile: View {
    private let account: ShequAccount
    private let showSub: Bool
    private let refresh: () -> Void
    private let checkIn: () -> Void
    private let genshinPicUrl: String?
    
    init(
        account: ShequAccount,
        showSub: Bool = false,
        refresh: @escaping () -> Void,
        checkIn: @escaping () -> Void,
        genshinUrl: String = ""
    ) {
        self.account = account
        self.showSub = showSub
        self.refresh = refresh
        self.checkIn = checkIn
        self.genshinPicUrl = genshinUrl
    }
    
    var body: some View {
        HStack {
            if !showSub { // 如果需要显示帮助信息，则这个小条显示的内容是游戏角色，则不存在查看默认状态一说。
                Toggle(isOn: .constant(account.active), label: {
                    // Text("") //我咋没找到类似jetpack compose中的CheckBox呢？Apple!
                }).toggleStyle(.checkbox)
            }
            KFImage((!showSub) ? URL(string: account.shequHead ?? "") : URL(string: genshinPicUrl ?? ""))
                .placeholder({ Image(systemName: "dot.radiowaves.left.and.right") })
                .loadDiskFileSynchronously(true)
                .resizable()
                .frame(width: 32, height: 32)
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
                .padding(.trailing, 8)
            VStack {
                HStack {
                    if !showSub {
                        Text(account.shequNicname!).font(.headline)
                    } else {
                        Text(account.genshinNicname!).font(.headline)
                    }
                    Spacer()
                }
                if showSub {
                    HStack { //其实我感觉不用加？进行判空，因为只要出错都不会添加账号。
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("user.table_hk4e.single_helper", comment: ""),
                            account.serverName ?? "无服务器",
                            account.level ?? "0"
                        )).font(.footnote)
                        Spacer()
                    }
                }
            }
            Spacer()
            // Button("account.table_mishe.check_in", action: { checkIn() })
            // 这个按钮不再需要了 因为登录时已经自动处理了
            if !showSub { // 如果需要显示帮助信息，则这个小条显示的内容是游戏角色，则不存在删除一说。
                Button("user.table_mishe.use_default", action: {
                    LocalEnvironment.shared.setStringValue(key: "default_account_stuid", value: account.stuid!)
                    LocalEnvironment.shared.setStringValue(key: "default_account_stoken", value: account.stoken!)
                    LocalEnvironment.shared.setStringValue(key: "default_account_mid", value: account.mid!)
                })
                Button("user.table_mishe.delete", action: {
                    LocalEnvironment.shared.setStringValue(key: "default_account_stuid", value: "")
                    LocalEnvironment.shared.setStringValue(key: "default_account_stoken", value: "")
                    LocalEnvironment.shared.setStringValue(key: "default_account_mid", value: "")
                    removeSomeFile()
                    let acc = account
                    let _ = CoreDataHelper.shared.deleteUser(single: acc)
                    let _ = CoreDataHelper.shared.save()
                    HomeController.shared.currentUser = nil
                    refresh()
                })
            }
        }.padding(4)
    }
    
    /// 删除账号时删除一些相关文件
    private func removeSomeFile() {
        let user = HomeController.shared.currentUser!
        let enkaData = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "characters_from_enka-\(user.genshinUID!).json").path().removingPercentEncoding!
        let shequData = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "characters_from_shequ-\(user.genshinUID!).json").path().removingPercentEncoding!
        if FileManager.default.fileExists(atPath: enkaData){ try! FileManager.default.removeItem(atPath: enkaData) }
        if FileManager.default.fileExists(atPath: shequData){ try! FileManager.default.removeItem(atPath: shequData) }
    }
}
