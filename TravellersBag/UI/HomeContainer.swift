//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import SwiftUI
import MMKV

struct ContentView: View {
    @State private var showUI = false
    var body: some View {
        VStack {
            if showUI {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("app.name")
                Text(MMKV.default()!.string(forKey: LocalEnvironment.DEVICE_FP)!)
            } else {
                Text("home.container")
            }
        }
        .padding()
        .onAppear {
            Task {
                await LocalEnvironment.shared.checkFigurePointer()
                DispatchQueue.main.async {
                    showUI.toggle()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
