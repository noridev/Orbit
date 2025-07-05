//
//  FriendHistoryView.swift
//  Orbit
//
//  Created by NoriDev on 7/5/25.
//

import SwiftUI
import VRCKit

struct FriendHistoryView: View {
    let friend: Friend
    @State private var histories: [FriendHistory] = []
    private let historyVM = FriendHistoryViewModel.shared

    var body: some View {
        List {
            if histories.isEmpty {
                ContentUnavailableView {
                    Label("No history", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("If your friend changes their nickname, changed their trust rank, or adds or removes a friend, you'll see a record of here.")
                }
            } else {
                ForEach(histories) { history in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(history.event.description)
                            .font(.body)
                        Text(history.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("\(friend.displayName)'s History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            histories = historyVM.loadHistory(for: friend.id)
        }
    }
}
