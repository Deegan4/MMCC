# Swift Gotchas & Patterns (MMCC)

## #Predicate Capture Rule
`#Predicate` macro CANNOT capture properties from non-local objects. Always extract to a local `let`:
```swift
// WRONG: let descriptor = FetchDescriptor<Estimate>(predicate: #Predicate { $0.id == item.entityID })
// RIGHT:
let entityID = item.entityID
let descriptor = FetchDescriptor<Estimate>(predicate: #Predicate { $0.id == entityID })
```

## Codable `Type` Property
Swift won't allow a stored property named `Type` (conflicts with `.Type` metatype syntax):
```swift
let ItemType: String?
enum CodingKeys: String, CodingKey {
    case ItemType = "Type"
}
```

## Optional @Environment for Services
QB services inject via environment but may be nil before `.task {}` initialization:
```swift
@Environment(SyncCoordinator.self) private var syncCoordinator: SyncCoordinator?
```
SettingsView uses non-optional (crashes if missing); detail views use optional (graceful nil).

## XcodeGen `info:` Block
REQUIRES `path:` key — XcodeGen generates the Info.plist at that location:
```yaml
info:
  path: MMCC/Info.plist
  properties: ...
```

## Duplicate Source Files
XcodeGen `sources: [{path: .}]` picks up EVERYTHING not excluded. Watch for:
- Stale `.xcodeproj` directories (add to excludes)
- Duplicate type definitions across files (WidgetDataService.swift vs MMCCApp.swift)

## Code Signing
- `CODE_SIGNING_REQUIRED: NO` works for simulator but breaks device installs
- `DEVELOPMENT_TEAM` must be set for device builds (A6H72TGWNL)
- Revoked certs show `CSSMERR_TP_CERT_REVOKED` — Xcode uses the valid one automatically
