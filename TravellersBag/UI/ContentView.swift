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
                    Text("home.sidePart.normal").bold()
                    NavigationLink(value: ContentPart.Account, label: { Label("home.sidebar.account", systemImage: "person.crop.circle") })
                    NavigationLink(value: ContentPart.Notice, label: { Label("home.sidebar.notice", systemImage: "bell.badge") })
                    Spacer()
                    Text("home.sidePart.functional").bold()
                    NavigationLink(
                        value: ContentPart.Dashboard,
                        label: { Label("home.sidebar.dashboard", systemImage: "gauge.with.dots.needle.33percent") }
                    )
                    NavigationLink(value: ContentPart.Character, label: { Label("home.sidebar.avatar", systemImage: "figure.wave")})
                    NavigationLink(value: ContentPart.DailyNote, label: { Label("home.sidebar.note", systemImage: "note.text") })
                    NavigationLink(value: ContentPart.Gacha, label: { Label("home.sidebar.gacha", systemImage: "gift") })
                    Spacer()
                    Text("home.sidePart.web").bold()
                    NavigationLink(value: ContentPart.Shequ, label: { Label("home.sidebar.shequ", systemImage: "flag.checkered") })
                    NavigationLink(
                        value: ContentPart.Adopt,
                        label: { Label("home.sidebar.adopt", systemImage: "person.crop.circle.badge.checkmark") }
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
                    DashboardView()
                case .DailyNote:
                    DailyNoteView()
                case .Shequ:
                    ShequIndexView().navigationTitle(Text("home.sidebar.shequ"))
                case .Adopt:
                    AdoptCalculator()
                case .Gacha:
                    GachaView()
                case .Character:
                    AvatarView()
                }
            }
        )
    }
    
    private enum ContentPart {
        case Account; case Notice; case Dashboard
        case DailyNote; case Shequ; case Adopt
        case Gacha; case Character
    }
}
