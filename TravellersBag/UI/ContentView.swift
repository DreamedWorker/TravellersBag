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
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
            .padding()
        }
    }
}
