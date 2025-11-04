# 📂 TaxedGmbH iOS - Project Structure

> Following Apple's recommended best practices for iOS/SwiftUI application architecture

## 🏗️ Directory Structure

```
TaxedGmbH_IOS/
│
├── TaxedGmbH_IOS/                          # Main source folder
│   │
│   ├── App/                                # ✅ Application Entry Point
│   │   └── TaxedGmbH_IOS.swift            # Main app file, Firebase initialization
│   │
│   ├── Models/                             # ✅ Data Models
│   │   ├── User.swift                     # User model with Swiss tax fields
│   │   └── TaxDocument.swift              # Tax document with AI classification
│   │
│   ├── Views/                              # ✅ SwiftUI Views (MVVM Pattern)
│   │   ├── Main/
│   │   │   ├── ContentView.swift          # Root view (auth state handler)
│   │   │   └── DashboardView.swift        # Main dashboard
│   │   │
│   │   ├── Documents/
│   │   │   ├── DocumentUploadView.swift   # Upload interface
│   │   │   ├── DocumentListView.swift     # Document list with filters
│   │   │   ├── DocumentDetailView.swift   # Document detail + AI results
│   │   │   ├── ImagePicker.swift          # Photo library picker
│   │   │   └── CameraPicker.swift         # Camera capture
│   │   │
│   │   ├── Authentication/
│   │   │   └── AuthenticationView.swift   # Login/signup
│   │   │
│   │   ├── Communication/                 # (Future: Chat views)
│   │   ├── Settings/                      # (Future: Settings views)
│   │   └── TaxReturns/                    # (Future: Tax return views)
│   │
│   ├── Services/                           # ✅ Business Logic Layer
│   │   ├── AuthenticationService.swift    # Firebase Auth
│   │   ├── FirestoreService.swift         # Database operations
│   │   └── StorageService.swift           # File uploads
│   │
│   ├── Constants/                          # ✅ App-wide Constants (Apple Best Practice)
│   │   └── AppConstants.swift             # Colors, strings, config values
│   │
│   ├── Helpers/                            # ✅ Utility Functions
│   │   └── (Future: Date formatters, validators, etc.)
│   │
│   ├── Extensions/                         # ✅ Swift Extensions
│   │   └── (Future: String+Validation, Date+Formatting, etc.)
│   │
│   ├── Utilities/                          # ✅ Reusable Utilities
│   │   └── (Future: Network monitor, permissions handler, etc.)
│   │
│   └── Resources/                          # ✅ Non-code Assets
│       ├── Assets/                        # Images, colors, icons
│       ├── GoogleService-Info.plist       # Firebase configuration
│       ├── Fonts/                         # Custom fonts
│       └── LocalizedStrings/              # Translations (DE/FR/IT)
│
├── TaxedGmbH_IOSTests/                    # Unit tests
├── TaxedGmbH_IOSUITests/                  # UI tests
│
├── functions/                              # ☁️ Firebase Cloud Functions
│   ├── src/
│   │   ├── index.ts                       # Main function entry
│   │   └── documentProcessor.ts           # OpenAI integration
│   ├── package.json
│   └── tsconfig.json
│
├── TaxedGmbH_IOS.xcodeproj                # Xcode project
└── Documentation/
    ├── DEPLOYMENT_GUIDE.md
    ├── IMPLEMENTATION_SUMMARY.md
    ├── MANUAL_STEPS.md
    └── PROJECT_STRUCTURE.md (this file)
```

---

## 📐 Architecture Pattern: MVVM

Following Apple's recommended approach for SwiftUI:

### **Model** (`Models/`)
- Data structures and business entities
- `User`, `TaxDocument`
- Codable for Firebase serialization

### **View** (`Views/`)
- SwiftUI views (UI layer)
- No business logic
- Observes ViewModels via `@StateObject`, `@ObservedObject`

### **ViewModel** (`Services/`)
- Business logic and state management
- `@MainActor` classes marked as `ObservableObject`
- `@Published` properties for reactive updates
- Services act as ViewModels in this architecture

---

## 🎨 Apple Best Practices Applied

### 1. **Constants Management** ✅
```swift
// All colors in one place
extension Color {
    static let taxedPrimary = Color.blue
    static let categoryIncome = Color.green
}

// App configuration centralized
struct AppConstants {
    struct Firebase { ... }
    struct Tax { ... }
}
```

### 2. **Separation of Concerns** ✅
- **Views:** UI only, no business logic
- **Services:** Data operations, API calls
- **Models:** Pure data structures

### 3. **Resource Organization** ✅
- All assets in `Resources/Assets`
- Firebase config in `Resources/`
- Fonts and localizations separated

### 4. **Folder = File System** ✅
- Xcode groups match actual folders
- Easy navigation in GitHub/Finder
- No virtual groups

---

## 📦 File Naming Conventions

Following Swift API Design Guidelines:

### **Swift Files**
- **Views:** `[Feature]View.swift` (e.g., `DashboardView.swift`)
- **Models:** `[Entity].swift` (e.g., `User.swift`, `TaxDocument.swift`)
- **Services:** `[Purpose]Service.swift` (e.g., `AuthenticationService.swift`)
- **Extensions:** `[Type]+[Feature].swift` (e.g., `String+Validation.swift`)

### **Folders**
- Plural for collections: `Models/`, `Views/`, `Services/`
- Singular for single purpose: `App/`, `Resources/`

---

## 🔄 Data Flow

```
User Interaction
    ↓
View (SwiftUI)
    ↓
Service/ViewModel (@ObservableObject)
    ↓
Firebase (Firestore/Storage/Auth)
    ↓
Model (Updated)
    ↓
View (Auto-updates via @Published)
```

**Example:**
1. User taps "Upload Document" → `DocumentUploadView`
2. View calls → `StorageService.uploadDocument()`
3. Service uploads to Firebase Storage
4. Service creates record via `FirestoreService`
5. Cloud Function processes (AI classification)
6. Firestore listener updates `@Published var documents`
7. View automatically refreshes

---

## 🧩 Module Dependencies

```
Views
  ↓
Services ← Constants
  ↓
Models
  ↓
Firebase SDK
```

- **Views** depend on Services (not Models directly)
- **Services** depend on Models and Constants
- **Models** are independent (pure data)
- **Constants** are app-wide (no dependencies)

---

## 📱 SwiftUI Specific

### **State Management**
- `@StateObject` for creating ViewModels
- `@ObservedObject` for passing ViewModels
- `@EnvironmentObject` for shared state (e.g., `AuthenticationService`)
- `@State` for local view state only

### **View Composition**
```
ContentView (Root)
  ├── DashboardView
  │     ├── CategoryCard
  │     ├── QuickActionButton
  │     └── RecentDocumentRow
  ├── DocumentUploadView
  └── AuthenticationView
```

---

## 🌍 Localization Structure

```
Resources/
  └── LocalizedStrings/
      ├── de.lproj/          # German (primary)
      │   └── Localizable.strings
      ├── fr.lproj/          # French
      │   └── Localizable.strings
      └── it.lproj/          # Italian
          └── Localizable.strings
```

**Swiss Languages Supported:**
- 🇩🇪 German (Deutsch) - Primary
- 🇫🇷 French (Français)
- 🇮🇹 Italian (Italiano)
- 🇬🇧 English (fallback)

---

## 🧪 Testing Structure

```
TaxedGmbH_IOSTests/
  ├── Models/
  │   ├── UserTests.swift
  │   └── TaxDocumentTests.swift
  ├── Services/
  │   ├── AuthenticationServiceTests.swift
  │   └── FirestoreServiceTests.swift
  └── ViewModels/
      └── (Future tests)

TaxedGmbH_IOSUITests/
  ├── DocumentUploadFlowTests.swift
  ├── AuthenticationFlowTests.swift
  └── DashboardTests.swift
```

---

## 🚀 Adding New Features

### Example: Adding Voice Recording Feature

1. **Create Model** (if needed)
   ```
   Models/VoiceMemo.swift
   ```

2. **Create Service**
   ```
   Services/VoiceRecordingService.swift
   Services/WhisperService.swift
   ```

3. **Create Views**
   ```
   Views/Voice/VoiceRecordingView.swift
   Views/Voice/VoiceMemoListView.swift
   ```

4. **Update Constants**
   ```swift
   // In Constants/AppConstants.swift
   struct Voice {
       static let maxRecordingDuration: TimeInterval = 300 // 5 min
   }
   ```

5. **Add to Navigation**
   ```swift
   // In Views/Main/DashboardView.swift
   NavigationLink("Voice Memos") {
       VoiceMemoListView()
   }
   ```

---

## 📚 Related Documentation

- **DEPLOYMENT_GUIDE.md** - How to build and deploy
- **IMPLEMENTATION_SUMMARY.md** - Feature overview
- **MANUAL_STEPS.md** - Xcode configuration
- **FIREBASE_SETUP.md** - Backend configuration
- **functions/README.md** - Cloud Functions docs

---

## ✅ Structure Validation Checklist

- [x] No duplicate nested folders
- [x] Xcode groups match file system
- [x] Constants separated from code
- [x] Views separate from business logic
- [x] Models are pure data structures
- [x] Resources properly organized
- [x] Following MVVM pattern
- [x] Localization structure ready
- [x] Test folders properly structured

---

## 🔧 Maintenance

### Monthly
- Review unused files
- Check for circular dependencies
- Update documentation

### Per Feature
- Add tests in parallel with implementation
- Update constants for new values
- Document complex business logic

---

**Last Updated:** October 23, 2025
**Architecture:** MVVM with SwiftUI
**Follows:** Apple iOS Best Practices 2024
