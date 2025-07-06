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
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.regularMaterial)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    var bottomOverlay: some View {
        HStack(alignment: .bottom) {
            status
            Spacer()
            if user.ageVerification.ageVerificationStatusLabel != nil {
                VStack(alignment: .trailing) {
                    if user.vrcPlus.isSupporter {
                        vrcPlusLabel
                    }
                    HStack {
                        if let ageVerificationStatusLabel = user.ageVerification.ageVerificationStatusLabel {
                            ageVerificationLabel(text: ageVerificationStatusLabel, status: user.ageVerification.ageVerificationStatus)
                        }
                        trustRankLabel
                    }
                }
            } else {
                HStack {
                    if user.vrcPlus.isSupporter {
                        vrcPlusLabel
                    }
                    trustRankLabel
                }
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private var statusDescription: String {
        if user.state == .offline {
            UserStatus.offline.description
        } else {
            user.statusDescription.isEmpty ? user.status.description : user.statusDescription
        }
    }

    private var status: some View {
        Label {
            Text(statusDescription)
        } icon: {
            StatusIndicator(
                user.state != .offline ? user.status.color : UserStatus.offline.color,
                size: Constants.IconSize.userDetailIndicator,
                isCutOut: user.platform == .web
            )
        }
        .lineLimit(1)
        .font(.subheadline)
    }

    private var vrcPlusLabel: some View {
        HStack(spacing: 4) {
            IconSet.vrcplus.icon
            Text("VRC+")
        }
        .font(.footnote.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(user.vrcPlus.color.opacity(0.5))
        .background(.thinMaterial)
        .cornerRadius(8)
    }

    private func ageVerificationLabel(text: String, status: AgeVerificationStatus) -> some View {
        HStack(spacing: 4) {
            IconSet.ageVerification.icon
            Text(text)
        }
        .font(.footnote.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.5))
        .background(.thinMaterial)
        .cornerRadius(8)
    }

    private var trustRankLabel: some View {
        HStack(spacing: 4) {
            IconSet.shield.icon
            Text(user.trustRank.description)
        }
        .font(.footnote.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(user.trustRank.color.opacity(0.5))
        .background(.thinMaterial)
        .cornerRadius(8)
    }
}
