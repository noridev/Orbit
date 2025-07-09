//
//  UserDetailView+BioSection.swift
//  Orbit
//
//  Created by makinosp on 2024/09/06.
//

import SwiftUI
import VRCKit

extension UserDetailView {
    func bioSection(_ bio: String?) -> some View {
        GroupBox("Profile") {
            if let bio = bio, !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ShowMoreText(bio, lineLimit: 5)
                    .font(.body)
            } else {
                Text("No bio added")
                    .foregroundStyle(.gray)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .groupBoxStyle(.card)
    }
}
