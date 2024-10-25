//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/24.
//

import SwiftUI

struct ContentView: View {
    let needShowWizard: Bool
    
    var body: some View {
        if needShowWizard {
            WizardPane()
        } else {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                if needShowWizard {
                    Text("app.name")
                } else {
                    Text("Hello, world!")
                }
            }
            .padding()
        }
    }
}

#if DEBUG
#Preview {
    ContentView(needShowWizard: true)
}
#endif
