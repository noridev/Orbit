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

enum HistoryEvent: Codable, Hashable {
    case added
    case removed
    case nicknameChanged(from: String, to: String)
    case trustRankChanged(from: String, to: String)

    var description: String {
        switch self {
        case .added:
            return "친구로 추가되었습니다."
        case .removed:
            return "친구에서 삭제되었습니다."
        case .nicknameChanged(let from, let to):
            return "닉네임이 '\(from)'에서 '\(to)'(으)로 변경되었습니다."
        case .trustRankChanged(let from, let to):
            return "신뢰 등급이 '\(from)'에서 '\(to)'(으)로 변경되었습니다."
        }
    }
}
