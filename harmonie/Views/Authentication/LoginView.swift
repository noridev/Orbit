//
//  LoginView.swift
//  Harmonie
//
//  Created by makinosp on 2024/08/31.
//

import AsyncSwiftUI
import VRCKit

struct LoginView: View, AuthenticationServicePresentable {
    @AppStorage(Constants.Keys.isSavedOnKeyChain) private var isSavedOnKeyChain = false
    @AppStorage(Constants.Keys.username) private var username: String = ""
    @Environment(AppViewModel.self) var appVM: AppViewModel
    @State private var verifyType: VerifyType?
    @State private var password: String = ""
    @State private var isRequesting = false
    @State private var isPresentedPopover = false

    var body: some View {
        VStack(spacing: 20) {
            title
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Connect your VRChat account")
                        .foregroundStyle(Color(.systemGray))
                        .font(.body)
                    loginFields
                    enterButton
                }
                .navigationDestination(item: $verifyType) { verifyType in
                    OtpView(verifyType: verifyType)
                        .navigationBarBackButtonHidden()
                }
            }
            .frame(height: 300)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            if isSavedOnKeyChain,
               let password = KeychainUtil.shared.getPassword(for: username) {
                self.password = password
            }
        }
    }

    private var title: some View {
        Text(BundleUtil.appName.uppercased())
            .font(.custom("Avenir Next", size: titleFontSize))
            .kerning(titleKerning)
    }

    private var titleFontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 56 : 28
    }

    private var titleKerning: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 28 : 14
    }

    private var loginFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("UserName", text: $username)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            Toggle(isOn: $isSavedOnKeyChain) {
                LabeledContent {
                    Button {
                        isPresentedPopover.toggle()
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .popover(isPresented: $isPresentedPopover) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("In What Way?")
                                .font(.headline)
                                .foregroundStyle(Color(.label))
                            Text(Constants.Messages.helpWithStoringKeychain)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(width: WindowUtil.width * 2 / 3)
                        .padding()
                        .presentationDetents([.fraction(1/4)])
                    }
                } label: {
                    Label {
                        Text("Save Password")
                    } icon: {
                        Image(systemName: "key.icloud")
                    }
                }
                .font(.callout)
                .foregroundStyle(Color(.systemGray))
            }
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 8)
    }

    private var enterButton: some View {
        AsyncButton {
            await loginAction()
        } label: {
            if isRequesting {
                ProgressView()
            } else {
                Text("Enter")
            }
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .disabled(isDisabledEnterButton)
    }

    private func loginAction() async {
        defer { isRequesting = false }
        isRequesting = true
        verifyType = await appVM.login(
            username: username,
            password: password,
            isSavedOnKeyChain: isSavedOnKeyChain
        )
    }

    private var isDisabledEnterButton: Bool {
        isRequesting || username.count < 4 || password.count < 8
    }
}

#Preview {
    LoginView()
        .environment(AppViewModel())
}
