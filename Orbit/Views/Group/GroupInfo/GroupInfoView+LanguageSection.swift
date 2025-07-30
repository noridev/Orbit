//
//  GroupInfoView+LanguageSection.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

extension GroupInfoView {
    func languageSection(languages: [String]) -> some View {
        GroupBox("Languages") {
            HStack(spacing: 8) {
                ForEach(currentGroup.languageTags) { languageTag in
                    Text(languageTag.description)
                        .font(.footnote.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.systemFill))
                        .cornerRadius(8)
                }
            }
        }
        .groupBoxStyle(.card)
    }
}
