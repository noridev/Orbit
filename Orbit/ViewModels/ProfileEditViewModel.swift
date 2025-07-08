//
//  ProfileEditViewModel.swift
//  Orbit
//
//  Created by makinosp on 2024/08/23.
//

import Foundation
import Observation
import VRCKit

@Observable @MainActor
final class ProfileEditViewModel {
    @ObservationIgnored private let id: User.ID
    var editingUserInfo: EditableUserInfo
    var tempBioLinks: [String] = []
    private let maxBioLinks = 3
    private let maxLanguages = 3
    
    var canAddMoreLanguages: Bool {
        editingUserInfo.tags.languageTags.count < maxLanguages
    }

    var canAddMoreLinks: Bool {
        tempBioLinks.count < maxBioLinks
    }

    init(user: User) {
        editingUserInfo = EditableUserInfo(detail: user)
        id = user.id
        tempBioLinks = user.bioLinks.wrappedValue.map { $0.absoluteString }
    }

    func saveProfile(service: UserServiceProtocol) async throws {
        guard tempBioLinks.count <= maxBioLinks else {
            throw ApplicationError.tooManyBioLinks
        }
        
        guard editingUserInfo.tags.languageTags.count <= maxLanguages else {
            throw ApplicationError.tooManyLanguages
        }
        
        editingUserInfo.bioLinks = tempBioLinks
            .filter { !$0.isEmpty }
            .compactMap { URL(string: $0) }
        
        try await service.updateUser(
            id: id,
            editedInfo: editingUserInfo
        )
    }

    func removeTag(_ target: LanguageTag) {
        editingUserInfo.tags.languageTags = editingUserInfo.tags.languageTags.filter { $0 != target }
    }

    func removeUrl(at index: Int) {
        guard index < tempBioLinks.count else { return }
        tempBioLinks.remove(at: index)
    }
}
