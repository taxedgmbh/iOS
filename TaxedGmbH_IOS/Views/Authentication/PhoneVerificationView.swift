import SwiftUI
import Combine

struct PhoneVerificationView: View {
    @StateObject private var phoneService = PhoneVerificationService()
    @Binding var isPresented: Bool
    @Binding var verifiedPhoneNumber: String

    @State private var verificationCode: String = ""
    @State private var showCodeInput = false
    @State private var resendTimer = 0
    @State private var canResend = false
    @State private var selectedCountry: Country = .default
    @State private var showCountryPicker = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.taxedPrimary.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if showCodeInput {
                        codeVerificationView
                    } else {
                        phoneNumberInputView
                    }
                }
            }
            .navigationTitle(showCodeInput ? "phone_verification.enter_code".localized : "phone_verification.verify_phone".localized)
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("Phone Verification")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        isPresented = false
                    }
                    .foregroundColor(.taxedPrimary)
                }
            }
        }
        .alert("common.error".localized, isPresented: .constant(phoneService.errorMessage != nil)) {
            Button("common.ok".localized) {
                phoneService.errorMessage = nil
            }
        } message: {
            Text(phoneService.errorMessage ?? "")
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if resendTimer > 0 {
                resendTimer -= 1
            } else if showCodeInput && !canResend {
                canResend = true
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry)
        }
    }

    // MARK: - Phone Number Input View

    private var phoneNumberInputView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.taxedPrimary)
                    .padding(.top, 40)

                // Title and description
                VStack(spacing: 12) {
                    Text("phone_verification.title".localized)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("phone_verification.description".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Phone number input
                VStack(alignment: .leading, spacing: 8) {
                    Text("phone_verification.mobile_number".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        // Country selector button
                        Button {
                            showCountryPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedCountry.flag)
                                    .font(.title3)
                                Text("+\(selectedCountry.dialCode)")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }

                        TextField(selectedCountry.format ?? "123456789", text: $phoneService.phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                // Send code button
                Button {
                    Task {
                        await sendCode()
                    }
                } label: {
                    HStack {
                        if phoneService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("phone_verification.send_code".localized)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(phoneService.phoneNumber.isEmpty ? Color.gray : Color.taxedPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(phoneService.phoneNumber.isEmpty || phoneService.isLoading)
                .padding(.horizontal)
                .padding(.top, 8)

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    PhoneInfoRow(icon: "checkmark.circle.fill", text: "phone_verification.info.swiss_numbers".localized)
                    PhoneInfoRow(icon: "lock.fill", text: "phone_verification.info.privacy".localized)
                    PhoneInfoRow(icon: "message.fill", text: "phone_verification.info.sms_code".localized)
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer()
            }
        }
    }

    // MARK: - Code Verification View

    private var codeVerificationView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.taxedPrimary)
                    .padding(.top, 40)

                // Title and description
                VStack(spacing: 12) {
                    Text("phone_verification.enter_code_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("phone_verification.enter_code_description".localized(with: phoneService.formatForDisplay(phoneService.phoneNumber)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // TEST MODE: Show test code to developer
                if phoneService.useTestMode {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.caption)
                            Text("phone_verification.test_mode".localized)
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.orange)

                        Text("phone_verification.test_code".localized(with: phoneService.testVerificationCode))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Verification code input
                VStack(spacing: 16) {
                    CodeInputView(code: $verificationCode, length: 6)
                        .padding(.horizontal)

                    // Verify button
                    Button {
                        Task {
                            await verifyCode()
                        }
                    } label: {
                        HStack {
                            if phoneService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("phone_verification.verify".localized)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(verificationCode.count == 6 ? Color.taxedPrimary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(verificationCode.count != 6 || phoneService.isLoading)
                    .padding(.horizontal)
                }

                // Resend code
                VStack(spacing: 12) {
                    if canResend {
                        Button {
                            Task {
                                await resendCode()
                            }
                        } label: {
                            Text("phone_verification.resend_code".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.taxedPrimary)
                        }
                        .disabled(phoneService.isLoading)
                    } else {
                        Text("phone_verification.resend_code_timer".localized(with: resendTimer))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        showCodeInput = false
                        verificationCode = ""
                        phoneService.reset()
                    } label: {
                        Text("phone_verification.change_number".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
        }
    }

    // MARK: - Actions

    private func sendCode() async {
        do {
            try await phoneService.sendVerificationCode(to: phoneService.phoneNumber, country: selectedCountry)
            withAnimation {
                showCodeInput = true
            }
            resendTimer = 60 // 60 seconds cooldown
            canResend = false
        } catch {
            phoneService.errorMessage = error.localizedDescription
        }
    }

    private func verifyCode() async {
        do {
            _ = try await phoneService.verifyCode(verificationCode)
            verifiedPhoneNumber = phoneService.phoneNumber
            isPresented = false
        } catch {
            phoneService.errorMessage = error.localizedDescription
            verificationCode = ""
        }
    }

    private func resendCode() async {
        verificationCode = ""
        do {
            try await phoneService.resendVerificationCode()
            resendTimer = 60
            canResend = false
        } catch {
            phoneService.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Code Input View

struct CodeInputView: View {
    @Binding var code: String
    let length: Int
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<length, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(width: 45, height: 55)

                    RoundedRectangle(cornerRadius: 12)
                        .stroke(code.count == index ? Color.taxedPrimary : Color.clear, lineWidth: 2)
                        .frame(width: 45, height: 55)

                    Text(getDigit(at: index))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .overlay(
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0)
                .onChange(of: code) { _, newValue in
                    // Limit to 6 digits
                    if newValue.count > length {
                        code = String(newValue.prefix(length))
                    }
                    // Only allow numbers
                    code = newValue.filter { $0.isNumber }
                }
        )
        .onAppear {
            isFocused = true
        }
    }

    private func getDigit(at index: Int) -> String {
        guard code.count > index else { return "" }
        return String(Array(code)[index])
    }
}

// MARK: - Phone Info Row

struct PhoneInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.taxedPrimary)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Preview

struct PhoneVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneVerificationView(
            isPresented: .constant(true),
            verifiedPhoneNumber: .constant("")
        )
    }
}
