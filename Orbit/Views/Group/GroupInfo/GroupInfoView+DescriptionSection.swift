//
//  GroupInfoView+DescriptionSection.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

extension GroupInfoView {
    func descriptionSection(_ description: String?, isLoading: Bool) -> some View {
        GroupBox("설명") {
            if isLoading {
                Text("설명이 없습니다")
                    .font(.body)
                    .redacted(reason: .placeholder)
            } else {
                if let desc = description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ShowMoreText(text: desc, lineLimit: 3)
                        .font(.body)
                } else {
                    Text("설명이 없습니다")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .groupBoxStyle(.card)
    }
}
