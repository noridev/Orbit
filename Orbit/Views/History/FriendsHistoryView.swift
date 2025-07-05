//
//  FriendsHistoryView.swift
//  Orbit
//
//  Created by NoriDev on 7/5/25.
//

import SwiftUI
import VRCKit
import NukeUI

struct FriendsHistoryView: View {
    @Environment(FriendViewModel.self) private var friendVM
    @State private var allHistories: [FriendHistoryViewModel.MergedHistory] = []
    
    private let historyVM = FriendHistoryViewModel.shared

    var body: some View {
        NavigationStack {
            List {
                if allHistories.isEmpty {
                    ContentUnavailableView {
                        Label("No history", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("If your friend changes their nickname, changed their trust rank, or adds or removes a friend, you'll see a record of here.")
                    }
                } else {
                    ForEach(allHistories) { mergedHistory in
                        historyRow(for: mergedHistory)
                    }
                }
            }
            .navigationTitle("Friends History")
            .listStyle(.plain)
            .onAppear {
                allHistories = historyVM.loadAllHistories(friends: friendVM.allFriends)
            }
            .refreshable {
                allHistories = historyVM.loadAllHistories(friends: friendVM.allFriends)
            }
        }
    }
    
    @ViewBuilder
    private func historyRow(for mergedHistory: FriendHistoryViewModel.MergedHistory) -> some View {
        HStack(alignment: .top, spacing: 12) {
            LazyImage(url: mergedHistory.friend?.avatarThumbnailUrl) { state in
                if let image = state.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.secondary.opacity(0.3)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mergedHistory.friend?.displayName ?? "알 수 없는 친구")
                    .font(.headline)
                
                Text(mergedHistory.history.event.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(mergedHistory.history.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PreviewContainer {
        FriendsHistoryView()
    }
}
