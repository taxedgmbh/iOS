//
//  PhoneVerificationView_LiquidGlass.swift
//  TaxedGmbH_IOS
//
//  Liquid Glass Phone Verification with seamless 2FA integration
//

import SwiftUI
import Combine

struct PhoneVerificationView_LiquidGlass: View {
    @StateObject private var phoneService = PhoneVerificationService()
    @Binding var isPresented: Bool
    @Binding var verifiedPhoneNumber: String

    @State private var verificationCode: String = ""
    @State private var showCodeInput = false
    @State private var resendTimer = 0
    @State private var canResend = false
    @State private var selectedCountry: Country = .default
    @State private var showCountryPicker = false
    @State private var contentOpacity: Double = 0
    @State private var codeDigitScale: [CGFloat] = Array(repeating: 1.0, count: 6)

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Animated Glass Background
            AnimatedGlassBackground()

            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .floatingButton()
                    }

                    Spacer()

                    Text(showCodeInput ? "Verify Code" : "Phone Verification")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Placeholder for balance
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding()

                ScrollView {
                    VStack(spacing: 32) {
                        if showCodeInput {
                            codeVerificationGlassView
                        } else {
                            phoneNumberInputGlassView
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: .constant(phoneService.errorMessage != nil)) {
            Button("OK") {
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
            CountryPickerGlassView(selectedCountry: $selectedCountry)
        }
        .onAppear {
            animateEntrance()
        }
    }

    // MARK: - Phone Number Input Glass View

    private var phoneNumberInputGlassView: some View {
        VStack(spacing: 32) {
            // Icon with Glass
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.6),
                                        Color.green.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.green)
            }
            .glow(color: .green, radius: 20)

            // Title and Description
            VStack(spacing: 12) {
                Text("Verify Your Phone")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("We'll send you a 6-digit verification code to confirm your phone number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Phone Input in Glass Card
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    // Country Selector
                    Button {
                        showCountryPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Text(selectedCountry.flag)
                                .font(.title3)
                            Text("+\(selectedCountry.dialCode)")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                    }
                    .glassCard(cornerRadius: 12, borderColor: .green.opacity(0.2))

                    // Phone Number Field
                    HStack {
                        TextField(selectedCountry.format ?? "123456789", text: $phoneService.phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(12)
                    .glassCard(cornerRadius: 12, borderColor: .green.opacity(0.2))
                }

                // Send Code Button
                Button {
                    Task {
                        await sendCode()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if phoneService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.headline)
                            Text("Send Verification Code")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        phoneService.phoneNumber.isEmpty ?
                        LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(
                        color: phoneService.phoneNumber.isEmpty ? .clear : Color.green.opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                }
                .disabled(phoneService.phoneNumber.isEmpty || phoneService.isLoading)
            }
            .padding(24)
            .glassCard(cornerRadius: 24, borderColor: .white.opacity(0.3))
            .padding(.horizontal)

            // Info Points
            VStack(spacing: 12) {
                PhoneVerificationInfoRow(icon: "checkmark.shield.fill", text: "Secure & Private", color: .green)
                PhoneVerificationInfoRow(icon: "message.fill", text: "SMS Code Delivery", color: .blue)
                PhoneVerificationInfoRow(icon: "clock.fill", text: "Code valid for 10 minutes", color: .orange)
            }
            .padding(.horizontal)
        }
        .opacity(contentOpacity)
    }

    // MARK: - Code Verification Glass View

    private var codeVerificationGlassView: some View {
        VStack(spacing: 32) {
            // Icon with Glass
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.6),
                                        Color.blue.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .glow(color: .blue, radius: 20)

            // Title and Description
            VStack(spacing: 12) {
                Text("Enter Verification Code")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("We sent a code to \(phoneService.formatForDisplay(phoneService.phoneNumber))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // TEST MODE Banner (if enabled)
            if phoneService.useTestMode {
                HStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.caption)
                    Text("TEST MODE: \(phoneService.testVerificationCode)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.orange)
                .padding(12)
                .glassCard(cornerRadius: 12, borderColor: .orange.opacity(0.3), glowColor: .orange.opacity(0.2))
                .padding(.horizontal)
            }

            // Code Input in Glass Card
            VStack(spacing: 24) {
                // Glass Code Input
                GlassCodeInputView(code: $verificationCode, length: 6)
                    .padding(.top, 8)

                // Verify Button
                Button {
                    Task {
                        await verifyCode()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if phoneService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.headline)
                            Text("Verify Code")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        verificationCode.count == 6 ?
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(
                        color: verificationCode.count == 6 ? Color.blue.opacity(0.3) : .clear,
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                }
                .disabled(verificationCode.count != 6 || phoneService.isLoading)

                // Resend/Change Number
                VStack(spacing: 12) {
                    if canResend {
                        Button {
                            Task {
                                await resendCode()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                Text("Resend Code")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                        }
                        .disabled(phoneService.isLoading)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("Resend in \(resendTimer)s")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }

                    Button {
                        withAnimation {
                            showCodeInput = false
                            verificationCode = ""
                            phoneService.reset()
                        }
                    } label: {
                        Text("Change Phone Number")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
            .glassCard(cornerRadius: 24, borderColor: .white.opacity(0.3))
            .padding(.horizontal)
        }
        .opacity(contentOpacity)
    }

    // MARK: - Actions

    private func sendCode() async {
        do {
            try await phoneService.sendVerificationCode(to: phoneService.phoneNumber, country: selectedCountry)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showCodeInput = true
            }
            resendTimer = 60
            canResend = false
        } catch {
            phoneService.errorMessage = error.localizedDescription
        }
    }

    private func verifyCode() async {
        do {
            _ = try await phoneService.verifyCode(verificationCode)
            verifiedPhoneNumber = phoneService.phoneNumber

            // Success animation
            if !reduceMotion {
                for i in 0..<6 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(Double(i) * 0.05)) {
                        codeDigitScale[i] = 1.2
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(Double(i) * 0.05 + 0.1)) {
                        codeDigitScale[i] = 1.0
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isPresented = false
            }
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

    private func animateEntrance() {
        if !reduceMotion {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                contentOpacity = 1.0
            }
        } else {
            contentOpacity = 1.0
        }
    }
}

// MARK: - Glass Code Input View

struct GlassCodeInputView: View {
    @Binding var code: String
    let length: Int
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<length, id: \.self) { index in
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .frame(width: 48, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    code.count == index ? Color.blue : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .shadow(
                            color: code.count == index ? Color.blue.opacity(0.2) : .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )

                    // Digit
                    Text(getDigit(at: index))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
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
                    if newValue.count > length {
                        code = String(newValue.prefix(length))
                    }
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

struct PhoneVerificationInfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .glow(color: color, radius: 4)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Country Picker Glass View

struct CountryPickerGlassView: View {
    @Binding var selectedCountry: Country
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            countryListView
        }
    }

    private var countryListView: some View {
        countryListContent
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
    }

    private var doneButton: some View {
        Button("Done") {
            dismiss()
        }
        .foregroundColor(.blue)
    }

    private var countryListContent: some View {
        ZStack {
            AnimatedGlassBackground()

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Country.all) { country in
                        countryButton(country)
                    }
                }
                .padding()
            }
        }
    }

    private func countryButton(_ country: Country) -> some View {
        Button {
            selectedCountry = country
            dismiss()
        } label: {
            HStack {
                Text(country.flag)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text("+\(country.dialCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if country.id == selectedCountry.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(16)
        }
        .glassCard(
            cornerRadius: 16,
            borderColor: country.id == selectedCountry.id ? .green.opacity(0.3) : .white.opacity(0.2)
        )
    }
}
