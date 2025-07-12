//
//  FriendStatusComponents.swift
//  Orbit
//
//  Created by NoriDev on 7/7/25.
//

import SwiftUI
import VRCKit

struct FriendStatusView: View {
    let friend: Friend
    
    var body: some View {
        if friend.status != .offline {
            if friend.location != .offline {
                InstanceLocationView(friend: friend)
            } else if !friend.statusDescription.isEmpty {
                Text(friend.statusDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if let lastActivity = friend.lastActivity {
                LastActivityView(lastActivity: lastActivity)
            }
        } else {
            if let lastActivity = friend.lastActivity {
                LastActivityView(lastActivity: lastActivity)
            } else if !friend.statusDescription.isEmpty {
                Text(friend.statusDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct InstanceLocationView: View {
    let friend: Friend
    @State private var instance: Instance?
    @State private var isLoading = true
    @State private var error = false
    @Environment(AppViewModel.self) var appVM

    var body: some View {
        Group {
            if isLoading {
                Text("Fetching location...")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if error {
                Text("Failed to get location")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if let instance = instance {
                VStack(alignment: .leading, spacing: 2) {
                    Text(instance.world.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(InstanceUtil.getInstanceDescription(instance))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                Text(locationDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            if isLoading {
                Task { await loadInstanceInfo() }
            }
        }
    }

    private var locationDescription: String {
        switch friend.location {
        case .private:
            String(localized: "Private")
        case .traveling:
            String(localized: "Traveling")
        case .offline:
            String(localized: "Offline")
        case .id:
            String(localized: "In world")
        }
    }

    private func loadInstanceInfo() async {
        guard case let .id(locationId) = friend.location else {
            isLoading = false
            return
        }
        do {
            let service = appVM.services.instanceService
            instance = try await service.fetchInstance(location: locationId)
            isLoading = false
        } catch {
            self.error = true
            isLoading = false
        }
    }
}

struct LastActivityView: View {
    let lastActivity: Date
    @State private var relativeTimeString = ""
    
    var body: some View {
        HStack(spacing: 2) {
            Text("Last Activity" + ":")
                .font(.caption)
                .foregroundStyle(.gray)
            Text(relativeTimeString)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .task {
            await updateRelativeTime()
        }
        .onAppear {
            updateRelativeTimeSync()
        }
    }
    
    private func updateRelativeTimeSync() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: lastActivity, to: now)
        
        if let day = components.day, day > 0 {
            relativeTimeString = lastActivity.formatted(date: .numeric, time: .shortened)
        } else {
            Task {
                await updateRelativeTime()
            }
        }
    }
    
    private func updateRelativeTime() async {
        let dateUtil = DateUtil.shared
        let relativeString = await dateUtil.formatRelative(from: lastActivity)
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: lastActivity, to: now)
        
        if let day = components.day, day == 0 {
            relativeTimeString = relativeString
        }
    }
}
