//
//  GroupInfoView+MembershipSection.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

extension GroupInfoView {
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
            
            if let roles = currentGroup.roles {
                let memberRoles = roles.filter { role in
                    member.roleIds.contains(role.id)
                }
                
                if !memberRoles.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(memberRoles, id: \.id) { role in
                            Text(role.name)
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                    }
                } else {
                    Text("역할 없음")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("역할 정보 없음")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var noMembershipInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            infoRow(title: "가입일", value: "정보 없음")
            infoRow(title: "내 역할", value: "정보 없음")
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
}
