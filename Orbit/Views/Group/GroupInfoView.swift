//
//  GroupInfoView.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

struct GroupInfoView: View {
    let group: VRCGroup
    @Binding var reloadTrigger: Bool
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @State private var isLoading = false
    @State private var currentGroup: VRCGroup
    @State private var members: [GroupMembership]?
    @State private var ownerUserState: OwnerUserState = .loading

    enum OwnerUserState {
        case loading
        case loaded(UserDetail)
        case notFound
        case error(Error)
    }

    init(group: VRCGroup, reloadTrigger: Binding<Bool>) {
        self.group = group
        self._currentGroup = State(initialValue: group)
        self._reloadTrigger = reloadTrigger
    }

    var body: some View {
        VStack(spacing: 16) {
            descriptionSection(currentGroup.description, isLoading: isLoading)
            rulesSection(currentGroup.rules, isLoading: isLoading)
            membershipSection(isLoading: isLoading)
            infoSection(members: members, isLoading: isLoading)
            if let languages = currentGroup.languages, !languages.isEmpty {
                languageSection(languages: languages)
            }
            ownerSection
        }
        .padding(.bottom, 32)
        .onAppear { Task { await refreshData() } }
        .refreshable {
            await refreshData()
            reloadTrigger.toggle()
        }
        .onChange(of: reloadTrigger) {
            Task { await refreshData() }
        }
    }

    private func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        await fetchGroupDetails()
        await fetchOwnerUser()
        await fetchMembers()
    }

    private func fetchGroupDetails() async {
        do {
            let updatedGroup = try await appVM.services.groupService.fetchGroup(
                groupId: currentGroup.groupId ?? currentGroup.id,
                includeRoles: true,
                includeMembers: true
            )
            await MainActor.run {
                self.currentGroup = updatedGroup
            }
        } catch {
            print("❌ [GroupInfoView] Failed to fetch group details: \(error)")
        }
    }

    private func fetchOwnerUser() async {
        do {
            let user = try await appVM.services.userService.fetchUser(userId: currentGroup.ownerId)
            await MainActor.run {
                self.ownerUserState = .loaded(user)
            }
        } catch {
            let isNotFound: Bool
            if let vrcError = error as? VRCKitError {
                switch vrcError {
                case .apiError(let details):
                    isNotFound = details.contains("404") || details.lowercased().contains("not found")
                default:
                    isNotFound = false
                }
            } else {
                isNotFound = error.localizedDescription.lowercased().contains("not found") ||
                            (error as NSError).code == 404
            }
            await MainActor.run {
                self.ownerUserState = isNotFound ? .notFound : .error(error)
            }
            print("❌ [GroupInfoView] Failed to fetch owner user: \(error)")
        }
    }

    private func fetchMembers() async {
        do {
            let groupMembers = try await appVM.services.groupService.fetchGroupMembers(groupId: currentGroup.groupId ?? currentGroup.id)
            await MainActor.run {
                self.members = groupMembers
            }
        } catch {
            print("❌ [GroupInfoView] Failed to fetch group members: \(error)")
        }
    }

    private func descriptionSection(_ description: String?, isLoading: Bool) -> some View {
        GroupBox("설명") {
            if isLoading {
                Text("설명이 없습니다")
                    .font(.body)
                    .redacted(reason: .placeholder)
            } else {
                if let desc = description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ShowMoreText(text: desc, lineLimit: 3)
                        .font(.body)
                } else {
                    Text("설명이 없습니다")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .groupBoxStyle(.card)
    }

    private func rulesSection(_ rules: String?, isLoading: Bool) -> some View {
        GroupBox("규칙") {
            if isLoading {
                Text("규칙이 없습니다")
                    .font(.body)
                    .redacted(reason: .placeholder)
            } else {
                if let rulesText = rules, !rulesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ShowMoreText(text: rulesText, lineLimit: 3)
                        .font(.body)
                } else {
                    Text("규칙이 없습니다")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .groupBoxStyle(.card)
    }

    private func membershipSection(isLoading: Bool) -> some View {
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

    private func infoSection(members: [GroupMembership]?, isLoading: Bool) -> some View {
        GroupBox("그룹 정보") {
            DividedVStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading) {
                    Text("멤버")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text(memberCountText(members: members))
                        .font(.callout)
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
    
    private func memberCountText(members: [GroupMembership]?) -> String {
        let onlineCount = currentGroup.onlineMemberCount ?? 0
        let friendsCount = friendsInGroupCount(members: members)
        if onlineCount == 0 && friendsCount == 0 {
            return "\(currentGroup.memberCount)"
        } else {
            return "\(currentGroup.memberCount) (\(onlineCount)/\(friendsCount))"
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

    private func languageSection(languages: [String]) -> some View {
        GroupBox("Languages") {
            HStack(spacing: 8) {
                ForEach(currentGroup.languageTags) { languageTag in
                    Text(languageTag.description)
                        .font(.footnote.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.systemFill))
                        .cornerRadius(8)
                }
            }
        }
        .groupBoxStyle(.card)
    }

    private var ownerSection: some View {
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
