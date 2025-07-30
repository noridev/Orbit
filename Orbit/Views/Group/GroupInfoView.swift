//
//  GroupInfoView.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

struct GroupInfoView: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @Binding var reloadTrigger: Bool
    @State private var isLoading = false
    @State var currentGroup: VRCGroup
    @State var members: [GroupMembership]?
    @State var ownerUserState: OwnerUserState = .loading
    let group: VRCGroup
    let headerSection: AnyView

    enum OwnerUserState {
        case loading
        case loaded(UserDetail)
        case notFound
        case error(Error)
    }

    init(group: VRCGroup, reloadTrigger: Binding<Bool>, headerSection: AnyView) {
        self.group = group
        self._currentGroup = State(initialValue: group)
        self._reloadTrigger = reloadTrigger
        self.headerSection = headerSection
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                descriptionSection(currentGroup.description, isLoading: isLoading)
                rulesSection(currentGroup.rules, isLoading: isLoading)
                membershipSection(isLoading: isLoading)
                infoSection(members: members, isLoading: isLoading)
                if let languages = currentGroup.languages, !languages.isEmpty {
                    languageSection(languages: languages)
                }
                if !currentGroup.linkUrls.isEmpty {
                    socialLinksSection(currentGroup.linkUrls)
                }
                ownerSection
            }
            .padding(.bottom, 32)
        }
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
            let groupMembers = try await appVM.services.groupService.fetchGroupMembers(
                groupId: currentGroup.groupId ?? currentGroup.id,
                offset: 0,
                n: 100
            )
            await MainActor.run {
                self.members = groupMembers
            }
        } catch {
            print("❌ [GroupInfoView] Failed to fetch group members: \(error)")
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
