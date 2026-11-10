# Home Assistant — Architecture Proposal

A native iOS app that acts as the private, searchable memory of a house, with an AI
assistant that answers questions **only from the owner's own material**.

This document covers the five things the spec asks for before any code:
overall architecture, module structure, core domain models, navigation, and the roadmap.
Each major decision lists the trade-off and what was chosen.

---

## 1. Overall architecture

```
┌──────────────────────────── iOS app ─────────────────────────────┐
│                                                                  │
│  Presentation   SwiftUI Views  ──►  @Observable ViewModels (MVVM)│
│                                         │                        │
│  Domain         Core: entities, repository & service protocols   │
│                                         ▲                        │
│  Data           Persistence (SwiftData)   Networking (URLSession,│
│                 MediaManagement (files)   SSE)  DocumentProcessing│
│                                                  (PDFKit, Vision) │
└──────────────────────────────────────────┬───────────────────────┘
                                           │ HTTPS + SSE (no API keys on device)
┌──────────────────────────── Backend ─────▼───────────────────────┐
│ Auth · File storage · OCR/extraction · Chunking · Embeddings ·   │
│ pgvector search · LLM chat (RAG) · Conversation history · Sync   │
└──────────────────────────────────────────────────────────────────┘
```

**Dependency rule:** everything points inward to `Core`. `Core` imports only
Foundation — no SwiftUI, no SwiftData, no networking. Views never touch a database or
an AI API; they talk to ViewModels, ViewModels talk to protocols from `Core`, and the
`App` target (composition root) decides which concrete implementation backs each protocol.

### Key decisions and trade-offs

| Decision | Options considered | Choice & reason |
|---|---|---|
| Modularisation | Folders in one target · one local SPM package with many targets · many packages · Tuist | **One local SPM package, one target per module.** Real compile-time boundaries (a module can't import what it doesn't declare), fast incremental builds, no extra tooling. Many packages adds versioning overhead with no benefit for a single app. |
| Xcode project | Hand-made `.xcodeproj` · XcodeGen · Tuist | **XcodeGen (`project.yml`).** The app target is a thin shell, so a 40-line YAML replaces a merge-conflict-prone `.pbxproj`. `.xcodeproj` is generated and git-ignored. |
| Domain models | SwiftData `@Model` classes used everywhere · plain structs + mapping | **Plain `Sendable` structs in Core; `@Model` types live only in Persistence.** Costs some mapping code, but keeps the domain testable, thread-safe across actors, and independent of SwiftData (which still has rough edges on iOS 17) — swapping storage or adding sync won't touch features. |
| Local persistence | SwiftData · Core Data · GRDB/SQLite | **SwiftData behind repository protocols.** Native, iOS 17-compatible, good enough for a single-user knowledge base. If it bites, the protocol boundary lets us move to GRDB without UI changes. Phase 1 ships an in-memory repository; Phase 2 adds SwiftData. |
| Media storage | Blobs in the database · files on disk | **Files in Application Support via `FileManager`, DB stores only the relative path + metadata.** Keeps the DB small and fast; thumbnails generated once and cached. |
| State management | `ObservableObject` · `@Observable` · TCA | **`@Observable` (iOS 17) MVVM.** Native, minimal boilerplate. TCA is powerful but heavy for this size of team/app. |
| DI | Third-party container · protocol injection | **Protocol-based constructor injection; one `AppContainer` as composition root.** No runtime magic, compile-time safe, trivial to substitute mocks in tests and previews. |
| Where RAG runs | On device · backend | **Backend.** Embedding models, pgvector, and LLM keys don't belong on the phone. The device keeps an offline copy of instructions (Phase 5) so the critical "how do I shut off the water" flows work with no connection. |
| Backend stack | Supabase (Postgres + pgvector + Storage + Auth + Edge Functions) · custom server (Vapor / FastAPI) + Postgres | **Decided at Phase 4.** Leaning Supabase for v1: auth, storage and pgvector out of the box. The iOS side only sees `AssistantService` / `SyncService` protocols, so the choice is reversible. |
| Streaming | WebSockets · SSE | **SSE over `URLSession.bytes`.** One-directional token stream is exactly what chat needs; no extra library. |

---

## 2. Module structure

```
HomeAssistant/
├── project.yml                     XcodeGen spec for the app target
├── App/                            Composition root (thin)
│   ├── HomeAssistantApp.swift      @main
│   ├── AppContainer.swift          builds concrete dependencies
│   ├── AppRouter.swift             tab selection + per-tab navigation paths
│   └── RootView.swift              TabView + destination resolution
└── Packages/HomeAssistantKit/
    └── Sources/
        ├── Core/                   Entities, IDs, repository/service protocols, AppDestination
        ├── DesignSystem/           Tokens (spacing, radius, typography), components
        ├── Networking/             HTTPClient, Endpoint, SSE parser, API errors
        ├── Persistence/            InMemory (Phase 1) + SwiftData (Phase 2) repositories, seeding
        ├── MediaManagement/        File storage, thumbnails, camera/photo import
        ├── DocumentProcessing/     PDF text extraction, Vision OCR, VisionKit scanning
        ├── Dashboard/              Home screen feature
        ├── KnowledgeBase/          Category tree, items, details, editing
        ├── Instructions/           Procedures, steps, checklists, annotations
        └── AIChat/                 Conversations, streaming, citations
```

`Dashboard` is added on top of the spec's list: it composes data from several features,
and keeping it in `App` would make the composition root grow with every screen.

**Allowed dependencies**

| Module | Depends on |
|---|---|
| Core | — |
| DesignSystem | Core (for icons/hazard levels only) |
| Networking, Persistence, MediaManagement, DocumentProcessing | Core |
| Dashboard, KnowledgeBase, Instructions, AIChat | Core, DesignSystem |
| App | everything |

Feature modules never import each other. Cross-feature navigation goes through
`AppDestination` (in Core), which the App resolves to a concrete screen.

---

## 3. Core domain models

```
House
 └── HouseCategory (tree via parentID, any depth: "Heating" → "Boiler")
      └── KnowledgeItem ── Attachment[] ── PhotoAnnotation[]
            │                (photo / video / pdf / diagram / document)
            └── Instruction ── InstructionStep[] (each may have an attachment)

Conversation ── ChatMessage[] ── SourceCitation[] → KnowledgeItem / Attachment / Instruction
```

| Entity | Purpose | Notable fields |
|---|---|---|
| `House` | The property itself | name, address (optional) |
| `HouseCategory` | A system or component node | `parentID`, `kind` (system / component), SF Symbol, `hazard`, `sortOrder` |
| `KnowledgeItem` | Any piece of knowledge | title, description, notes, tags, `provenance`, `isFavorite`, attachments, related item IDs, dates |
| `Attachment` | A file on disk | `kind`, relative file path, `extractedText` (OCR/PDF), annotations |
| `PhotoAnnotation` | Marker on a photo | `number`, label, detail, normalised position (0…1), optional arrow end-point, style |
| `Instruction` | Operational procedure | equipment, preconditions, ordered steps, warnings, expected result, troubleshooting, `provenance`, usage count |
| `InstructionStep` | One step | text, optional attachment, optional warning |
| `Conversation` / `ChatMessage` | Chat history | role, markdown content, status (streaming / complete / failed), citations |
| `SourceCitation` | Grounding reference | target ID + type, snippet, `provenance` |

### Safety is part of the model, not just the prompt

- **`Provenance`** — every knowledge item, instruction and citation is one of:
  `verifiedInstruction`, `userNote`, `manufacturerDocument`, `aiSuggestion`.
  The UI badges each one, and AI-generated content is *always* stored as
  `aiSuggestion` (“unverified”) until the owner explicitly verifies it.
- **`HazardLevel`** — categories carry `normal` / `caution` / `dangerous`
  (electrical, gas, pressurised systems). The UI shows a professional-help banner on
  dangerous systems and the backend prompt receives the hazard level with each chunk.

---

## 4. Navigation

```
TabView
├── Home         (Dashboard)      NavigationStack(path:)
├── House        (KnowledgeBase)  NavigationStack(path:)
├── Procedures   (Instructions)   NavigationStack(path:)
└── Assistant    (AIChat)         NavigationStack(path:)

Global: "+" Upload Center presented as a sheet from any tab.
```

- One `AppRouter` (`@Observable`) owns the selected tab and one `[AppDestination]` path
  per tab. Programmatic deep links ("open this citation") are a single call:
  `router.open(.knowledgeItem(id))`.
- Each stack registers `.navigationDestination(for: AppDestination.self)` and the App
  maps destinations to feature screens — features stay decoupled.
- iPad uses the same tab structure in Phase 1; a `NavigationSplitView` layout for the
  House tab (tree on the left, item on the right) arrives with Phase 2.
- On iOS 17 we use the classic `TabView` + `tabItem` API (the new `Tab` API is iOS 18+).

---

## 5. Roadmap

| Phase | Scope | Exit criteria |
|---|---|---|
| **1 — Foundation** ✅ | XcodeGen project, SPM modules, Core models, design system, DI container, router, tab navigation, Dashboard, default house structure seeding | App launches; Dashboard shows systems, quick access, recent items, frequent procedures; tapping a system navigates across tabs |
| 2 — Knowledge Base | Category CRUD (create/rename/move/delete), knowledge item CRUD, photo/PDF/video import, file storage + thumbnails, SwiftData persistence, search, filters, grid/list, favourites, iPad split view | Data survives relaunch; 500 items with photos scroll smoothly |
| 3 — Instructions | Instruction editor, per-step photos, warnings, checklist run mode with completion state, photo annotation editor (numbered markers, labels, arrows, tap-to-reveal) | A full "fill the tanks from city water" procedure can be authored and run |
| 4 — AI Integration | Backend (auth, upload, extraction, chunking, embeddings, pgvector, chat endpoint), SSE streaming chat, markdown, citations with image previews, stop/retry, suggested questions, safety system prompt | Answers cite the right items; refuses when the knowledge base lacks the info |
| 5 — Advanced | On-device + server OCR, multimodal photo understanding, cross-session conversation memory, offline instructions, sync & conflict resolution | Procedures usable in airplane mode; edits sync between devices |
| 6 — Quality | Unit tests per module, UI tests for key flows, performance passes, error handling polish, VoiceOver / Dynamic Type audit | CI green, accessibility audit clean |

Tests are written alongside each phase where logic exists (SSE parser, repositories,
view models); Phase 6 is about coverage and polish, not the first tests.
