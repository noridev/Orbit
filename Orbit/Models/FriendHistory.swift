//
//  FriendHistory.swift
//  Orbit
//
//  Created by NoriDev on 7/5/25.
//

import Foundation

struct FriendHistory: Codable, Identifiable, Hashable {
    let id: UUID
    let friendId: String
    let date: Date
    let event: HistoryEvent

    init(friendId: String, date: Date = Date(), event: HistoryEvent) {
        self.id = UUID()
        self.friendId = friendId
        self.date = date
        self.event = event
    }
}

enum EventType: String, CaseIterable, Hashable, CustomStringConvertible {
    case newFriend, unfriend, displayNameChanged, trustRankChanged

    var description: String {
        switch self {
        case .newFriend: "New friend"
        case .unfriend: "Unfriend"
        case .displayNameChanged: "Display Name Changed"
        case .trustRankChanged: "Trust Rank Changed"
        }
    }
    
    var icon: Iconizable {
        switch self {
        case .newFriend: return IconSet.newFriend
        case .unfriend: return IconSet.unfriend
        case .displayNameChanged: return IconSet.at
        case .trustRankChanged: return IconSet.shield
        }
    }
}

enum HistoryEvent: Codable, Hashable {
    case newFriend
    case unfriend
    case displayNameChanged(from: String, to: String)
    case trustRankChanged(from: String, to: String)

    var eventType: EventType {
        switch self {
        case .newFriend: .newFriend
        case .unfriend: .unfriend
        case .displayNameChanged: .displayNameChanged
        case .trustRankChanged: .trustRankChanged
        }
    }
    
    var description: String {
        switch self {
        case .newFriend:
            return "친구로 추가되었습니다."
        case .unfriend:
            return "친구에서 삭제되었습니다."
        case .displayNameChanged(let from, let to):
            return "닉네임이 '\(from)'에서 '\(to)'(으)로 변경되었습니다."
        case .trustRankChanged(let from, let to):
            return "신뢰 등급이 '\(from)'에서 '\(to)'(으)로 변경되었습니다."
        }
    }
}
