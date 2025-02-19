//
//  Butttons.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/25.
//

import SwiftUI

struct StyledButton: View {
    let text: String
    let actions: () -> Void
    let colored: Bool
    
    init(text: String, actions: @escaping () -> Void, colored: Bool = false) {
        self.text = text
        self.actions = actions
        self.colored = colored
    }
    
    var body: some View {
        if colored {
            Button(
                action: actions,
                label: {
                    Text(NSLocalizedString(text, comment: ""))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                }
            ).buttonStyle(.borderedProminent)
        } else {
            Button(
                action: actions,
                label: {
                    Text(NSLocalizedString(text, comment: ""))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                }
            )
        }
    }
}
