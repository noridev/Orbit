//
//  View+ErrorAlertModifier.swift
//  Orbit
//
//  Created by makinosp on 2024/06/28.
//

import MemberwiseInit
import SwiftUI

extension View {
    func errorAlert(_ action: @escaping () -> Void = {}) -> some View {
        modifier(ErrorAlertModifier(action))
    }
}

@MainActor @MemberwiseInit
private struct ErrorAlertModifier {
    @Environment(AppViewModel.self) var appVM: AppViewModel
    @Init(.internal, escaping: true, label: "_") private let action: () -> Void

    typealias ErrorKeyPath<E> = ReferenceWritableKeyPath<AppViewModel, E?>

    func isThrownError<E>(_ errorKeyPath: ErrorKeyPath<E>) -> Binding<Bool> where E: Error {
        Binding<Bool>(
            get: { appVM[keyPath: errorKeyPath] != nil },
            set: { isErrorActive in
                guard !isErrorActive else { return }
                appVM[keyPath: errorKeyPath] = nil
            }
        )
    }
}

extension ErrorAlertModifier: ViewModifier {
    func body(content: Content) -> some View {
        @Bindable var appVM = appVM
        content
            .errorAlert(isThrownError(\.vrckError), appVM.vrckError, action)
            .errorAlert(isThrownError(\.applicationError), appVM.applicationError, action)
            .sessionExpiredAlert(appVM: appVM)
    }
}

private extension View {
    func errorAlert<E>(
        _ isPresented: Binding<Bool>,
        _ error: E?,
        _ action: @escaping () -> Void
    ) -> some View where E: LocalizedError {
        alert(
            isPresented: isPresented,
            error: error
        ) { error in
            Button("OK", action: action)
        } message: { error in
            errorText(error)
        }
    }

    private func errorText<E>(_ error: E) -> Text where E: LocalizedError {
        let message = error.failureReason ?? String(localized: "Try again later")
        return Text(verbatim: message)
    }
    
    @ViewBuilder
    func sessionExpiredAlert(appVM: AppViewModel) -> some View {
        let isSessionExpired = Binding<Bool>(
            get: {
                if let vrckError = appVM.vrckError,
                   case .unauthorized(let context) = vrckError,
                   !context.isLoginFailure {
                    return true
                }
                return false
            },
            set: { _ in
                appVM.vrckError = nil
            }
        )
        
        self.alert(
            "Session Expired",
            isPresented: isSessionExpired
        ) {
            Button("OK") {
                appVM.step = .loggingIn
                appVM.dispose()
            }
        } message: {
            Text("Your session has expired. Please log in again to continue.")
        }
    }
}
