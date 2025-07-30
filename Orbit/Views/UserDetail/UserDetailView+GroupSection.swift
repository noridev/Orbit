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
    let groupService: GroupProvidable
    
    @ObservedObject private var groupViewModel = GroupViewModel.shared
    @State private var isLoading = true
    
    init(userId: String, groupService: GroupProvidable) {
        self.userId = userId
        self.groupService = groupService
    }
    
    var body: some View {
        Group {
            if groupViewModel.error != nil {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("그룹 정보를 불러올 수 없습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if groupViewModel.hasGroups {
                VStack(alignment: .leading, spacing: 12) {
                    if !groupViewModel.representedGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            GroupSectionHeader(
                                iconName: "star.fill",
                                iconColor: .yellow,
                                title: "Representing"
                            )
                            
                            ForEach(groupViewModel.representedGroups) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    NavigationLabel {
                                        GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    if !groupViewModel.managedGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            GroupSectionHeader(
                                iconName: IconSet.shield.systemName,
                                iconColor: .blue,
                                title: "관리 중인 그룹",
                                count: groupViewModel.managedGroups.count
                            )
                            
                            ForEach(groupViewModel.managedGroups.prefix(2)) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    NavigationLabel {
                                        GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
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
                    
                    if !groupViewModel.mutualGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            GroupSectionHeader(
                                iconName: "person.2.circle.fill",
                                iconColor: .purple,
                                title: "함께 속한 그룹",
                                count: groupViewModel.mutualGroups.count
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        GroupSectionHeader(
                            iconName: "person.3.fill",
                            iconColor: .green,
                            title: "소속된 그룹",
                            count: groupViewModel.allGroups.count
                        )
                    }
                }
            } else {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.gray)
                    Text("참여 중인 그룹이 없습니다")
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
            if Task.isCancelled { return }
            await groupViewModel.loadUserGroups()
            if Task.isCancelled { return }
            await MainActor.run {
                self.isLoading = false
            }
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
