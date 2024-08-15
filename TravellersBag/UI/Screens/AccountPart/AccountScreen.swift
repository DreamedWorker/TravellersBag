//
//  AccountScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/16.
//

import SwiftUI

struct AccountScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                Form {
                    MDLikeTile(
                        leadingIcon: "qrcode",
                        endIcon: "arrow.forward",
                        title: NSLocalizedString("user.add.by_qr", comment: ""),
                        onClick: {}
                    )
                    NavigationLink(destination: {}, label: {Label("user.add.by_cookie", systemImage: "square.and.pencil")})
                }.scrollDisabled(false).formStyle(.grouped)
            }
        }.navigationTitle(Text("home.sider.account"))
    }
}

#Preview {
    AccountScreen()
}
