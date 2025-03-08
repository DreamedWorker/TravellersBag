//
//  HomeStageScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/6.
//

import SwiftUI

struct HomeStageScreen: View {
    @State private var uiPart: StagePart = .Account
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(selection: $uiPart) {
                    Text("stage.side.tip.account")
                        .font(.callout).bold()
                        .foregroundStyle(.secondary)
                    NavigationLink(value: StagePart.Account, label: { Label("stage.side.myAccount", systemImage: "person.circle") })
                }
            },
            detail: {
                switch uiPart {
                case .Account:
                    AccountMgrScreen()
                        .navigationTitle("stage.side.myAccount")
                }
            }
        )
    }
    
    enum StagePart {
        case Account
    }
}
