//
//  UserDetailView+BadgeSection.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import SwiftUI
import VRCKit

extension UserDetailView {
    func badgeSection(badges: [Badge], isMe: Bool) -> some View {
        GroupBox("Badges") {
            BadgeListView(badges: badges, isMe: isMe)
        }
        .groupBoxStyle(.card)
    }
}
