//
//  UserDetailView+BioSection.swift
//  Orbit
//
//  Created by makinosp on 2024/09/06.
//

import SwiftUI
import VRCKit

extension UserDetailView {
    func bioSection(_ bio: String?, proxy: ScrollViewProxy) -> some View {
        GroupBox("Profile") {
            if let bio = bio, !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ShowMoreText(text: bio, lineLimit: 5)
                    .font(.body)
            } else {
                Text("소개가 없습니다")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .groupBoxStyle(.card)
        .id("bio")
    }
}
