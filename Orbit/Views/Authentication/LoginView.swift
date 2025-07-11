//
//  LoginView.swift
//  Orbit
//
//  Created by makinosp on 2024/08/31.
//

import AsyncSwiftUI
import VRCKit

struct LoginView: View {
    @AppStorage(Constants.Keys.isSavedOnKeyChain.rawValue) private var isSavedOnKeyChain = false
    @AppStorage(Constants.Keys.username.rawValue) private var username = ""
    @Environment(AppViewModel.self) var appVM
    @State private var password = ""
    @State private var isPresentedSecurityPopover = false
    @State private var isPresentedSavingPasswordPopover = false
    @State private var isRequesting = false
    @State private var isReady = false
    @State private var isPresentedBrowser = false

    private let titleFont = "Avenir Next"

    var body: some View {
        @Bindable var appVM = appVM
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        Spacer(minLength: 60)
                        titleSection
                        loginCard
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationDestination(item: $appVM.verifyType) { _ in
                OtpView()
            }
        }
        .ignoresSafeArea(.keyboard)
        .overlay {
            if !isReady {
                ProgressScreen()
            }
        }
        .task {
            defer { isReady = true }
            guard isSettedLocalData else { return }
            guard let password = await KeychainUtil.shared.getPassword(for: username) else { return }
            self.password = password
            await appVM.login(credential: cledential, isSavedOnKeyChain: isSavedOnKeyChain)
        }
        .sheet(isPresented: $isPresentedBrowser) {
            if let url = URL(string: "https://vrchat.com/home/register") {
                SafariView(url: url)
            }
        }
        .errorAlert {
            isRequesting = false
        }
    }

    private var isSettedLocalData: Bool {
        isSavedOnKeyChain && !username.isEmpty
    }

    private var cledential: Credential {
        Credential(username: username, password: password)
    }

    private var titleSection: some View {
        VStack(spacing: 12) {
            Image("AppIcon_1024")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(verbatim: BundleUtil.appName.capitalized)
                        .font(.custom(titleFont, size: titleFontSize))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text(verbatim: "for VRChat")
                        .font(.custom(titleFont, size: titleFontSize * 0.6))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Text("Connect to your world")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var titleFontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 56 : 32
    }

    private var loginCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                customTextField(
                    title: "Username",
                    text: $username,
                    icon: "person.fill",
                    contentType: .username
                )
                
                customSecureField(
                    title: "Password",
                    text: $password,
                    icon: "lock.fill",
                    contentType: .password
                )
            }
            
            keychainToggleCard
            loginButton
            bottomLinks
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .frame(maxWidth: 400)
    }

    private func customTextField(
        title: String,
        text: Binding<String>,
        icon: String,
        contentType: UITextContentType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                TextField(title, text: text)
                    .textContentType(contentType)
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    }
            }
        }
    }

    private func customSecureField(
        title: String,
        text: Binding<String>,
        icon: String,
        contentType: UITextContentType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                SecureField(title, text: text)
                    .textContentType(contentType)
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    }
            }
        }
    }

    private var keychainToggleCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("Save Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Button {
                        isPresentedSavingPasswordPopover.toggle()
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .popover(isPresented: $isPresentedSavingPasswordPopover) {
                        HelpView(title: "In What Way?", contents: [.helpWithStoringPassword])
                            .presentationDetents([.medium])
                    }
                }
                
                Text("Securely store in iCloud Keychain")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("", isOn: $isSavedOnKeyChain)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .frame(width: 50)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        }
    }

    private var loginButton: some View {
        AsyncButton {
            defer { isRequesting = false }
            isRequesting = true
            await appVM.login(credential: cledential, isSavedOnKeyChain: isSavedOnKeyChain)
        } label: {
            HStack(spacing: 12) {
                if isRequesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
                
                Text(isRequesting ? "Signing in..." : "Sign In")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
            }
        }
        .disabled(isDisabledLoginButton)
        .opacity(isDisabledLoginButton ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabledLoginButton)
    }

    private var bottomLinks: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Button {
                    isPresentedSecurityPopover.toggle()
                } label: {
                    Text("Is this secure?")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .popover(isPresented: $isPresentedSecurityPopover) {
                    let contents: [Constants.Messages] = [
                        .helpWithVRChatAPIAuthencication,
                        .helpWithStoringAuthenticationTokens,
                        .helpWithStoringPassword,
                        .helpWithCommunicationSecurity
                    ]
                    HelpView(title: "Is this secure?", contents: contents)
                }
                
                Spacer()
            }
            
            HStack {
                Text("New to VRChat?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    isPresentedBrowser.toggle()
                } label: {
                    Text("Create an account")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
        }
    }

    private var isDisabledLoginButton: Bool {
        isRequesting || username.count < 4 || password.count < 8
    }
}

#Preview {
    LoginView()
        .environment(AppViewModel())
}
