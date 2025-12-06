//
//  BugReportSheet.swift
//  TaxedGmbH_IOS
//
//  UI for submitting screenshot-triggered bug reports
//  Features voice-enabled comment input using InlineVoiceTextEditor
//

import SwiftUI

struct BugReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject private var bugReportService = BugReportService.shared

    let screenshot: UIImage
    let screenName: String

    @State private var comment: String = ""
    @State private var showSuccessMessage: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "ladybug.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 227/255, green: 30/255, blue: 36/255))

                        Text("Report a Bug")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Thank you for helping us improve the app!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Screenshot Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Screenshot")
                            .font(.headline)

                        Image(uiImage: screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }

                    // Screen Name (Read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Screen")
                            .font(.headline)

                        HStack {
                            Image(systemName: "app.fill")
                                .foregroundColor(.secondary)
                            Text(screenName)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Comment with Voice Input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("What went wrong?")
                                .font(.headline)

                            Spacer()

                            // Character count
                            if !comment.isEmpty {
                                Text("\(comment.count) chars")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        InlineVoiceTextEditor(
                            text: $comment,
                            placeholder: "Describe the issue... You can use voice input by tapping the microphone!",
                            minHeight: 120,
                            backgroundColor: .clear,
                            cornerRadius: 12,
                            borderColor: Color.cyan.opacity(0.3)
                        )
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        Label {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Success Message
                    if showSuccessMessage {
                        Label {
                            Text("Bug report submitted successfully! Thank you.")
                                .font(.caption)
                                .foregroundColor(.green)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Submit Button
                    Button(action: submitBugReport) {
                        HStack {
                            if bugReportService.isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }

                            Text(bugReportService.isSubmitting ? "Submitting..." : "Submit Bug Report")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || bugReportService.isSubmitting
                                ? Color.gray
                                : Color(red: 227/255, green: 30/255, blue: 36/255)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || bugReportService.isSubmitting)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("Bug Report")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(bugReportService.isSubmitting)
                }
            }
        }
    }

    // MARK: - Submit Bug Report

    private func submitBugReport() {
        guard let user = authService.user else {
            errorMessage = "You must be logged in to submit a bug report"
            return
        }

        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else {
            errorMessage = "Please describe the issue"
            return
        }

        Task {
            do {
                errorMessage = nil

                _ = try await bugReportService.submitBugReport(
                    screenshot: screenshot,
                    comment: trimmedComment,
                    screenName: screenName,
                    user: user
                )

                await MainActor.run {
                    showSuccessMessage = true

                    // Auto-dismiss after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }

            } catch {
                await MainActor.run {
                    errorMessage = "Failed to submit bug report: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BugReportSheet(
        screenshot: UIImage(systemName: "photo")!,
        screenName: "DocumentDetailView"
    )
    .environmentObject(AuthenticationService())
}
