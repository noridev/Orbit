//
//  UserDetailView+OverlayViews.swift
//  Orbit
//
//  Created by makinosp on 2024/09/06.
//

import SwiftUI
import VRCKit

extension UserDetailView {
    var topOverlay: some View {
        HStack {
            Spacer()
            
            if !lastActivity.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch")
                    Text(lastActivity)
                }
                .font(.footnote.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .padding(12)
    }

    var statusDescription: String {
        if user.state == .offline {
            UserStatus.offline.description
        } else {
            user.statusDescription.isEmpty ? user.status.description : user.statusDescription
        }
    }
}
