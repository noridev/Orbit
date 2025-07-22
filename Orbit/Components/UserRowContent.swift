//
//  UserRowContent.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

struct UserRowContent<T: ProfileElementRepresentable>: View {
    let user: T
    let showOwnerStatus: Bool
    let ownerStatusView: AnyView?
    let showFriendStatus: Bool
    let friendStatusView: AnyView?
    let joinedAt: Date?
    let roles: [String]?
    let isManager: Bool
    let isLoading: Bool
    let iconSize: CGSize

    init(
        user: T,
        showOwnerStatus: Bool = false,
        ownerStatusView: AnyView? = nil,
        showFriendStatus: Bool = false,
        friendStatusView: AnyView? = nil,
        joinedAt: Date? = nil,
        roles: [String]? = nil,
        isManager: Bool = false,
        isLoading: Bool = false,
        iconSize: CGSize = CGSize(width: 40, height: 40)
    ) {
        self.user = user
        self.showOwnerStatus = showOwnerStatus
        self.ownerStatusView = ownerStatusView
        self.showFriendStatus = showFriendStatus
        self.friendStatusView = friendStatusView
        self.joinedAt = joinedAt
        self.roles = roles
        self.isManager = isManager
        self.isLoading = isLoading
        self.iconSize = iconSize
    }

    var body: some View {
        HStack(spacing: 12) {
            UserIcon(user: user, size: iconSize)
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if showOwnerStatus, let ownerStatusView = ownerStatusView {
                    ownerStatusView
                }
                
                if showFriendStatus, let friendStatusView = friendStatusView {
                    friendStatusView
                }
                
                if let joinedAt = joinedAt {
                    HStack(spacing: 4) {
                        IconSet.calendar.icon
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(isLoading ? "가입일: YYYY.MM.DD" : "가입일: \(joinedAt, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let roles = roles, !roles.isEmpty {
                    HStack(spacing: 6) {
                        Text(isLoading ? "Role Name" : roles.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(isManager ? .blue : .primary)
                        
                        if isManager {
                            Image(systemName: IconSet.shield.systemName)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule()).lineLimit(1)
                }
            }
        }
    }
}
