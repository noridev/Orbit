//
//  ApplicationError.swift
//  Orbit
//
//  Created by makinosp on 2024/06/23.
//

import Foundation

struct ApplicationError: LocalizedError {
    let text: String

    var localizedString: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: text)
    }

    var errorDescription: String? {
        String(localized: localizedString)
    }

    static var appVMIsNotSetError: ApplicationError {
        ApplicationError(text: "App ViewModel is not set")
    }

    static var userIsNotSetError: ApplicationError {
        ApplicationError(text: "User is not set")
    }

    static var tooManyLanguages: ApplicationError {
        ApplicationError(text: "You can add up to 3 languages")
    }

    static var tooManyBioLinks: ApplicationError {
        ApplicationError(text: "You can add up to 3 social links")
    }
}

extension ApplicationError {
    init(_ error: Error) {
        text = error.localizedDescription
    }
}
