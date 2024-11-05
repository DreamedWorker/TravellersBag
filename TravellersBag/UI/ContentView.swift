//
//  ContentView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2024/10/26.
//

import SwiftUI

struct ContentView: View {
    let needShowWizard: Bool
    
    var body: some View {
        if needShowWizard {
            WizardPane()
        } else {
            ContentPane()
        }
    }
}

struct ContentPane: View {
    @StateObject private var model = ContentPaneControl()
    @State var panePart: ContentPart = .Account
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(
                    selection: $panePart,
                    content: {
                        NavigationLink(value: ContentPart.Account, label: { Label("home.sidebar.account", systemImage: "person.crop.circle") })
                        NavigationLink(value: ContentPart.Notice, label: { Label("home.sidebar.notice", systemImage: "bell.badge") })
                    }
                )
            },
            detail: {
                switch panePart {
                case .Account:
                    AccountScreen()
                case .Notice:
                    Text("app.confirm")
                }
            }
        )
    }
}

class ContentPaneControl: ObservableObject {
}

enum ContentPart {
    case Account; case Notice;
}
