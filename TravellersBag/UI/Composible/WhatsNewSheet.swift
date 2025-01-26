//
//  WhatsNewSheet.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/26.
//

import SwiftUI

struct WhatsNewSheet: View {
    let dismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("whats.title")
                    .font(.largeTitle).fontWeight(.black)
                Text("whats.exp")
                    .padding(.top, 1)
                    .font(.title3).foregroundStyle(.secondary)
                Spacer()
                VStack {
                    WhatsNewUnit(
                        imageName: "rectangle.inset.filled.and.person.filled",
                        title: "whats.n1.title",
                        exp: "whats.n1.exp"
                    )
                    WhatsNewUnit(
                        imageName: "app.badge.fill",
                        title: "whats.n2.title",
                        exp: "whats.n2.exp"
                    ).padding(.top, 8)
                    WhatsNewUnit(
                        imageName: "square.3.layers.3d.middle.filled",
                        title: "whats.n3.title",
                        exp: "whats.n3.exp"
                    ).padding(.top, 8)
                }
                Spacer()
                StyledButton(
                    text: "whats.ok",
                    actions: {
                        UserDefaults.standard.set("0.0.4", forKey: "lastUsedVersion")
                        UserDefaults.standard.synchronize()
                        dismiss()
                    },
                    colored: true
                )
            }
        }
        .padding(20)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 {
                    return nil
                } else {
                    return event
                }
            }
        }
    }
}

struct WhatsNewUnit: View {
    let imageName: String
    let title: String
    let exp: String
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
                .resizable().scaledToFit()
                .foregroundStyle(.accent)
                .frame(width: 70)
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString(title, comment: ""))
                    .font(.title2).bold()
                Text(NSLocalizedString(exp, comment: ""))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 250)
    }
}

#Preview {
    WhatsNewSheet(dismiss: {})
}
