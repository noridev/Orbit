//
//  FilterSheetView.swift
//  Orbit
//
//  Created by NoriDev on 7/6/25.
//

import SwiftUI
import VRCKit

struct FilterSheetView: View {
    @Environment(FavoriteViewModel.self) private var favoriteVM
    @Environment(\.dismiss) private var dismiss
    @Binding var sortType: SortType
    @Binding var statusFilter: Set<UserStatus>
    @Binding var favoriteGroupFilter: Set<FavoriteGroup.ID>
    @Binding var eventFilter: Set<EventType>
    @Binding var excludeWebUsers: Bool
    
    let sortContext: SortType.Context
    let visibleSections: Set<FilterType>
    
    var body: some View {
        NavigationStack {
            Form {
                SortPickerView(selection: $sortType, context: sortContext)
                
                if visibleSections.contains(.status) {
                    statusSection
                }

                if visibleSections.contains(.eventType) {
                    eventTypeSection
                }

                if visibleSections.contains(.favoriteGroup) {
                    favoriteGroupSection
                }
                
                if visibleSections.contains(.platform) {
                    platformSection
                }
            }
            .navigationTitle("Display Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: { dismiss() }) {
                        ExitButton()
                    }
                }
            }
        }
    }
    
    private var statusSection: some View {
        Section {
            ForEach(UserStatus.allCases) { userStatus in
                Toggle(isOn: $statusFilter.containsBinding(for: userStatus)) {
                    Label {
                        Text(userStatus.description)
                    } icon: {
                        Image(systemName: IconSet.circleFilled.systemName)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(userStatus.color)
                    }
                }
            }
        } header: {
            HStack {
                Text("Statuses")
                Spacer()
                Button("Clear") { statusFilter.removeAll() }.font(.caption)
            }
        }
    }
    
    private var favoriteGroupSection: some View {
        Section {
            ForEach(favoriteVM.favoriteGroups(.friend)) { favoriteGroup in
                Toggle(isOn: $favoriteGroupFilter.containsBinding(for: favoriteGroup.id)) {
                    Label(favoriteGroup.displayName, systemImage: IconSet.favoriteGroup.systemName)
                }
            }
        } header: {
            HStack {
                Text("Favorite Groups")
                Spacer()
                Button("Clear") { favoriteGroupFilter.removeAll() }.font(.caption)
            }
        }
    }
    
    private var eventTypeSection: some View {
        Section {
            ForEach(EventType.allCases, id: \.self) { eventType in
                Toggle(isOn: eventFilterBinding(for: eventType)) {
                    Label(eventType.description, systemImage: eventType.icon.systemName)
                }
            }
        } header: {
            HStack {
                Text("Type")
                Spacer()
                Button("Clear") { eventFilter.removeAll() }.font(.caption)
            }
        }
    }
    
    private var platformSection: some View {
        Section {
            Toggle(isOn: $excludeWebUsers) {
                Label {
                    Text("Exclude Web Users")
                } icon: {
                    Image(systemName: "globe")
                }
            }
        } header: {
            Text("Platform")
        } footer: {
            Text("Exclude users who are using VRChat through a web browser")
        }
    }

    private func eventFilterBinding(for eventType: EventType) -> Binding<Bool> {
        Binding<Bool>(
            get: { self.eventFilter.contains(eventType) },
            set: {
                if $0 { self.eventFilter.insert(eventType) } else { self.eventFilter.remove(eventType) }
            }
        )
    }
    
    enum FilterType {
        case status, favoriteGroup, eventType, platform
    }
}
