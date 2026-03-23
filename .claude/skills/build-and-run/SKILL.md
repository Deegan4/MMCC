---
name: build-and-run
description: Regenerate Xcode project with XcodeGen and build MMCC for iOS 26 simulator
---

# Build and Run MMCC

Regenerate the Xcode project from `project.yml` and build for an iOS 26 simulator.

## Steps

1. Run XcodeGen to regenerate the project:
```bash
cd "/Volumes/SAMSUNG 1TB/MMCC" && xcodegen generate
```

2. Build the project:
```bash
xcodebuild build \
  -project "/Volumes/SAMSUNG 1TB/MMCC/MMCC.xcodeproj" \
  -scheme MMCC \
  -destination "generic/platform=iOS Simulator" \
  -quiet \
  2>&1
```

3. If the build fails, read the errors and fix them. Common issues:
   - Missing imports (SwiftData, SwiftUI)
   - Swift 6 strict concurrency violations
   - SwiftData model relationship issues

4. Report build result: success or the specific errors that need fixing.
