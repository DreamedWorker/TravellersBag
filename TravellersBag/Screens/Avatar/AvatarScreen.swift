//
//  AvatarScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/2.
//

import SwiftUI

struct AvatarScreen: View {
    @StateObject private var viewModel = AvatarModel.shared
    @State private var showContext = GlobalUIModel.exported.hasDefAccount()
    
    var body: some View {
        if GlobalUIModel.exported.hasDefAccount() {
            if viewModel.showUI {
                Text("app.name")
            } else {
                VStack {
                    Image("avatar_need_login").resizable().scaledToFit().frame(width: 72, height: 72).padding(.bottom, 8)
                    Text("avatar.no_data.title").font(.title2).bold()
                    Button("avatar.no_data.fetch", action: {}).buttonStyle(BorderedProminentButtonStyle())
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                .frame(minWidth: 400)
            }
        } else {
            VStack {
                Image("avatar_need_login").resizable().scaledToFit().frame(width: 72, height: 72).padding(.bottom, 8)
                Text("daily.no_account.title").font(.title2).bold()
                Button("gacha.login_first", action: {
                    GlobalUIModel.exported.refreshDefAccount()
                    showContext = GlobalUIModel.exported.hasDefAccount()
                }).buttonStyle(BorderedProminentButtonStyle())
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .frame(minWidth: 400)
        }
    }
}
