//
//  GroupInstanceListView.swift
//  Orbit
//
//  Created by NoriDev on 7/22/25.
//

import SwiftUI
import VRCKit

private enum GroupInstanceCardData {
    case friendInstance(Instance)
}

struct GroupInstanceListView: View {
@Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @Binding var reloadTrigger: Bool
    @State private var instances: [Instance] = []
    @State private var isLoading = false
    @State private var error: Error?
    let groupId: String
    let groupName: String

    var body: some View {
        let displayInstances: [GroupInstanceCardData?] = isLoading
            ? []
            : instances.map { .friendInstance($0) }
        
        let friendInstances = displayInstances.compactMap { data in
            if case .friendInstance(let instance) = data {
                let friendsInInstance = friendVM.allFriends.filter { friend in
                    if case let .id(locationId) = friend.location {
                        return locationId == instance.id
                    }
                    return false
                }
                return friendsInInstance.isEmpty ? nil : instance
            }
            return nil
        }
        
        let regularInstances = displayInstances.compactMap { data in
            if case .friendInstance(let instance) = data {
                let friendsInInstance = friendVM.allFriends.filter { friend in
                    if case let .id(locationId) = friend.location {
                        return locationId == instance.id
                    }
                    return false
                }
                return friendsInInstance.isEmpty ? instance : nil
            }
            return nil
        }
        
        Group {
            if !isLoading && instances.isEmpty {
                if let error = error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error.localizedDescription)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ContentUnavailableView {
                        Label("인스턴스 없음", systemImage: "person.3.fill")
                            .foregroundColor(.gray)
                    } description: {
                        Text("현재 이 그룹에는 인스턴스가 없습니다")
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
            } else {
                GroupInstanceList(
                    friendInstances: friendInstances,
                    regularInstances: regularInstances,
                    isLoading: isLoading,
                    loadInstances: { await loadInstances(force: true) },
                    instanceCount: instances.count
                )
            }
        }
        .onAppear { Task { await loadInstances() } }
        .onChange(of: reloadTrigger) { Task { await loadInstances(force: true) } }
    }

    @MainActor
    private func loadInstances(force: Bool = false) async {
        if !force {
            guard instances.isEmpty, !isLoading else { return }
        }
        isLoading = true
        error = nil
        
        do {
            let userId = appVM.user?.id ?? "me"
            let result = try await appVM.services.groupService.fetchGroupInstances(userId: userId, groupId: groupId)
            self.instances = result
        } catch {
            self.error = error
        }
        
        withAnimation { self.isLoading = false }
    }
}

private struct GroupInstanceList: View {
    let friendInstances: [Instance]
    let regularInstances: [Instance]
    let isLoading: Bool
    let loadInstances: () async -> Void
    let instanceCount: Int
    
    var body: some View {
        List {
            if isLoading {
                Section(header: HStack {
                    Text("인스턴스")
                    Spacer()
                    Text("\(instanceCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                        .redacted(reason: isLoading ? .placeholder : [])
                }) {
                    ForEach(0..<6) { _ in
                        NavigationLink(destination: EmptyView()) {
                            FriendLocationContent(instance: PreviewData.instance)
                        }
                        .disabled(true)
                    }
                }
            } else {
                if !friendInstances.isEmpty {
                    Section(header: HStack {
                        Text("친구가 접속함")
                        Spacer()
                        Text("\(friendInstances.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                    }) {
                        ForEach(friendInstances, id: \.id) { instance in
                            NavigationLink(destination: GroupLocationDetailView(instance: instance)) {
                                FriendLocationContent(instance: instance)
                            }
                        }
                    }
                }
                
                if !regularInstances.isEmpty {
                    Section(header: HStack {
                        Text("인스턴스")
                        Spacer()
                        Text("\(regularInstances.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }) {
                        ForEach(regularInstances, id: \.id) { instance in
                            NavigationLink(destination: GroupLocationDetailView(instance: instance)) {
                                FriendLocationContent(instance: instance)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .redacted(reason: isLoading ? .placeholder : [])
        .refreshable {
            await loadInstances()
        }
    }
}

private struct FriendLocationContent: View {
    @Environment(FriendViewModel.self) var friendVM
    let instance: Instance
    
    private var friendsInInstance: [Friend] {
        friendVM.allFriends.filter { friend in
            if case let .id(locationId) = friend.location {
                return locationId == instance.id
            }
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                WorldHeaderView(world: instance.world ?? .placeholder) {
                    Text(InstanceUtil.getInstanceWithInstanceType(instance))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule()).lineLimit(1)
                    
                    HStack {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(personAmount(instance))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        if instance.ageGate == true {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                Text("Age Gated")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 6)
            
            if !friendsInInstance.isEmpty {
                HStack(spacing: 10) {
                    HStack(spacing: 2) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(friendsInInstance.count)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                    
                    HorizontalProfileImages(friendsInInstance)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func personAmount(_ instance: Instance) -> String {
        [instance.userCount, instance.capacity]
            .map { $0.description }
            .joined(separator: " / ")
    }
}
