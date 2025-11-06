# Storage & Data Architecture Redesign

## Executive Summary

This document outlines a comprehensive redesign of the TaxedGmbH storage and data architecture to solve critical problems with file management, data consistency, and cover sheet updates. The redesign introduces **document-centric storage**, **structured metadata as source of truth**, and **event-driven PDF regeneration**.

---

## Problem Statement

### Current Storage Issues

The current storage architecture splits related files across **THREE separate locations**:

```
documents/{userId}/{year}/{category}/{subcategory}/SAL_1234_uuid_salary.pdf  ← Original
covers/{userId}/{year}/{documentId}_cover.pdf                                 ← Cover sheet (SEPARATE!)
processed/{userId}/{year}/processed_{documentId}.pdf                          ← Merged doc (SEPARATE!)
```

**Critical Problems:**
1. ❌ Cannot keep cover sheets with their original documents
2. ❌ Cannot move documents between categories cleanly (files get orphaned)
3. ❌ Cannot update cover sheets fluently (must re-download, re-generate, re-upload)
4. ❌ No referential integrity between related files
5. ❌ No way to detect when cover sheets become stale

### Current Data Flow Issues

Beyond storage, the entire data architecture has fundamental problems:

**Problem: Stale Cover Sheets**
```
User changes name: "Hans Müller" → "Hans Peter Müller"
↓
Cover sheets still show "Hans Müller"
↓
No detection mechanism
↓
Outdated PDFs persist forever
```

**Problem: No Event-Driven Updates**
- Profile changes don't propagate to documents
- No version tracking for data changes
- No automatic regeneration system
- PDFs treated as immutable instead of generated artifacts

**Problem: Scattered Data Management**
- User profile stored in Firestore
- Document metadata stored in Firestore
- PDFs stored in Storage
- No coordination between these layers when data changes

---

## Proposed Solution: Comprehensive Architecture

### 1. Document-Centric Storage

**New File Structure:**
```
documents/
└── {userId}/
    └── {taxYear}/
        └── {category}/
            └── {subcategory}/
                └── {documentId}/
                    ├── original.pdf          ← Original uploaded document
                    ├── cover.pdf             ← Generated cover sheet
                    └── complete.pdf          ← Merged (cover + original)
```

**Benefits:**
- ✅ All related files stay together
- ✅ Moving document = moving ONE folder
- ✅ Deleting document = deleting ONE folder
- ✅ No orphaned files
- ✅ Clear referential integrity
- ✅ Atomic operations
- ✅ Fluent in-place updates

**Example Flow:**
```swift
// Move from income/salary to income/freelance
FROM: documents/user123/2024/income/salary/doc-abc-123/
TO:   documents/user123/2024/income/freelance/doc-abc-123/

// All 3 files move together automatically:
  ├── original.pdf   ← Moves with folder
  ├── cover.pdf      ← Moves with folder
  └── complete.pdf   ← Moves with folder
```

---

### 2. Structured Data as Source of Truth

**Paradigm Shift:** Firestore metadata is source of truth, PDFs are generated artifacts.

**Architecture:**
```
Source of Truth          Generated Artifacts
────────────────         ───────────────────
Firestore Document  →    original.pdf (uploaded, immutable)
   ↓                     cover.pdf (generated from metadata)
User Profile Data   →    complete.pdf (merged from above)
```

**Key Principle:** PDFs are **cached/generated files**, not authoritative data. Always regenerate from current Firestore data when needed.

---

### 3. Profile Versioning System

**Problem:** User updates profile, but cover sheets don't reflect changes.

**Solution:** Track profile versions and PDF generation versions.

**Enhanced User Model:**
```swift
struct User: Codable {
    // ... existing fields ...

    // NEW: Version tracking
    var profileVersion: Int = 1              // Increment on every profile update
    var profileLastUpdatedAt: Date           // Track when profile changed
}
```

**Enhanced TaxDocument Model:**
```swift
struct TaxDocument: Codable {
    // ... existing fields ...

    // NEW: PDF Generation Tracking
    var pdfGenerationStatus: PDFGenerationStatus?  // "pending", "generating", "completed", "failed"
    var pdfLastGeneratedAt: Date?                  // When PDF was last created
    var generatedWithProfileVersion: Int?          // Which profile version was used
    var needsRegeneration: Bool = false            // Flag for stale PDFs
}

enum PDFGenerationStatus: String, Codable {
    case pending = "pending"           // Queued for generation
    case generating = "generating"     // Currently being generated
    case completed = "completed"       // Successfully generated
    case failed = "failed"             // Generation failed
}
```

**Detection Logic:**
```swift
func isPDFStale(document: TaxDocument, user: User) -> Bool {
    guard let generatedVersion = document.generatedWithProfileVersion else {
        return true  // Never generated, definitely stale
    }

    return generatedVersion < user.profileVersion
}
```

---

### 4. Background PDF Regeneration Service

**Design Decision:** Background pre-generation (chosen by user over on-demand)

**New Service: PDFRegenerationService**

```swift
@MainActor
class PDFRegenerationService: ObservableObject {
    static let shared = PDFRegenerationService()

    @Published var regenerationQueue: [RegenerationTask] = []
    @Published var isProcessing: Bool = false

    private let firestoreService = FirestoreService.shared
    private let coverSheetService = CoverSheetService.shared

    struct RegenerationTask {
        let documentId: String
        let reason: RegenerationReason
        let priority: Priority
        let queuedAt: Date
    }

    enum RegenerationReason {
        case profileChanged
        case categoryChanged
        case manualTrigger
        case preSubmissionCheck
    }

    enum Priority {
        case high      // User-triggered, blocking
        case normal    // Category change
        case low       // Background profile change
    }

    /// Queue a document for regeneration
    func queueRegeneration(
        documentId: String,
        reason: RegenerationReason,
        priority: Priority = .normal
    ) {
        let task = RegenerationTask(
            documentId: documentId,
            reason: reason,
            priority: priority,
            queuedAt: Date()
        )
        regenerationQueue.append(task)

        // Start processing if not already running
        if !isProcessing {
            Task {
                await processQueue()
            }
        }
    }

    /// Process regeneration queue in background
    private func processQueue() async {
        guard !regenerationQueue.isEmpty else { return }

        isProcessing = true

        // Sort by priority
        regenerationQueue.sort { $0.priority.rawValue < $1.priority.rawValue }

        while let task = regenerationQueue.first {
            await regenerateDocument(task)
            regenerationQueue.removeFirst()

            // Small delay to avoid overwhelming server
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }

        isProcessing = false
    }

    /// Regenerate a single document's PDFs
    private func regenerateDocument(_ task: RegenerationTask) async {
        print("🔄 Regenerating PDFs for document: \(task.documentId)")
        print("   Reason: \(task.reason)")

        do {
            // Fetch document and user
            guard let document = try await firestoreService.getDocument(documentId: task.documentId),
                  let user = try await firestoreService.getUser(userId: document.customerId) else {
                print("❌ Failed to fetch document or user")
                return
            }

            // Mark as generating
            var updatedDoc = document
            updatedDoc.pdfGenerationStatus = .generating
            try await firestoreService.updateDocument(updatedDoc)

            // Generate new cover sheet and merged PDF
            let (coverUrl, completeUrl) = try await coverSheetService.processCoverSheet(
                for: document,
                user: user
            )

            // Update document with new URLs and version
            updatedDoc.coverSheetUrl = coverUrl
            updatedDoc.processedDocumentUrl = completeUrl
            updatedDoc.pdfGenerationStatus = .completed
            updatedDoc.pdfLastGeneratedAt = Date()
            updatedDoc.generatedWithProfileVersion = user.profileVersion
            updatedDoc.needsRegeneration = false

            try await firestoreService.updateDocument(updatedDoc)

            print("✅ PDF regeneration completed for: \(task.documentId)")
        } catch {
            print("❌ PDF regeneration failed: \(error)")

            // Mark as failed
            if var doc = try? await firestoreService.getDocument(documentId: task.documentId) {
                doc.pdfGenerationStatus = .failed
                try? await firestoreService.updateDocument(doc)
            }
        }
    }

    /// Find all documents needing regeneration
    func findStaleDocuments(for userId: String) async throws -> [TaxDocument] {
        let user = try await firestoreService.getUser(userId: userId)
        let documents = try await firestoreService.getDocumentsForCustomer(customerId: userId)

        return documents.filter { document in
            guard let generatedVersion = document.generatedWithProfileVersion else {
                return true  // Never generated
            }
            return generatedVersion < user.profileVersion
        }
    }

    /// Regenerate all stale documents for a user
    func regenerateAllStale(for userId: String) async {
        print("🔍 Finding stale documents for user: \(userId)")

        do {
            let staleDocuments = try await findStaleDocuments(for: userId)
            print("   Found \(staleDocuments.count) stale documents")

            for document in staleDocuments {
                queueRegeneration(
                    documentId: document.id,
                    reason: .profileChanged,
                    priority: .low
                )
            }
        } catch {
            print("❌ Failed to find stale documents: \(error)")
        }
    }
}
```

**Key Features:**
- Queue-based processing (non-blocking)
- Priority levels (high/normal/low)
- Automatic failure handling
- Batch processing with delays
- Version tracking on completion

---

### 5. Event-Driven Architecture

**Design:** Use Combine to publish events and automatically trigger regeneration.

**Enhanced AuthenticationService:**
```swift
class AuthenticationService: ObservableObject {
    // ... existing code ...

    // NEW: Profile change publisher
    let profileDidChange = PassthroughSubject<User, Never>()

    func updateUser(userId: String, data: [String: Any]) async throws {
        // ... existing update code ...

        // Increment profile version
        var updatedData = data
        let currentVersion = user?.profileVersion ?? 1
        updatedData["profileVersion"] = currentVersion + 1
        updatedData["profileLastUpdatedAt"] = Timestamp(date: Date())

        // Update in Firestore
        try await firestoreService.updateUser(userId: userId, data: updatedData)

        // Fetch updated user
        let updatedUser = try await firestoreService.getUser(userId: userId)

        // Publish event
        profileDidChange.send(updatedUser)

        print("✅ Profile updated, version: \(currentVersion + 1)")
    }
}
```

**Enhanced DocumentManager:**
```swift
class DocumentManager: ObservableObject {
    // ... existing code ...

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to profile changes
        authService.profileDidChange
            .sink { [weak self] user in
                Task {
                    await self?.handleProfileChange(user)
                }
            }
            .store(in: &cancellables)
    }

    private func handleProfileChange(_ user: User) async {
        print("🔔 Profile changed, regenerating stale PDFs...")

        // Queue all user's documents for regeneration
        await PDFRegenerationService.shared.regenerateAllStale(for: user.id)
    }
}
```

**Flow Diagram:**
```
User Updates Profile
    ↓
AuthenticationService.updateUser()
    ↓
Increment profileVersion
    ↓
Save to Firestore
    ↓
Publish profileDidChange event
    ↓
DocumentManager receives event
    ↓
Queue stale documents for regeneration
    ↓
PDFRegenerationService processes queue
    ↓
Background regeneration (non-blocking)
    ↓
PDFs updated with current profile data
```

---

### 6. Regeneration Triggers (User Decisions)

Based on user input, PDFs regenerate on these triggers:

#### ✅ **1. Profile Changes** (Background, Low Priority)
```swift
// Any change to user profile
- Name change
- Address change
- AHV number change
- Marital status change
- Canton/Municipality change

→ Trigger: profileDidChange event
→ Priority: Low (background)
→ Processing: Queue all user documents
```

#### ✅ **2. Document Recategorization** (Normal Priority)
```swift
// User changes document category
DocumentManager.remapDocument(to: newCategory)

→ Trigger: Category change
→ Priority: Normal
→ Processing: Queue this document only
```

#### ✅ **3. Pre-Submission Check** (High Priority, Blocking)
```swift
// Before tax submission
func prepareForSubmission() async {
    // Find and regenerate any stale documents
    let staleCount = await regenerateAllStale(blocking: true)
    print("Regenerated \(staleCount) stale documents")
}

→ Trigger: Manual submission button
→ Priority: High (user waiting)
→ Processing: Block until complete
```

#### ❌ **NOT Using Profile Snapshots**
User decided against storing profile snapshots in documents. Always use current user data for regeneration.

---

### 7. Enhanced Firestore Schema

**Complete Document Structure:**
```javascript
documents/{documentId} {
  // Core Identity
  id: "doc-abc-123",
  customerId: "user-xyz-789",
  name: "Salary_Statement.pdf",

  // Classification
  category: "income",                    // Old enum-based category
  subcategory: "salary",                 // Old subcategory
  taxCategoryType: "salary",             // New unified category
  taxYear: 2024,

  // File Storage (Document-Centric Paths)
  storageUrl: "gs://.../documents/user/2024/income/salary/doc-abc-123/original.pdf",
  coverSheetUrl: "gs://.../documents/user/2024/income/salary/doc-abc-123/cover.pdf",
  processedDocumentUrl: "gs://.../documents/user/2024/income/salary/doc-abc-123/complete.pdf",
  thumbnailUrl: "gs://.../thumbnails/doc-abc-123.jpg",

  // PDF Generation Tracking (NEW)
  pdfGenerationStatus: "completed",      // "pending" | "generating" | "completed" | "failed"
  pdfLastGeneratedAt: Timestamp,         // When PDFs were last generated
  generatedWithProfileVersion: 7,        // Which user profile version was used
  needsRegeneration: false,              // Flag for stale PDFs

  // AI Processing
  aiConfidence: 0.85,
  extractedText: "...",
  aiSummary: "Salary statement from...",

  // Status & Workflow
  status: "approved",                    // Document approval status
  workflowStatus: "coverGenerated",      // Workflow progress
  coverSheetGenerated: true,

  // Metadata
  attachmentNumber: "SAL_5432",          // Swiss tax attachment number
  amount: 85000.0,
  currency: "CHF",

  // Notes
  userNotes: "Annual salary 2024",
  expertNotes: null,

  // Timestamps
  uploadedAt: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Complete User Structure:**
```javascript
users/{userId} {
  // Identity
  id: "user-xyz-789",
  email: "hans.mueller@example.com",
  name: "Hans Müller",
  role: "customer",

  // Profile Version Tracking (NEW)
  profileVersion: 7,                     // Increment on every update
  profileLastUpdatedAt: Timestamp,       // Track when profile changed

  // Person Information
  person1Name: "Hans Müller",
  person1AhvNumber: "756.1234.5678.97",
  person2Name: null,                     // Spouse/Partner
  person2AhvNumber: null,

  // Swiss Tax Information
  canton: "ZH",
  municipality: "Zürich",
  municipalityId: "261",                 // BFS number
  maritalStatus: "single",
  numberOfChildren: 0,

  // Address
  street: "Bahnhofstrasse 1",
  postalCode: "8001",
  city: "Zürich",

  // Contact
  phone: "+41 79 123 45 67",
  profileImageUrl: "gs://...",

  // Expert Assignment
  assignedExpertId: "expert-123",

  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

## Implementation Plan

### **Phase 1: Storage Foundation** (Week 1)

**Goal:** Implement document-centric storage structure.

**Tasks:**
1. Update `StorageService.generateStoragePath()` to include `{documentId}/` folder
2. Add `documentId` parameter to all upload functions
3. New path format: `documents/{userId}/{year}/{category}/{subcategory}/{documentId}/original.pdf`
4. Update `CoverSheetService` to use same folder:
   - Cover: `{documentId}/cover.pdf`
   - Complete: `{documentId}/complete.pdf`
5. Add `moveDocumentFolder()` function for recategorization
6. Test file operations (upload, move, delete)

**Success Criteria:**
- New uploads use new structure
- Cover sheets stay with originals
- Moving documents works atomically

---

### **Phase 2: Metadata Enhancement** (Week 2)

**Goal:** Add version tracking to data models.

**Tasks:**
1. Update `User.swift`:
   - Add `profileVersion: Int = 1`
   - Add `profileLastUpdatedAt: Date`
   - Update `toDictionary()` and `fromDictionary()`
2. Update `TaxDocument.swift`:
   - Add `pdfGenerationStatus: PDFGenerationStatus?`
   - Add `pdfLastGeneratedAt: Date?`
   - Add `generatedWithProfileVersion: Int?`
   - Add `needsRegeneration: Bool = false`
   - Add `PDFGenerationStatus` enum
3. Update `FirestoreService`:
   - Modify user update to increment `profileVersion`
   - Add queries for stale documents
4. Database migration script (if needed for existing data)

**Success Criteria:**
- All new users have `profileVersion = 1`
- Profile updates increment version
- Documents track generation version

---

### **Phase 3: Regeneration Service** (Week 3)

**Goal:** Build background PDF regeneration system.

**Tasks:**
1. Create `PDFRegenerationService.swift`:
   - Queue-based processing
   - Priority levels (high/normal/low)
   - `queueRegeneration()` method
   - `processQueue()` background processor
   - `regenerateDocument()` core logic
   - `findStaleDocuments()` detection
   - `regenerateAllStale()` batch processing
2. Update `CoverSheetService`:
   - Support in-place overwrite of existing PDFs
   - Use document-centric paths
3. Add regeneration UI:
   - Progress indicator
   - Manual trigger button
   - "Stale PDFs" warning badge
4. Testing:
   - Test queue processing
   - Test failure handling
   - Test priority ordering

**Success Criteria:**
- Regeneration queue processes in background
- Failures don't crash the queue
- Users can manually trigger regeneration

---

### **Phase 4: Event-Driven System** (Week 4)

**Goal:** Automatic regeneration on profile changes.

**Tasks:**
1. Update `AuthenticationService`:
   - Add `profileDidChange` publisher (Combine)
   - Increment `profileVersion` on updates
   - Publish events after profile changes
2. Update `DocumentManager`:
   - Subscribe to `profileDidChange`
   - Handle event → queue regeneration
   - Add cancellables management
3. Add regeneration triggers:
   - Profile change → low priority queue
   - Category change → normal priority
   - Pre-submission → high priority blocking
4. Add settings:
   - Toggle auto-regeneration on/off
   - Choose regeneration timing

**Success Criteria:**
- Profile changes automatically queue regeneration
- Category changes trigger immediate regeneration
- Pre-submission blocks until all PDFs updated

---

### **Phase 5: UI & Polish** (Week 5)

**Goal:** User-facing features and refinements.

**Tasks:**
1. Document detail view enhancements:
   - Show "PDF version" info
   - Show "Generated with profile v7" badge
   - "Regenerate now" button
   - Stale PDF warning icon
2. Settings screen:
   - Auto-regeneration toggle
   - "Regenerate all documents" button
   - View regeneration queue
   - Clear failed jobs
3. Dashboard indicators:
   - Badge showing stale document count
   - Progress bar for regeneration queue
4. Accessibility:
   - VoiceOver labels for regeneration status
   - Haptic feedback on completion
5. Localization:
   - Add strings for all new UI elements

**Success Criteria:**
- Users can see PDF version info
- Users can manually trigger regeneration
- Clear visual feedback for stale PDFs

---

### **Phase 6: Migration & Testing** (Week 6)

**Goal:** Migrate existing documents and comprehensive testing.

**Migration Strategy (Hybrid Approach):**
1. **New uploads:** Immediately use new structure ✅
2. **Old documents:** Migrate on-access (lazy migration)
3. **Background job:** Gradually migrate all old documents over time

**Migration Script:**
```swift
func migrateOldDocuments() async {
    let oldDocs = try await firestoreService.getDocumentsWithOldStructure()

    for doc in oldDocs {
        // 1. Create new folder: {documentId}/
        // 2. Copy original.pdf to new location
        // 3. Copy cover.pdf (if exists) to new location
        // 4. Copy complete.pdf (if exists) to new location
        // 5. Update Firestore URLs
        // 6. Delete old files
        // 7. Mark as migrated

        print("Migrated: \(doc.name)")
    }
}
```

**Testing Checklist:**
- ✅ Upload new document → files in correct location
- ✅ Move document category → all files move together
- ✅ Delete document → all files deleted
- ✅ Update profile → PDFs queued for regeneration
- ✅ Recategorize document → PDF regenerated with new category
- ✅ Pre-submission check → all stale PDFs regenerated (blocking)
- ✅ Queue processing → handles failures gracefully
- ✅ Priority ordering → high priority jobs processed first
- ✅ Stale detection → correctly identifies outdated PDFs
- ✅ Version tracking → increments on every profile change

**Success Criteria:**
- All old documents migrated to new structure
- No data loss during migration
- All tests passing

---

## Benefits Summary

### Immediate Benefits
✅ **Files stay together** - All related PDFs in one folder
✅ **Easy category changes** - Move entire folder atomically
✅ **Fluent updates** - In-place cover sheet regeneration
✅ **No orphaned files** - Delete one folder, delete everything
✅ **Clear referential integrity** - Folder structure shows relationships

### Long-Term Benefits
✅ **Automatic updates** - Profile changes auto-regenerate PDFs
✅ **Version tracking** - Know which profile version generated each PDF
✅ **Event-driven** - Reactive architecture, automatic propagation
✅ **Structured data** - Firestore as source of truth, PDFs as artifacts
✅ **Background processing** - Non-blocking queue system
✅ **Failure resilience** - Queue handles errors gracefully
✅ **User control** - Manual triggers and settings
✅ **Better UX** - Always up-to-date PDFs, clear status indicators

---

## Code Changes Summary

### Files to Create
- `PDFRegenerationService.swift` - New service for background regeneration

### Files to Modify
1. **StorageService.swift**
   - Update `generateStoragePath()` to include `{documentId}/` folder
   - Add `moveDocumentFolder()` for recategorization
   - Add `updateFileInPlace()` for in-place updates

2. **CoverSheetService.swift**
   - Change paths to use document folder
   - Remove separate `covers/` and `processed/` paths
   - Support overwriting existing files

3. **DocumentManager.swift**
   - Add `moveDocument()` using folder move
   - Update `remapDocument()` to use new move function
   - Subscribe to profile change events
   - Trigger regeneration on events

4. **User.swift**
   - Add `profileVersion: Int`
   - Add `profileLastUpdatedAt: Date`
   - Update dictionary methods

5. **TaxDocument.swift**
   - Add `pdfGenerationStatus: PDFGenerationStatus?`
   - Add `pdfLastGeneratedAt: Date?`
   - Add `generatedWithProfileVersion: Int?`
   - Add `needsRegeneration: Bool`
   - Add `PDFGenerationStatus` enum

6. **AuthenticationService.swift**
   - Add `profileDidChange` publisher
   - Increment `profileVersion` on updates
   - Publish events after profile changes

7. **FirestoreService.swift**
   - Update user update logic to increment version
   - Add queries for stale documents

---

## Example Scenarios

### Scenario 1: User Updates Name
```
1. User changes name: "Hans Müller" → "Hans Peter Müller"
2. AuthenticationService increments profileVersion: 7 → 8
3. profileDidChange event published
4. DocumentManager receives event
5. PDFRegenerationService queues all 15 user documents (low priority)
6. Background queue processes documents one by one
7. Each document regenerated with new name "Hans Peter Müller"
8. generatedWithProfileVersion updated to 8
9. User sees progress in UI
10. All PDFs now show updated name
```

### Scenario 2: User Recategorizes Document
```
1. User moves document from "income/salary" to "income/freelance"
2. DocumentManager.remapDocument() called
3. Storage path changes:
   FROM: documents/user/2024/income/salary/doc-abc-123/
   TO:   documents/user/2024/income/freelance/doc-abc-123/
4. All 3 files move together (original.pdf, cover.pdf, complete.pdf)
5. PDFRegenerationService queued (normal priority)
6. New cover sheet generated showing "Freelance Income"
7. Uploaded to same folder, overwrites old cover.pdf
8. New complete.pdf generated and uploaded
9. Firestore URLs updated
10. User sees updated document immediately
```

### Scenario 3: Pre-Submission Check
```
1. User clicks "Submit Tax Return" button
2. System checks for stale PDFs:
   - Document A: generatedWithProfileVersion = 7, user.profileVersion = 8 → STALE
   - Document B: generatedWithProfileVersion = 8, user.profileVersion = 8 → OK
   - Document C: generatedWithProfileVersion = 6, user.profileVersion = 8 → STALE
3. Modal appears: "Updating 2 documents with latest information..."
4. PDFRegenerationService regenerates Document A and C (high priority, blocking)
5. Progress bar shows 50% → 100%
6. All PDFs now current (version 8)
7. Submission proceeds
8. Tax expert receives complete, up-to-date documents
```

---

## Technical Notes

### Firebase Storage Operations
```swift
// Move folder in Firebase Storage
func moveFolder(from: String, to: String) async throws {
    // 1. List all files in source folder
    let files = try await storage.reference(withPath: from).listAll().items

    // 2. Copy each file to destination
    for file in files {
        let fileName = file.name
        let sourcePath = "\(from)/\(fileName)"
        let destPath = "\(to)/\(fileName)"

        // Download
        let data = try await storage.reference(withPath: sourcePath).data(maxSize: 10 * 1024 * 1024)

        // Upload to new location
        try await storage.reference(withPath: destPath).putDataAsync(data)

        // Delete old
        try await storage.reference(withPath: sourcePath).delete()
    }
}
```

### Version Comparison
```swift
func isPDFStale(document: TaxDocument, user: User) -> Bool {
    guard let generatedVersion = document.generatedWithProfileVersion else {
        return true  // Never generated
    }
    return generatedVersion < user.profileVersion
}
```

### Combine Event Flow
```swift
// Publisher (AuthenticationService)
let profileDidChange = PassthroughSubject<User, Never>()

// Subscriber (DocumentManager)
authService.profileDidChange
    .debounce(for: .seconds(2), scheduler: DispatchQueue.main)  // Wait 2s for batched changes
    .sink { user in
        await regenerateStale(for: user)
    }
    .store(in: &cancellables)
```

---

## Risks & Mitigations

### Risk 1: Migration Downtime
**Risk:** Migrating all documents could take hours, blocking users.
**Mitigation:** Hybrid migration - new uploads use new structure immediately, old documents migrate lazily on access or in background.

### Risk 2: Storage Costs
**Risk:** Multiple PDFs per document increases storage.
**Mitigation:** Implement cleanup jobs to delete old versions after successful regeneration. Compression for PDFs.

### Risk 3: Regeneration Queue Backlog
**Risk:** Hundreds of documents could overwhelm regeneration queue.
**Mitigation:** Priority system, rate limiting (0.5s delay between docs), batch processing with progress indicators.

### Risk 4: Concurrent Updates
**Risk:** User updates profile while regeneration in progress.
**Mitigation:** Version tracking ensures regeneration uses correct version. Queue deduplication prevents duplicate jobs.

### Risk 5: Failed Regenerations
**Risk:** Network issues or bugs cause regeneration failures.
**Mitigation:** Retry logic (3 attempts), failure status tracking, manual retry button, error logging for debugging.

---

## Future Enhancements

### Phase 7+ (Optional)
- **Smart regeneration:** Only regenerate if profile fields used in cover sheet changed
- **Batch export:** Download all documents + cover sheets as ZIP
- **Version history:** Keep old cover sheet versions for audit trail
- **Real-time updates:** Use Firestore snapshots to show live regeneration progress
- **Analytics:** Track regeneration times, failure rates, storage usage
- **Offline support:** Queue regeneration requests while offline, sync when online
- **Multi-language PDFs:** Generate cover sheets in user's preferred language
- **Expert collaboration:** Experts can trigger regeneration for customer documents

---

## Conclusion

This comprehensive redesign solves the fundamental problems with file management and data consistency in the TaxedGmbH app. By moving to **document-centric storage**, **structured metadata as source of truth**, and **event-driven PDF regeneration**, we achieve:

1. **Clean Storage** - All files stay together, easy to move and manage
2. **Data Consistency** - PDFs always reflect current user information
3. **Fluent Updates** - Cover sheets regenerate automatically when needed
4. **User-Centric** - Everything driven by structured user data
5. **Scalable Architecture** - Event-driven, queue-based, non-blocking

The 6-week phased implementation ensures minimal risk and allows for testing at each stage. The hybrid migration strategy means users can benefit from the new structure immediately without waiting for a complete migration.

**Status:** Documentation complete, ready for implementation approval.
