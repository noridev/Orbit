//
//  OtpView.swift
//  Orbit
//
//  Created by makinosp on 2024/08/31.
//

import AsyncSwiftUI
import VRCKit

struct OtpView: View {
    @Environment(AppViewModel.self) var appVM
    @State private var code: String = ""
    @State private var isRequesting = false
    @FocusState private var isCodeFieldFocused: Bool

    var body: some View {
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
                    headerSection
                    otpCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            isCodeFieldFocused = true
        }
        .onDisappear {
            if appVM.step == .loggingIn && appVM.verifyType != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appVM.verifyType = nil
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.green.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 8) {
                Text("Two-Factor Authentication")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Enter the 6-digit code from your \(verifyTypeDescription)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }

    private var otpCard: some View {
        VStack(spacing: 32) {
            pinCodeFields
            verifyButton
            
            if appVM.verifyType == .emailOtp {
                helpText
            }
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .frame(maxWidth: 400)
    }

    private var pinCodeFields: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(
                            index < code.count ? 
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : 
                            LinearGradient(
                                gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 16, height: 16)
                        .overlay {
                            Circle()
                                .stroke(
                                    index < code.count ? Color.clear : Color(.systemGray4),
                                    lineWidth: 1
                                )
                        }
                        .scaleEffect(index < code.count ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: code.count)
                }
            }
            .padding(.bottom, 8)
            
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFieldFocused)
                .opacity(0)
                .frame(height: 1)
                .onChange(of: code) { _, newValue in
                    if newValue.count > 6 {
                        code = String(newValue.prefix(6))
                    }
                    code = newValue.filter { $0.isNumber }
                }
            
            Rectangle()
                .fill(Color.clear)
                .frame(height: 60)
                .contentShape(Rectangle())
                .onTapGesture {
                    isCodeFieldFocused = true
                }
        }
    }

    private var verifyButton: some View {
        AsyncButton {
            await otpAction()
        } label: {
            HStack(spacing: 12) {
                if isRequesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title3)
                }
                
                Text(isRequesting ? "Verifying..." : "Verify Code")
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
                            gradient: Gradient(colors: [Color.green, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 6)
            }
        }
        .disabled(isDisabledVerifyButton)
        .opacity(isDisabledVerifyButton ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabledVerifyButton)
    }

    private var helpText: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Didn't receive a code?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("Check your email's spam folder, then try again.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        }
    }

    private func otpAction() async {
        defer { isRequesting = false }
        isRequesting = true
        await appVM.verifyTwoFA(code: code)
    }

    private var verifyTypeDescription: String {
        appVM.verifyType?.description ?? ""
    }

    private var isDisabledVerifyButton: Bool {
        isRequesting || code.count < 6
    }
}

extension VerifyType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .emailOtp:
            String(localized: "email")
        case .otp, .totp:
            String(localized: "authenticator app")
        }
    }
}

#Preview {
    OtpView()
        .environment(AppViewModel())
}
