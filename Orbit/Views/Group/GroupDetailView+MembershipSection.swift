//
//  GroupDetailView+MembershipSection.swift
//  Orbit
//
//  Created by NoriDev on 7/17/25.
//

import SwiftUI
import VRCKit

extension GroupDetailView {
    func membershipSection(isLoading: Bool) -> some View {
        GroupBox("가입 정보") {
            if isLoading {
                membershipPlaceholderView
                    .redacted(reason: .placeholder)
            } else if let myMember = currentGroup.myMember {
                membershipContentView(for: myMember)
            } else {
                noMembershipInfoView
            }
        }
        .groupBoxStyle(.card)
    }
    
    private func membershipContentView(for member: GroupMembership) -> some View {
        DividedVStack(alignment: .leading, spacing: 8) {
            joinedDateView(from: member.joinedAt)
            rolesView(for: member)
        }
    }
    
    private var membershipPlaceholderView: some View {
        DividedVStack(alignment: .leading, spacing: 8) {
            infoRow(title: "가입일", value: "MM/DD/YYYY, hh:mm")
            infoRow(title: "내 역할", value: "역할 이름")
        }
    }
    
    private func joinedDateView(from joinedAt: Date?) -> some View {
        VStack(alignment: .leading) {
            Text("가입일")
                .font(.caption)
                .foregroundStyle(.gray)
            
            if let date = joinedAt {
                Text(date.formatted(date: .numeric, time: .shortened))
                    .font(.callout)
            } else {
                Text("정보 없음")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func rolesView(for member: GroupMembership) -> some View {
        VStack(alignment: .leading) {
            Text("내 역할")
                .font(.caption)
                .foregroundStyle(.gray)
            
            let userRoles = filterUserRoles(for: member)
            
            if userRoles.isEmpty {
                Text("역할 없음")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(userRoles) { role in
                        roleItemView(for: role)
                    }
                }
            }
        }
    }
    
    private func roleItemView(for role: GroupRole) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(role.name)
                    .font(.callout)
                    .foregroundStyle(role.isManagementRole ? .blue : .primary)
                
                if role.isManagementRole {
                    Image(systemName: IconSet.shield.systemName)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            
            if let description = role.description, !description.isEmpty {
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var noMembershipInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            infoRow(title: "가입일", value: "정보 없음")
            infoRow(title: "내 역할", value: "역할 없음")
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
    
    private func filterUserRoles(for member: GroupMembership) -> [GroupRole] {
        guard let allRoles = currentGroup.roles, !member.roleIds.isEmpty else {
            return []
        }
        
        let roleIdSet = Set(member.roleIds)
        return allRoles.filter { roleIdSet.contains($0.id) }
    }
}
