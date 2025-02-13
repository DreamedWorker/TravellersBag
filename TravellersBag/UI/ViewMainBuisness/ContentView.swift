//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("defaultPart") var destinationPart: Destinations = .Notice
    @State private var part: Destinations = .Notice
    
    enum Destinations: String {
        case Notice
    }
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(selection: $part) {
                    Text("router.tag.general")
                        .font(.callout).bold()
                        .foregroundStyle(.secondary)
                    NavigationLink(
                        value: Destinations.Notice,
                        label: { Label("router.notice", systemImage: "list.bullet.rectangle.portrait") }
                    )
                }
            },
            detail: {
                switch part {
                case .Notice:
                    NoticeView()
                }
            }
        )
        .onAppear {
            part = destinationPart
        }
    }
}

#Preview {
    ContentView()
}
