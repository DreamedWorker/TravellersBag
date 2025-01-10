//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/17.
//

import SwiftUI

struct ContentView: View {
    
    @State private var panePart: ContentPart = .Notice
    
    init() {
    }
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(selection: $panePart) {
                    NavigationLink(value: ContentPart.Account, label: { Label("home.sidebar.account", systemImage: "person.crop.circle") })
                    NavigationLink(value: ContentPart.Notice, label: { Label("home.sidebar.notice", systemImage: "bell.badge") })
                    NavigationLink(
                        value: ContentPart.Dashboard,
                        label: { Label("home.sidebar.dashboard", systemImage: "gauge.with.dots.needle.33percent") }
                    )
                }
            },
            detail: {
                switch panePart {
                case .Account:
                    AccountView()
                case .Notice:
                    NoticeView()
                case .Dashboard:
                    Text("app.name")
                }
            }
        )
    }
    
    private enum ContentPart {
        case Account; case Notice; case Dashboard
    }
}
