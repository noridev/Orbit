//
//  GroupDetailView+OwnerSection.swift
//  Orbit
//
//  Created by NoriDev on 7/17/25.
//

import SwiftUI
import VRCKit

extension GroupDetailView {
    var ownerSection: some View {
        GroupBox("그룹 소유자") {
            switch ownerUserState {
            case .loading:
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Loading...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text(currentGroup.ownerId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .redacted(reason: .placeholder)
            case .notFound:
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("사용자가 존재하지 않음")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        /*
                        Text(currentGroup.ownerId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                         */
                    }
                    Spacer()
                }
            case .loaded(let ownerUser):
                NavigationLink(destination: UserDetailPresentationView(id: ownerUser.id)) {
                    NavigationLabel {
                        HStack(spacing: 12) {
                            UserIcon(user: ownerUser, size: CGSize(width: 40, height: 40))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ownerUser.displayName)
                                    .font(.headline)
                                GroupOwnerStatusView(owner: ownerUser)
                            }
                        }
                    }
                }
            case .error:
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("불러오기 실패")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text(currentGroup.ownerId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .groupBoxStyle(.card)
    }
}
