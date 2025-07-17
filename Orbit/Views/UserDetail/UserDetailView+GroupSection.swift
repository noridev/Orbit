//
//  UserDetailView+GroupSection.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import SwiftUI
import VRCKit

extension UserDetailView {
    var groupSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink(destination: GroupListView(
                    userId: user.id,
                    userName: user.displayName,
                    groupService: appVM.services.groupService
                )) {
                    HStack {
                        Text("Groups")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        IconSet.forward.icon
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                GroupSectionContent(userId: user.id, groupService: appVM.services.groupService)
            }
            .redacted(reason: isRequesting ? .placeholder : [])
        }
        .groupBoxStyle(.card)
    }
}

struct GroupSectionContent: View {
    let userId: String
    let groupService: GroupServiceProtocol
    
    @ObservedObject private var groupViewModel = GroupViewModel.shared
    @State private var isLoading = true
    
    init(userId: String, groupService: GroupServiceProtocol) {
        self.userId = userId
        self.groupService = groupService
    }
    
    var body: some View {
        Group {
            if groupViewModel.hasGroups {
                VStack(alignment: .leading, spacing: 12) {
                    if !groupViewModel.representedGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text("Representing")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            ForEach(groupViewModel.representedGroups) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    NavigationLabel {
                                        GroupRowView(group: group, isRepresenting: false)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    if !groupViewModel.managedGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("관리 중")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            ForEach(groupViewModel.managedGroups.prefix(2)) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    NavigationLabel {
                                        GroupRowView(group: group, isRepresenting: false)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if groupViewModel.managedGroups.count > 2 {
                                HStack {
                                    Text("그 외 \(groupViewModel.managedGroups.count - 2)개")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("소속된 그룹")
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(groupViewModel.allGroups.count)개")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("그룹 정보를 불러올 수 없습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .redacted(reason: isLoading ? .placeholder : [])
        .task {
            isLoading = true
            groupViewModel.configure(groupService: groupService, userId: userId)
            await groupViewModel.loadUserGroups()
            isLoading = false
        }
    }
}

struct GroupSummaryRow: View {
    let title: String
    let groups: [VRCGroup]
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(groups.count)개")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    GroupSectionContent(
        userId: "usr_preview",
        groupService: GroupPreviewService(client: APIClient())
    )
    .padding()
}
