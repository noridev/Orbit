//
//  GroupInfoView+InfoSection.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

extension GroupInfoView {
    func infoSection(members: [GroupMembership]?, isLoading: Bool) -> some View {
        GroupBox("그룹 정보") {
            DividedVStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading) {
                    Text("멤버")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    Text(memberInGroupCount(members: members))
                        .font(.callout)
                }
                
                if friendsInGroupCount(members: members) != 0 {
                    VStack(alignment: .leading) {
                        Text("친구인 멤버")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Text("\(friendsInGroupCount(members: members))")
                            .font(.callout)
                    }
                }
                
                if let lastPostCreatedAt = currentGroup.lastPostCreatedAt {
                    VStack(alignment: .leading) {
                        Text("마지막 포스트")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Text(lastPostCreatedAt.formatted(date: .numeric, time: .shortened))
                            .font(.callout)
                    }
                }
                
                if let createdAt = currentGroup.createdAt {
                    VStack(alignment: .leading) {
                        Text("생성일")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Text(createdAt.formatted(date: .numeric, time: .shortened))
                            .font(.callout)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("그룹 ID")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    Text(currentGroup.actualGroupId)
                        .font(.callout)
                        .textSelection(.enabled)
                }
                
                if let url = URL(string: "https://vrc.group/\(currentGroup.shortCode).\(currentGroup.discriminator)") {
                    VStack(alignment: .leading) {
                        Text("그룹 URL")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Text(url.absoluteString)
                            .font(.callout)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .groupBoxStyle(.card)
        .redacted(reason: isLoading ? .placeholder : [])
    }
    
    private func memberInGroupCount(members: [GroupMembership]?) -> String {
        let onlineCount = currentGroup.onlineMemberCount ?? 0
        
        if onlineCount == 0 {
            return "\(currentGroup.memberCount)"
        } else {
            return "\(currentGroup.memberCount) (\(onlineCount))"
        }
    }
    
    private func friendsInGroupCount(members: [GroupMembership]?) -> Int {
        let allFriends = friendVM.allFriends
        
        if let memberships = members {
            let memberUserIds = Set(memberships.map { $0.userId })
            let friendIds = Set(allFriends.map { $0.id })
            return memberUserIds.intersection(friendIds).count
        }
        
        return 0
    }
}
