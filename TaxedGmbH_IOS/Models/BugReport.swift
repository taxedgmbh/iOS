//
//  BugReport.swift
//  TaxedGmbH_IOS
//
//  Screenshot-triggered bug report model
//  Stores user feedback with screenshot and context
//

import Foundation
import FirebaseFirestore

struct BugReport: Codable, Identifiable {
    var id: String?
    let userId: String
    let userEmail: String
    let screenshotUrl: String
    let comment: String
    let screenName: String
    let createdAt: Date
    var status: BugReportStatus

    init(
        id: String? = nil,
        userId: String,
        userEmail: String,
        screenshotUrl: String,
        comment: String,
        screenName: String,
        createdAt: Date = Date(),
        status: BugReportStatus = .open
    ) {
        self.id = id
        self.userId = userId
        self.userEmail = userEmail
        self.screenshotUrl = screenshotUrl
        self.comment = comment
        self.screenName = screenName
        self.createdAt = createdAt
        self.status = status
    }

    // MARK: - Firestore Serialization

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "userEmail": userEmail,
            "screenshotUrl": screenshotUrl,
            "comment": comment,
            "screenName": screenName,
            "createdAt": Timestamp(date: createdAt),
            "status": status.rawValue
        ]

        if let id = id {
            dict["id"] = id
        }

        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> BugReport? {
        guard let userId = dict["userId"] as? String,
              let userEmail = dict["userEmail"] as? String,
              let screenshotUrl = dict["screenshotUrl"] as? String,
              let comment = dict["comment"] as? String,
              let screenName = dict["screenName"] as? String,
              let createdAtTimestamp = dict["createdAt"] as? Timestamp,
              let statusString = dict["status"] as? String,
              let status = BugReportStatus(rawValue: statusString) else {
            return nil
        }

        return BugReport(
            id: dict["id"] as? String,
            userId: userId,
            userEmail: userEmail,
            screenshotUrl: screenshotUrl,
            comment: comment,
            screenName: screenName,
            createdAt: createdAtTimestamp.dateValue(),
            status: status
        )
    }
}

enum BugReportStatus: String, Codable {
    case open = "open"
    case inProgress = "in_progress"
    case resolved = "resolved"
}
