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
                Text("app.name")
            }
        )
        .onAppear {
            part = destinationPart
        }
    }
}

enum Destinations: String {
    case Notice
}

#Preview {
    ContentView()
}
