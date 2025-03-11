//
//  AccountMgrScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/7.
//

import SwiftUI
import SwiftData
import Kingfisher

// MARK: - 页面
struct AccountMgrScreen: View {
    @Query(sort: \MihoyoAccount.misheNicname) private var users: [MihoyoAccount]
    @State private var selectedUser: MihoyoAccount?
    @Environment(\.modelContext) private var dao
    @StateObject private var service = AccountMgrModel()
    @State private var showLoginWin: Bool = false
    
    var body: some View {
        HSplitView {
            List(selection: $selectedUser) {
                if !users.isEmpty {
                    ForEach(users) { user in
                        UserRow(user: user)
                            .tag(user)
                            .contextMenu {
                                Button(
                                    "account.action.logOut", role: .destructive,
                                    action: {
                                        let requiredUser = user
                                        selectedUser = nil
                                        dao.delete(requiredUser)
                                        try! dao.save()
                                        if users.count == 0 {
                                            NSApplication.shared.terminate(self)
                                        } else {
                                            if requiredUser.active {
                                                let neoAccount = users.first!
                                                neoAccount.active = true
                                                try! dao.save()
                                                service.alertMate.showAlert(msg: NSLocalizedString("account.tip.reDef", comment: ""))
                                            }
                                        }
                                    }
                                )
                            }
                            .listRowSeparator(.hidden)
                    }
                } else {
                    ContentUnavailableView("account.error.noLoggedInUsers", systemImage: "person.2")
                }
            }
            .frame(minWidth: 150, maxWidth: 170, maxHeight: .infinity)
            UserDetailView(
                user: selectedUser,
                deleteUser: {
                    let requiredUser = selectedUser!
                    selectedUser = nil
                    dao.delete(requiredUser)
                    try! dao.save()
                    if users.count == 0 {
                        NSApplication.shared.terminate(self)
                    } else {
                        if requiredUser.active {
                            let neoAccount = users.first!
                            neoAccount.active = true
                            try! dao.save()
                            service.alertMate.showAlert(msg: NSLocalizedString("account.tip.reDef", comment: ""))
                        }
                    }
                },
                copyCookies: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("stuid=\(selectedUser!.cookies.stuid);stoken=\(selectedUser!.cookies.stoken);mid=\(selectedUser!.cookies.mid)", forType: .string)
                    service.alertMate.showAlert(msg: NSLocalizedString("def.finished", comment: ""))
                },
                checkUser: {
                    if FakeDeviceEnv.checkFp(fp: PreferenceMgr.default.getValue(key: TBData.DEVICE_FP, def: "")) {
                        Task {
                            let neoAccount = await service.checkAccountState(account: selectedUser!)
                            if let checked = neoAccount {
                                selectedUser = nil
                                let inListAccount = users.first(where: { $0.stuidForTest == checked.stuidForTest })!
                                dao.delete(inListAccount); dao.insert(checked)
                                try! dao.save()
                            }
                        }
                    } else {
                        service.alertMate.showAlert(msg: NSLocalizedString("account.error.fp", comment: ""), type: .Error)
                    }
                }
            ).frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    "account.action.login", systemImage: "plus",
                    action: {
                        Task {
                            do {
                                let url = try await service.fetchQRCode()
                                if let confirmCode = service.generateQRCode(from: url) {
                                    DispatchQueue.main.async { [self] in
                                        service.loginQRCode = confirmCode
                                        service.picURL = url
                                        showLoginWin = true
                                    }
                                }
                            } catch {
                                service.alertMate.showAlert(msg: String.localizedStringWithFormat(NSLocalizedString("account.error.cannotCreateQRCode", comment: ""), error.localizedDescription), type: .Error)
                            }
                        }
                    }
                ).help("account.action.login")
            }
        }
        .sheet(isPresented: $showLoginWin, content: {
            QRCodeSigning(
                qrcode: service.loginQRCode!, cancelAction: { showLoginWin = false },
                confirmAction: {
                    Task {
                        let data = await service.queryStatusAndLogin(
                            hasSame: { uid in return users.contains(where: { $0.stuidForTest == uid })},
                            counts: users.count,
                            dismiss: { showLoginWin = false }
                        )
                        DispatchQueue.main.async {
                            if let account = data {
                                self.dao.insert(account); try? self.dao.save()
                            }
                            self.showLoginWin = false; self.service.loginQRCode = nil
                        }
                    }
                }
            )
        })
        .alert(
            (service.alertMate.type == .Error) ? NSLocalizedString("def.warning", comment: "")
            : NSLocalizedString("def.info", comment: ""),
            isPresented: $service.alertMate.showIt, actions: {},
            message: { Text(service.alertMate.msg)}
        )
    }
}

// MARK: - 二维码登录窗口
extension AccountMgrScreen {
    struct QRCodeSigning: View {
        let qrcode: NSImage
        let cancelAction: () -> Void
        let confirmAction: () -> Void
        
        var body: some View {
            NavigationStack {
                Text("account.win.title")
                    .font(.title).bold()
                    .padding(.bottom, 8)
                Image(nsImage: qrcode)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 98, height: 98)
                Spacer()
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .resizable()
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(.accent)
                    .frame(width: 18, height: 18)
                Text("account.win.tip")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.keyCode == 53 {
                        return nil
                    } else {
                        return event
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("def.cancel", action: cancelAction)
                })
                ToolbarItem(placement: .confirmationAction, content: {
                    Button("def.confirm", action: confirmAction)
                })
            }
        }
    }
}

// MARK: - 用户列表单元
extension AccountMgrScreen {
    struct UserRow: View {
        let user: MihoyoAccount
        
        var body: some View {
            HStack(spacing: 16) {
                KFImage.url(URL(string: user.misheHead))
                    .loadDiskFileSynchronously(true)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 32, height: 32)
                Text(user.misheNicname).bold()
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 用户细节面板
extension AccountMgrScreen {
    struct UserDetailView: View {
        let user: MihoyoAccount?
        let deleteUser: () -> Void
        let copyCookies: () -> Void
        let checkUser: () -> Void
        
        @State private var showDelete: Bool = false
        
        @ViewBuilder
        var body: some View {
            if let user = user {
                VStack {
                    HStack(spacing: 16) {
                        KFImage.url(URL(string: user.misheHead)) // 社区头像
                            .loadDiskFileSynchronously(true)
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 120, height: 120)
                        if let nsImage = ResourceMgr.shared.getProfilePicture(picID: user.gameInfo.genshinPicID) {
                            Image(nsImage: nsImage) // 游戏角色头像 如果没有本地图片则不显示
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .frame(width: 120, height: 120)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Form {
                            DetailRow(title: "account.info.avatarName", value: user.gameInfo.genshinNicname)
                            DetailRow(title: "account.info.avatarUID", value: user.gameInfo.genshinUID)
                            DetailRow(title: "account.info.level", value: user.gameInfo.level)
                            DetailRow(title: "account.info.stoken", value: user.cookies.stoken, click2display: true)
                        }
                        .formStyle(.grouped)
                        //.scrollDisabled(true)
                        Form {
                            Button(action: checkUser, label: { ActionRow(actionName: "account.action.checkAccessible", actionIcon: "person.fill.checkmark") })
                                .buttonStyle(.borderless)
                            Button(action: copyCookies, label: { ActionRow(actionName: "account.action.copyCookies", actionIcon: "doc.on.doc") })
                                .buttonStyle(.borderless)
                            Button(action: { showDelete = true }, label: { ActionRow(actionName: "account.action.delete", actionIcon: "trash")} )
                                .buttonStyle(.borderless)
                        }
                        .formStyle(.grouped)
                        .scrollDisabled(true)
                    }
                }
                .padding(20)
                .alert(
                    "def.warning", isPresented: $showDelete,
                    actions: {
                        Button("def.confirm", role: .destructive, action: deleteUser)
                    },
                    message: { Text("account.tip.delete") }
                )
            } else {
                ContentUnavailableView("account.error.noSelectedUser", systemImage: "person.crop.circle")
            }
        }
    }
    
    struct DetailRow: View {
        let title: String
        let value: String
        var click2display: Bool
        
        @State private var show: Bool = false
        
        init(title: String, value: String, click2display: Bool = false) {
            self.title = title
            self.value = value
            self.click2display = click2display
        }
        
        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Text(NSLocalizedString(title, comment: ""))
                Spacer()
                if !click2display {
                    Text(value)
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                } else {
                    Text(show ? value : NSLocalizedString("account.action.clickToDisplay", comment: ""))
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                            show.toggle()
                        }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    struct ActionRow: View {
        let actionName: String
        let actionIcon: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: actionIcon)
                    .foregroundStyle(.accent)
                Text(NSLocalizedString(actionName, comment: ""))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
