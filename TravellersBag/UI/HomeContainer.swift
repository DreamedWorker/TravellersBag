//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import SwiftUI
import MMKV

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("app.name")
        }
        .padding()
        .onAppear {
        }
    }
}

#Preview {
    ContentView()
}
