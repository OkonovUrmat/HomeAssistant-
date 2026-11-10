# Home Assistant

A native iOS app that works as the private memory of your house: photos, manuals,
diagrams, notes and procedures for every system — heating, water, pool, electrical and
anything else — with an AI assistant that answers **only from what you've documented**.

> **Status:** Phase 1 (Foundation) — architecture, design system, navigation, Dashboard.
> See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design and roadmap.

## Requirements

- Xcode 15.4 or newer (Xcode 16 recommended)
- iOS 17.0+ (iPhone and iPad)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Getting started

```bash
xcodegen            # generates HomeAssistant.xcodeproj from project.yml
open HomeAssistant.xcodeproj
```

Select the **HomeAssistant** scheme and run. In Debug, the scheme passes `-sampleData`
so the app launches with demo content; untick it in *Edit Scheme › Run › Arguments* to
start with an empty house.

**Signing:** pick your team under *Signing & Capabilities* the first time (or set
`DEVELOPMENT_TEAM` in `project.yml`).

### Tests

Module tests live in the local package. In Xcode choose the
**HomeAssistantKit-Package** scheme and press ⌘U, or from the terminal:

```bash
xcodebuild test -scheme HomeAssistantKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -workspace HomeAssistant.xcodeproj/project.xcworkspace
```

## Project layout

```
App/                        Composition root: DI container, router, tab bar
Packages/HomeAssistantKit/  All modules as SPM targets
  Core                      Domain models + repository/service protocols (Foundation only)
  DesignSystem              Tokens and reusable SwiftUI components
  Networking                HTTP client + Server-Sent Events parser
  Persistence               Repositories (in-memory now, SwiftData in Phase 2) + house template
  MediaManagement           File storage and thumbnails
  DocumentProcessing        PDFKit text extraction, Vision OCR
  Dashboard                 Home screen
  KnowledgeBase             House tree, components, item details, upload center
  Instructions              Procedures library and detail
  AIChat                    Assistant (streaming chat arrives in Phase 4)
docs/ARCHITECTURE.md        Architecture, trade-offs, models, navigation, roadmap
```

## Safety principles

This app documents real infrastructure — valves, breakers, pressurised systems.

- Every item and procedure carries a **provenance**: verified, your note, manufacturer,
  or unverified AI suggestion. They are always visibly distinct.
- Systems carry a **hazard level**; electrical, gas and pressure systems show a
  professional-help banner and pass that context to the assistant.
- The assistant never invents valve positions, breaker mappings, pressures or
  temperatures. When the knowledge base doesn't contain the answer, it says so.
