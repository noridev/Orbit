//
//  GroupDetailView+RulesSection.swift
//  Orbit
//
//  Created by NoriDev on 7/17/25.
//

import SwiftUI
import VRCKit

extension GroupDetailView {
    func rulesSection(_ rules: String?, isLoading: Bool) -> some View {
        GroupBox("규칙") {
            if isLoading {
                Text("규칙이 없습니다")
                    .font(.body)
                    .redacted(reason: .placeholder)
            } else {
                if let rulesText = rules, !rulesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ShowMoreText(text: rulesText, lineLimit: 3)
                        .font(.body)
                } else {
                    Text("규칙이 없습니다")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .groupBoxStyle(.card)
    }
} 
