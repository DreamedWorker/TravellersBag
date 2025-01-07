//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/17.
//

import SwiftUI

struct ContentView: View {
    @State private var welcomeSheetDisplay: Bool = false
    
    private func theFirstTime() -> String {
        if let version = UserDefaults.standard.string(forKey: "theFirstTime") {
            return version
        } else {
            return "0.0.0"
        }
    }
    
    init() {
        welcomeSheetDisplay = theFirstTime() != "0.0.3"
        print(welcomeSheetDisplay)
    }
    
    var body: some View {
        if welcomeSheetDisplay {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
            }
            .padding()
        } else {
            VStack {
                Image(systemName: "alarm").font(.title).bold()
                Text("def.holding").font(.title2).bold().padding(.top, 8)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
