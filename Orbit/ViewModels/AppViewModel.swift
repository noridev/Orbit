//
//  AppViewModel.swift
//  Orbit
//
//  Created by makinosp on 2024/03/09.
//

import Foundation
import Observation
import VRCKit

@Observable @MainActor
final class AppViewModel {
    var user: User?
    var step: Step = .initializing
    var vrckError: VRCKitError?
    var applicationError: ApplicationError?
    var services: APIServiceUtil
    var verifyType: VerifyType?
    var screenSize: CGSize = .zero
    @ObservationIgnored var client: APIClient
    @ObservationIgnored let userDefaults: UserDefaults
    @ObservationIgnored let accountManager = AccountManager.shared

    init() {
        let client = APIClient()
        self.client = client
        services = APIServiceUtil(client: client)
        userDefaults = UserDefaults.standard
    }

    enum Step: Equatable {
        case initializing, loggingIn, done(User)
    }

    /// Checks the user's authentication status, fetches user information,
    /// and performs the initialization process.
    ///
    /// - Parameter service: An instance conforming to `AuthenticationServiceProtocol`
    ///                      used to verify the authentication token and fetch user information.
    /// - Returns: A `Step` value indicating the next step:
    ///            `.loggingIn` if the user is not authenticated, or `.done(user)`
    ///            if the authentication and user data retrieval are successful.
    func setup(service: AuthenticationServiceProtocol) async -> Step {
        var next: Step = .loggingIn
        // check local data
        guard await client.cookieManager.cookieExists else { 
            print("🍪 [setup] No cookies found, proceeding to login")
            return next 
        }
        
        print("🍪 [setup] Cookies found, verifying auth token")
        do {
            // verify auth token and fetch user data
            guard try await service.verifyAuthToken() else { 
                print("🔐 [setup] Auth token verification failed")
                await client.cookieManager.deleteCookies()
                return next 
            }
            
            print("🔐 [setup] Auth token verified, fetching user info")
            let result = try await service.loginUserInfo()
            if case .left(let user) = result {
                setUser(user)
                next = .done(user)
                print("✅ [setup] Setup completed successfully for user: \(user.displayName)")
            } else {
                print("🔐 [setup] User info fetch returned 2FA requirement")
                await client.cookieManager.deleteCookies()
            }
        } catch {
            print("❌ [setup] Setup failed with error: \(error)")
            await client.cookieManager.deleteCookies()
            if let vrckError = error as? VRCKitError,
               case .unauthorized = vrckError {
                print("🔐 [setup] Authentication error, clearing session")
            } else {
                handleError(error)
            }
        }
        return next
    }

    /// Sets the user's credentials and configures the necessary services.
    /// - Parameters:
    ///   - credential: The `Credential` object containing user authentication information.
    ///   - isSavedOnKeyChain: A Boolean indicating whether the credential should
    ///                        be saved in the Keychain for future use.
    private func setCredential(_ credential: Credential, isSavedOnKeyChain: Bool) async {
        services = APIServiceUtil(isPreviewMode: credential.isPreviewUser, client: client)
        await client.setCledentials(credential)
        if isSavedOnKeyChain {
            _ = await KeychainUtil.shared.savePassword(credential)
        }
    }

    /// Logs in the user with the provided credentials and handles the login result.
    /// - Parameters:
    ///   - credential: The `Credential` object containing user authentication information.
    ///   - isSavedOnKeyChain: A Boolean indicating whether the credential should
    ///                        be saved in the Keychain for future use.
    func login(credential: Credential, isSavedOnKeyChain: Bool) async {
        await setCredential(credential, isSavedOnKeyChain: isSavedOnKeyChain)
        guard let result = await login() else { return }
        loginHandler(result: result)
    }

    private func loginHandler(result: Either<User, VerifyType>) {
        switch result {
        case .left(let user):
            setUser(user)
        case .right(let verifyType):
            self.verifyType = verifyType
        }
    }

    private func setUser(_ user: User) {
        print("🚀 [AppViewModel.setUser] Setting user: \(user.displayName) (ID: \(user.id))")
        
        self.user = user
        step = .done(user)
        
        accountManager.setCurrentUser(user)
        accountManager.checkAndMigrateLegacyData()
        
        print("✅ [AppViewModel.setUser] User setup completed")
    }

    /// Attempts to log in the user and returns the result of the authentication process.
    /// - Returns: An `Either<User, VerifyType>` value representing the authenticated user
    ///            or a verification type, or `nil` if an error occurs during the process.
    func login() async -> Either<User, VerifyType>? {
        var result: Either<User, VerifyType>?
        do {
            result = try await services.authenticationService.loginUserInfo()
        } catch {
            handleError(error)
        }
        return result
    }

    func verifyTwoFA(code: String) async {
        guard let verifyType = verifyType else { return }
        do {
            guard try await services.authenticationService.verify2FA(
                verifyType: verifyType,
                code: code
            ) else {
                throw ApplicationError(text: "Authentication failed")
            }
            
            let result = try await services.authenticationService.loginUserInfo()
            if case .left(let user) = result {
                setUser(user)
                self.verifyType = nil
            }
        } catch {
            handleError(error)
        }
    }

    func logout() async {
        print("🚀 [logout] Starting logout process")
        user = nil
        
        do {
            try await services.authenticationService.logout()
            print("✅ [logout] Server logout successful")
        } catch {
            print("⚠️ [logout] Server logout failed: \(error), but clearing local state")
        }
        dispose()
    }

    /// Resets the application's state and clears user-related data.
    ///
    /// This function removes stored user data from `UserDefaults`, including the
    /// Keychain save preference and username, resets the current authentication step
    /// to `.initializing`, and reinitializes the API client to a default state.
    func dispose() {
        print("🗑️ [dispose] Clearing application state")
        
        userDefaults.removeObject(forKey: Constants.Keys.isSavedOnKeyChain.rawValue)
        userDefaults.removeObject(forKey: Constants.Keys.username.rawValue)
        
        Task {
            await client.cookieManager.deleteCookies()
        }
        
        user = nil
        verifyType = nil
        vrckError = nil
        applicationError = nil
        
        step = .initializing
        client = APIClient()
        
        print("✅ [dispose] Application state cleared")
    }

    func handleError(_ error: Error) {
        if let error = error as? VRCKitError {
            switch error {
            case .unauthorized(let context):
                if context.isLoginFailure {
                    vrckError = error
                } else {
                    vrckError = error
                }
            case .networkError, .serverError:
                vrckError = error
            default:
                vrckError = error
            }
        } else if let error = error as? ApplicationError {
            applicationError = error
        } else if !error.isCancelled {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    vrckError = VRCKitError.networkError("No internet connection. Please check your network settings.")
                case .timedOut:
                    vrckError = VRCKitError.networkError("Request timed out. Please try again.")
                case .cannotConnectToHost:
                    vrckError = VRCKitError.networkError("Cannot connect to server. Please try again later.")
                default:
                    vrckError = VRCKitError.networkError("Network error: \(urlError.localizedDescription)")
                }
            } else {
                applicationError = ApplicationError(error)
            }
        }
    }
}
