//
//  GroupDetailView.swift
//  Orbit
//
//  Created by NoriDev on 7/17/25.
//

import SwiftUI
import VRCKit

struct GroupDetailView: View {
    let group: VRCGroup
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @State private var isLoading = false
    @State private var isPresentedJsonView = false
    @State var ownerUserState: OwnerUserState = .loading
    @State var currentGroup: VRCGroup
    @State private var members: [GroupMembership]?
    
    enum OwnerUserState {
        case loading
        case loaded(UserDetail)
        case notFound
        case error(Error)
    }
    
    init(group: VRCGroup) {
        self.group = group
        self._currentGroup = State(initialValue: group)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
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
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(currentGroup.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("JSON Data", systemImage: "doc.text") {
                        isPresentedJsonView = true
                    }
                } label: {
                    Image(systemName: IconSet.dots.systemName)
                }
            }
        }
        .sheet(isPresented: $isPresentedJsonView) {
            GroupJsonDetailView(group: currentGroup)
        }
        .refreshable {
            await refreshData()
        }
        .task {
            await refreshData()
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
            print("❌ [GroupDetailView] Failed to fetch group details: \(error)")
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
            print("❌ [GroupDetailView] Failed to fetch owner user: \(error)")
        }
    }
    
    private func fetchMembers() async {
        do {
            let groupMembers = try await appVM.services.groupService.fetchGroupMembers(groupId: currentGroup.groupId ?? currentGroup.id)
            await MainActor.run {
                self.members = groupMembers
            }
        } catch {
            print("❌ [GroupDetailView] Failed to fetch group members: \(error)")
        }
    }
}

struct GroupJsonDetailView: View {
    let group: VRCGroup
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            JsonDetailView(
                userId: group.groupId ?? group.id,
                cachedData: group,
                isLocalDataView: false,
                title: group.name,
                subTitle: "Group JSON Data",
                useNavigationStack: true,
                showToolbar: true,
                onDismiss: { dismiss() }
            )
        }
    }
}

#Preview {
    NavigationView {
        GroupDetailView(group: PreviewData.sampleGroup)
    }
}
