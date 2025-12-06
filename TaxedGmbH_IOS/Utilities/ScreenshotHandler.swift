//
//  ScreenshotHandler.swift
//  TaxedGmbH_IOS
//
//  Detects when user takes a screenshot and triggers bug report sheet
//

import Foundation
import SwiftUI
import UIKit
import Photos
import Combine

@MainActor
class ScreenshotHandler: ObservableObject {
    @Published var showBugReportSheet: Bool = false
    @Published var capturedScreenshot: UIImage?
    @Published var capturedScreenName: String = "Unknown Screen"

    private var screenTracker: ScreenTracker

    init(screenTracker: ScreenTracker = ScreenTracker.shared) {
        self.screenTracker = screenTracker
        setupScreenshotNotification()
    }

    // MARK: - Setup Screenshot Detection

    private func setupScreenshotNotification() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleScreenshot()
            }
        }

        print("📸 Screenshot detection enabled")
    }

    // MARK: - Handle Screenshot

    private func handleScreenshot() async {
        print("📸 Screenshot detected!")

        // Capture current screen name
        capturedScreenName = screenTracker.currentScreen

        // Try to get the screenshot from Photos Library
        if let screenshot = await fetchLatestScreenshot() {
            capturedScreenshot = screenshot
            showBugReportSheet = true
            print("   ✅ Screenshot captured, showing bug report sheet")
        } else {
            print("   ⚠️ Could not fetch screenshot - Photos permission may be denied")
            // Still show bug report sheet with placeholder image
            capturedScreenshot = createPlaceholderImage()
            showBugReportSheet = true
        }
    }

    // MARK: - Fetch Latest Screenshot

    /// Fetch the most recent screenshot from Photos Library
    private func fetchLatestScreenshot() async -> UIImage? {
        // Request Photos permission
        let status = await requestPhotosPermission()

        guard status == .authorized else {
            print("   ⚠️ Photos permission not granted: \(status)")
            return nil
        }

        // Create fetch options to get only screenshots
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)

        // Fetch the screenshot
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        guard let asset = fetchResult.firstObject else {
            print("   ⚠️ No screenshots found in Photos Library")
            return nil
        }

        // Request the image
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = true
            options.isNetworkAccessAllowed = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// Request Photos library access permission
    private func requestPhotosPermission() async -> PHAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

            if currentStatus == .notDetermined {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    continuation.resume(returning: status)
                }
            } else {
                continuation.resume(returning: currentStatus)
            }
        }
    }

    /// Create a placeholder image if screenshot fetch fails
    private func createPlaceholderImage() -> UIImage {
        let size = CGSize(width: 300, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Background
            UIColor.systemGray6.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Icon
            let icon = UIImage(systemName: "photo.fill")!
            let iconSize: CGFloat = 100
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            icon.draw(in: iconRect, blendMode: .normal, alpha: 0.3)
        }
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
