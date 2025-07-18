//
//  GroupListView.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import SwiftUI
import VRCKit

struct GroupListView: View {
    @StateObject private var groupViewModel = GroupViewModel.shared
    @State private var searchText = ""
    @State private var sortType: SortType = .name
    @State private var isPresentedSheet = false
    let userId: String
    let userName: String?
    let groupService: GroupServiceProtocol
    
    init(userId: String, userName: String? = nil, groupService: GroupServiceProtocol) {
        self.userId = userId
        self.userName = userName
        self.groupService = groupService
    }
    
    private var navigationTitle: String {
        if let userName = userName {
            return "\(userName)'s Groups"
        }
        return "그룹"
    }
    
    private func sortedAndFilteredGroups(for groups: [VRCGroup]) -> [VRCGroup] {
        let filtered = groups.filter { group in
            searchText.isEmpty ||
            group.name.localizedCaseInsensitiveContains(searchText) ||
            group.shortCode.localizedCaseInsensitiveContains(searchText) ||
            group.discriminator.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted {
            switch sortType {
            case .name:
                return $0.name.lowercased() < $1.name.lowercased()
            case .memberCount:
                return $0.memberCount > $1.memberCount
            default:
                return $0.name.lowercased() < $1.name.lowercased()
            }
        }
    }
    
    private var filteredRepresentedGroups: [VRCGroup] {
        sortedAndFilteredGroups(for: groupViewModel.representedGroups)
    }
    
    private var filteredManagedGroups: [VRCGroup] {
        sortedAndFilteredGroups(for: groupViewModel.managedGroups)
    }
    
    private var filteredMutualGroups: [VRCGroup] {
        sortedAndFilteredGroups(for: groupViewModel.mutualGroups)
    }
    
    private var filteredRegularGroups: [VRCGroup] {
        sortedAndFilteredGroups(for: groupViewModel.regularGroups)
    }
    
    var body: some View {
        List {
            if !filteredRepresentedGroups.isEmpty {
                Section {
                    ForEach(filteredRepresentedGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: { 
                    GroupSectionHeader(
                        iconName: "star.fill",
                        iconColor: .yellow,
                        title: "Representing"
                    )
                }
            }
            
            if !filteredManagedGroups.isEmpty {
                Section {
                    ForEach(filteredManagedGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: { 
                    GroupSectionHeader(
                        iconName: IconSet.shield.systemName,
                        iconColor: .blue,
                        title: "관리 중인 그룹",
                        count: filteredManagedGroups.count
                    )
                }
            }
            
            if !filteredMutualGroups.isEmpty {
                Section {
                    ForEach(filteredMutualGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: { 
                    GroupSectionHeader(
                        iconName: "person.2.circle.fill",
                        iconColor: .purple,
                        title: "함께 속한 그룹",
                        count: filteredMutualGroups.count
                    )
                }
            }
            
            if !filteredRegularGroups.isEmpty {
                Section {
                    ForEach(filteredRegularGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: { 
                    GroupSectionHeader(
                        iconName: "person.3.fill",
                        iconColor: .green,
                        title: "소속된 그룹",
                        count: filteredRegularGroups.count
                    )
                }
            }
        }
        .overlay { overlayView }
        .refreshable {
            await groupViewModel.refreshGroups()
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isPresentedSheet.toggle() }) {
                    Image(systemName: IconSet.filter.systemName)
                }
            }
        }
        .sheet(isPresented: $isPresentedSheet) {
            FilterSheetView(
                sortType: $sortType,
                statusFilter: .constant([]),
                favoriteGroupFilter: .constant([]),
                eventFilter: .constant([]),
                excludeWebUsers: .constant(false),
                sortContext: .groups,
                visibleSections: []
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            groupViewModel.configure(groupService: groupService, userId: userId)
            
            if groupViewModel.userGroups.isEmpty && !groupViewModel.isLoading {
                Task {
                    await groupViewModel.loadUserGroups()
                }
            } else if groupViewModel.isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if groupViewModel.isLoading {
                        groupViewModel.resetState()
                        Task {
                            await groupViewModel.loadUserGroups()
                        }
                    }
                }
            }
        }
        .task {
            groupViewModel.configure(groupService: groupService, userId: userId)
            await groupViewModel.loadUserGroups()
        }
        .onReceive(groupViewModel.objectWillChange) { _ in
            // Force view update when view model changes
        }
    }
    
    @ViewBuilder private var overlayView: some View {
        if groupViewModel.isLoading {
            ProgressView()
                .padding(32)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else if let error = groupViewModel.error {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("그룹을 불러오는데 실패했습니다")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("다시 시도") {
                    Task {
                        await groupViewModel.refreshGroups()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        } else if !groupViewModel.hasGroups {
            ContentUnavailableView {
                Label("참여 중인 그룹이 없습니다", systemImage: "person.3")
                    .foregroundColor(.gray)
            } description: {
                Text("VRChat에서 그룹에 가입하면 여기에 표시됩니다")
            }
        } else if !searchText.isEmpty && filteredRepresentedGroups.isEmpty && filteredManagedGroups.isEmpty && filteredMutualGroups.isEmpty && filteredRegularGroups.isEmpty {
            ContentUnavailableView.search
        }
    }
}

struct GroupRowView: View {
    let group: VRCGroup
    let isRepresenting: Bool
    let isManagedGroup: Bool
    let isMutualGroup: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = group.iconUrl {
                AsyncImage(url: icon) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.secondary)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 80, height: 80)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if group.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    if isRepresenting {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    if isManagedGroup {
                        Image(systemName: IconSet.shield.systemName)
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    
                    if isMutualGroup {
                        Image(systemName: "person.2.circle.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                
                ScrollView(.horizontal) {
                    HStack {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(group.memberCount)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                        
                        Text("#\(group.shortCode).\(group.discriminator)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule()).lineLimit(1)
                        
                        Spacer()
                    }
                }
                
                if let description = group.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GroupListView(
        userId: "usr_preview",
        groupService: GroupPreviewService(client: APIClient())
    )
}
