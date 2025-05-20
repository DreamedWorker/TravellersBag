//
//  AccountCapsule.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/18.
//

import SwiftUI
import Kingfisher

struct AccountCapsule: View {
    private let des: ContentView.StagePart
    private var account: HoyoAccount? = nil
    
    init(des: ContentView.StagePart, account: HoyoAccount? = nil) {
        self.des = des
        self.account = account
    }
    
    var body: some View {
        NavigationLink(
            value: des,
            label: {
                HStack(spacing: 8) {
                    if let user = account {
                        KFImage.url(URL(string: user.bbsHeadImg))
                            .loadDiskFileSynchronously(true)
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 36, height: 36)
                    }
                    VStack(alignment: .leading) {
                        if let user = account {
                            Text(user.bbsNicname)
                                .font(.title3).bold()
                        } else {
                            Text("stage.side.account.needLogin")
                                .font(.title3).bold()
                        }
                        Text("stage.side.account")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        )
    }
}
