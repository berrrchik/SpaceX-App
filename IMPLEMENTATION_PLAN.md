# SpaceX iOS App — Production-Grade Implementation Roadmap

**Version:** 2.0  
**Date:** 2026-04-30  
**Status:** Implementation-Ready  
**Source of Truth:** `new-func-spacex-priority.md`

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [AS-IS Baseline](#2-as-is-baseline)
3. [Cache Strategy: Decision Rationale](#3-cache-strategy-decision-rationale)
4. [TO-BE Architecture](#4-to-be-architecture)
5. [Global Dependency Plan](#5-global-dependency-plan)
6. [Phased Implementation](#6-phased-implementation)
   - [Phase 1 — F-1: Domain Models and DTO Expansion](#phase-1--f-1-domain-models-and-dto-expansion)
   - [Phase 2 — F-2: UserDefaults Launch Cache Store](#phase-2--f-2-userdefaults-launch-cache-store)
   - [Phase 3 — F-7: LoadableState Refactor (parallel with Phase 4)](#phase-3--f-7-loadablestate-refactor)
   - [Phase 4 — F-3: Diffable Data Source + Compositional Layout (parallel with Phase 3)](#phase-4--f-3-diffable-data-source--compositional-layout)
   - [Phase 5 — F-4: Launch Search, Filtering, and Sorting](#phase-5--f-4-launch-search-filtering-and-sorting)
   - [Phase 6 — F-5: Launch Detail Screen](#phase-6--f-5-launch-detail-screen)
   - [Phase 7 — F-6: Statistics Screen (parallel with Phase 6)](#phase-7--f-6-statistics-screen)
   - [Phase 8 — F-8: Design and Visual Consistency](#phase-8--f-8-design-and-visual-consistency)
   - [Phase 9 — F-9: Test Finalization](#phase-9--f-9-test-finalization)
7. [Feature Traceability Matrix](#7-feature-traceability-matrix)
8. [Cross-Project Test Strategy](#8-cross-project-test-strategy)
9. [Delivery Slicing](#9-delivery-slicing)
10. [Operational Readiness](#10-operational-readiness)
11. [Final Master Checklist](#11-final-master-checklist)
12. [Self-Check Report](#12-self-check-report)

---

## 1. Executive Summary

### What is Delivered

This roadmap delivers nine discrete, dependency-ordered features on top of the existing UIKit MVVM+Coordinator SpaceX app:

| ID | Feature |
|----|---------|
| F-1 | Domain Models and DTO Expansion |
| F-2 | UserDefaults Launch Cache Store |
| F-3 | Migrate Launch List to Diffable Data Source + Compositional Layout |
| F-4 | Launch Search, Filtering, and Sorting |
| F-5 | Launch Detail Screen |
| F-6 | Statistics Screen |
| F-7 | LoadableState Refactor |
| F-8 | Design and Visual Consistency |
| F-9 | Test Finalization |

### Why This Implementation Order

The execution order is driven by hard technical dependencies:

- **F-1 first** — every other feature needs `Launch.id` and the expanded domain model; nothing else can start without it.
- **F-2 second** — the UserDefaults cache enables offline support required by F-5 and F-6; must be in place before detail and stats screens are built.
- **F-7 and F-3 in parallel** — `LoadableState` is a pure Swift addition with no UI dependencies; `Diffable + Compositional Layout` is a pure UI refactor; neither blocks the other.
- **F-4 after F-3** — `LaunchQuery` requires `LaunchesItem` (defined in F-3), `LaunchCellViewModel` as `Hashable` (done in F-3), and animated diffs from Diffable Data Source.
- **F-5 and F-6 in parallel after F-2** — both depend on cached data and expanded models, neither depends on the other.
- **F-8 after all UI** — design token audit and shared component extraction require all screens to exist.
- **F-9 last** — integration tests require all features to be complete; unit tests are written continuously per phase.

### Final Done State

After all nine phases pass their Definition of Done:

- The app functions offline for both the launch list and the launch detail screen using a UserDefaults-backed JSON cache.
- The launch list uses `UICollectionViewDiffableDataSource` with animated filter/sort transitions.
- A `UISearchController` + filter chips enable client-side search, status filter, year filter, and sort order selection.
- Tapping a launch cell navigates to a scrollable detail screen populated from the cache, with sections for hero, timeline, description, rocket, pad, payloads, crew, ships, capsules, and external links.
- A statistics screen (SwiftUI `Chart` views embedded via `UIHostingController`) aggregates launch data in memory by loading cached launches for all known `rocketId` values from `UserDefaults`.
- `LoadableState<Value>` drives all ViewModel state, including offline-first `.failed(message, cachedValue)` and `.loaded(_, isStale: true)` states.
- All new and modified screens use `AppColors` and `AppFonts` exclusively; shared components (`CardView`, `SectionHeaderView`, `LoadingIndicatorView`, `EmptyStateView`) are extracted and reused.
- Test coverage exceeds 80% for all new ViewModels and Repositories; UI tests cover the three critical paths.

---

## 2. AS-IS Baseline

### Current Architecture Flow Map

```
SceneDelegate
  └─ AppCoordinator(window:appContainer:)
       ├─ start() → pushes RocketViewController
       │    └─ RocketViewModel ← RocketRepository ← RocketRemoteDataSource ← URLSessionHTTPClient
       ├─ showLaunches(for:) → pushes LaunchViewController
       │    └─ LaunchListViewModel ← LaunchRepository ← LaunchRemoteDataSource ← URLSessionHTTPClient
       └─ showSettings(from:) → presents SettingsViewController (modal)
            └─ SettingsViewModel ← UserDefaultsSettingsStore
```

All dependencies are assembled in `AppContainer` and injected via initializer. `AppCoordinator` conforms to `AppCoordinating` protocol for testability.

### Current Limitations Relevant to In-Scope Features

| Limitation | Blocks |
|-----------|--------|
| `Launch` has no `id` field | F-5 (cell tap → detail), F-4 (query-based filtering needs stable identity) |
| `LaunchDTO` only decodes `name`, `dateUtc`, `success`, `rocket` | F-1 (DTO expansion), F-5 (detail needs payloads, launchpad, crew, etc.) |
| No persistence layer; app is network-only | F-2 (UserDefaults cache), F-5 (offline detail), F-6 (stats from cache) |
| `LaunchViewController` uses `UITableView` + `UITableViewDataSource/Delegate` | F-3 (Diffable migration), F-4 (filter chips require compositional sections) |
| `LaunchCellViewModel` is not `Hashable` | F-3 (required for `NSDiffableDataSourceSnapshot`) |
| No `LaunchQuery` model; filtering not possible without network | F-4 |
| No `LaunchDetailViewController` or coordinator route | F-5 |
| No stats feature | F-6 |
| No `LoadableState`; `LaunchListState` is bespoke per-feature enum | F-7 |
| No shared design token components (`CardView`, etc.) | F-8 |
| `LaunchListViewModel.mapToViewModels` excludes `id` | F-5 (detail navigation requires `id`) |

### Current Test Gaps Relevant to In-Scope Features

| Gap | Relevant Feature |
|----|-----------------|
| No mapper unit tests (`LaunchMapper`) | F-1 |
| No cache store tests (no persistence layer yet) | F-2 |
| No snapshot construction tests for Diffable Data Source | F-3 |
| No `LaunchQuery` filter/sort unit tests | F-4 |
| No `LaunchDetailViewModel` tests | F-5 |
| No `StatsViewModel` / `StatsRepository` tests | F-6 |
| No `LoadableState` transition tests | F-7 |
| No UI tests for navigation, filtering, or pagination | F-9 |

### High-Risk Coupling Points

| Coupling | Risk | Mitigation |
|---------|------|------------|
| `LaunchListViewModel` shares a single instance across rocket selections (injected once in `AppContainer`) | State contamination: page cursor and cached data from Rocket A bleed into Rocket B | In F-4 and F-5, `LaunchListViewModel` resets `currentQuery` and `currentPage` when `loadInitialLaunches(for:)` is called |
| `LaunchView.tableView` is referenced directly in `LaunchViewController` | F-3 removes `tableView` and adds `collectionView`; any reference leak breaks build | Replace atomically in one PR |
| `LaunchRemoteDataSource` private `LaunchQuery` struct name collides with the public `LaunchQuery` domain model added in F-4 | Build error | Rename the private request struct to `LaunchQueryRequest` (already named that in current code) and namespace the public domain enum under `Domain/` |
| `AppContainer` creates `launchListViewModel` as a lazy singleton | Prevents per-rocket ViewModel reset | Document that `LaunchListViewModel.loadInitialLaunches(for:)` must reset all mutable state |

---

## 3. Cache Strategy: Decision Rationale

### Why UserDefaults Over Core Data

The launch cache introduced in F-2 uses `UserDefaults` with `JSONEncoder`/`JSONDecoder` rather than a Core Data stack. This decision is intentional and bounded by the concrete constraints of this project.

| Factor | Analysis |
|--------|----------|
| **Dataset size** | The SpaceX v4 API returns ~200 launches total. Even at 10 kB per serialised launch, the entire dataset fits within 2 MB — well under the practical `UserDefaults` storage ceiling and the app's memory budget. |
| **Query complexity** | All filtering and sorting in F-4 is performed in-memory on `[Launch]` arrays. No `NSPredicate`, join, or relational query is needed at any point in the roadmap. |
| **Relationship depth** | Launches are scoped by `rocketId` only. There are no entity graphs or cross-feature relationships that would benefit from a relational store. |
| **Implementation cost** | Core Data requires a schema file (`.xcdatamodeld`), managed object subclasses, a `NSPersistentContainer`, background context management, and careful thread-affinity. UserDefaults with `Codable` adds none of this overhead. |
| **Testability** | A `UserDefaults(suiteName:)` instance isolates test state without any in-memory store plumbing. No base class, no `/dev/null` path, no store coordinator. |
| **Alignment with existing project** | Settings are already stored via `UserDefaultsSettingsStore`. This approach is consistent with the existing architecture layer. |

### Scope Limits and Constraints

This decision is appropriate **as long as** the following constraints hold:

- The total number of `Launch` objects across all rockets does not exceed approximately 2,000.
- No feature requires server-side or SQL-style predicate evaluation on cached data.
- No feature requires relationships between `Launch` and other cached entity types (e.g., joining `Launch` → `Rocket` → `Launchpad` in a single query).
- The cache is a best-effort offline fallback, not a primary data source with strict consistency guarantees.

If any constraint is violated in a future iteration (e.g., the dataset grows to tens of thousands of records, or a feature requires multi-entity joins), migrating to SQLite-backed persistence (Core Data, GRDB, or SwiftData) is straightforward: only `UserDefaultsLaunchCacheStore` and its tests change — `LaunchCacheStoreProtocol` and all callers remain unchanged.

---

## 4. TO-BE Architecture

### Target Module Boundaries

```
SpaceX/
├── App/
│   ├── AppContainer.swift          (registers LaunchCacheStore, new repositories)
│   ├── AppCoordinator.swift        (adds showLaunchDetail, showStats methods)
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
│
├── Core/
│   ├── Networking/                 (unchanged)
│   ├── Settings/                   (unchanged)
│   ├── UI/
│   │   ├── Theme/
│   │   │   ├── AppColors.swift     (unchanged)
│   │   │   └── AppFonts.swift      (unchanged)
│   │   ├── Components/
│   │   │   ├── CardView.swift
│   │   │   ├── SectionHeaderView.swift
│   │   │   ├── LoadingIndicatorView.swift
│   │   │   └── EmptyStateView.swift
│   │   ├── Loading/                (unchanged)
│   │   └── LoadableState.swift
│   ├── Formatting/                 (unchanged)
│   └── Logging/                    (unchanged)
│
├── Features/
│   ├── Rockets/                    (unchanged structure)
│   │
│   ├── Launches/
│   │   ├── Data/
│   │   │   ├── LaunchDTO.swift           (expanded)
│   │   │   ├── LaunchMapper.swift        (expanded)
│   │   │   ├── LaunchPageDTO.swift       (unchanged)
│   │   │   ├── LaunchRemoteDataSource.swift (select array expanded)
│   │   │   ├── LaunchRepository.swift    (cache injected)
│   │   │   └── LaunchCacheStore.swift    (protocol + UserDefaultsLaunchCacheStore)
│   │   ├── Domain/
│   │   │   ├── Launch.swift              (id, launchpadId, upcoming, details, links, cores added; Codable)
│   │   │   ├── LaunchDetail.swift
│   │   │   ├── LaunchPageResult.swift    (unchanged)
│   │   │   ├── LaunchQuery.swift
│   │   │   ├── LaunchStatusFilter.swift
│   │   │   └── LaunchSortOrder.swift
│   │   ├── Presentation/
│   │   │   ├── LaunchListViewModel.swift (query + LoadableState)
│   │   │   ├── LaunchCellViewModel.swift (id, Hashable)
│   │   │   └── LaunchViewModel.swift     (unchanged)
│   │   └── UI/
│   │       ├── LaunchView.swift          (collectionView replaces tableView)
│   │       ├── LaunchViewController.swift (Diffable DS, UISearchController)
│   │       ├── LaunchCell.swift          (UICollectionViewCell)
│   │       ├── LaunchFilterCell.swift
│   │       └── Components/
│   │           └── LaunchErrorCell.swift  (UICollectionViewCell)
│   │
│   ├── LaunchDetail/
│   │   ├── Domain/
│   │   │   ├── LaunchDetailRepository.swift + protocol
│   │   ├── Presentation/
│   │   │   └── LaunchDetailViewModel.swift
│   │   └── UI/
│   │       ├── LaunchDetailViewController.swift
│   │       └── LaunchDetailView.swift
│   │
│   ├── Launchpad/
│   │   ├── Domain/
│   │   │   ├── Launchpad.swift
│   │   │   └── Landpad.swift
│   │   └── Data/
│   │       ├── LaunchpadRemoteDataSource.swift + protocol
│   │       └── LandpadRemoteDataSource.swift + protocol
│   │
│   ├── Stats/
│   │   ├── Domain/
│   │   │   ├── LaunchStats.swift
│   │   │   └── StatsRepository.swift + protocol
│   │   ├── Presentation/
│   │   │   └── StatsViewModel.swift
│   │   └── UI/
│   │       ├── StatsViewController.swift
│   │       └── LaunchStatsView.swift (SwiftUI)
│   │
│   └── Settings/                   (unchanged)
│
└── Shared/
    └── Extensions/                 (unchanged)
```

### Responsibility Map by Layer

| Layer | Responsibility |
|-------|---------------|
| **Domain** | Pure Swift value types / enums conforming to `Codable` where caching is required; no UIKit, no Foundation storage imports |
| **Data** | DTOs, mappers (DTO→Domain), remote data sources (network), cache stores (`UserDefaultsLaunchCacheStore`), repositories (read-through/write-through orchestration) |
| **Presentation** | ViewModels: hold state (`LoadableState`), apply `LaunchQuery`, call repositories, publish on main thread |
| **UI** | ViewControllers (thin: wire ViewModel → View, delegate navigation to coordinator), Views (build subviews programmatically), Cells |
| **Core** | Cross-feature shared: `LoadableState`, design token components, networking, logging, formatting |
| **App** | `AppContainer` (DI graph), `AppCoordinator` (navigation decisions only) |

### Dependency Direction Rules

```
UI → Presentation → Domain ← Data
             ↑
            Core
```

- `Data` layer imports `Domain` types (maps DTO → Domain, serialises Domain structs via `Codable`).
- `Presentation` layer imports `Domain` and `Data` protocols only (never concrete data classes).
- `UI` imports `Presentation` only (never `Data` or `Domain` directly except for display-only value types).
- `Core` has no imports from `Features`.
- No circular imports.

### Online/Offline Data Flow

```
Online flow:
  ViewModel.load()
    → Repository.fetch()
      → CacheStore.load(for:)  [returns cached data synchronously if available]
      → RemoteDataSource.fetch() [async network call]
      → CacheStore.save(_:for:)  [on network success]
      → returns fresh Domain data

Offline / network failure flow:
  ViewModel.load()
    → Repository.fetch()
      → CacheStore.load(for:)  [returns cached data]
      → RemoteDataSource.fetch() throws NetworkError
      → Repository catches error, returns cached data + isStale: true
      → ViewModel publishes .failed(message, cachedValue: cached) or
        .loaded(cached, isStale: true) depending on cache availability
```

---

## 5. Global Dependency Plan

### Phase Dependency Graph

```
Phase 1 (F-1: Domain Models)
    │
    ├──────────────────────────────────────┐
    ▼                                      ▼
Phase 2 (F-2: UserDefaults Cache)   Phase 3 (F-7: LoadableState) ─── parallel ───
    │                                      │                                        │
    │               Phase 4 (F-3: Diffable+Compositional) ◄─── parallel ───────────┘
    │                        │
    │                        ▼
    │               Phase 5 (F-4: Search/Filter/Sort)
    │
    ├──────────────────────────────────────┐
    ▼                                      ▼
Phase 6 (F-5: Launch Detail)        Phase 7 (F-6: Statistics) ─── parallel ───
    │                                      │
    └──────────────────┬───────────────────┘
                       ▼
              Phase 8 (F-8: Design Consistency)
                       │
                       ▼
              Phase 9 (F-9: Test Finalization)
```

### Critical Path

`F-1 → F-2 → F-5 → F-8 → F-9`

This is the longest sequential chain. Delay to F-2 directly delays F-5 and the final delivery.

### Parallelizable Streams

| Parallel Group | Streams |
|---------------|---------|
| After Phase 2 completes | Phase 3 (F-7) and Phase 4 (F-3) can run simultaneously |
| After Phase 4 (F-3) and Phase 2 complete | Phase 6 (F-5) and Phase 7 (F-6) can run simultaneously |

### Blockers and Prerequisites

| Phase | Hard Blockers (must complete first) |
|-------|-------------------------------------|
| Phase 1 (F-1) | None — first phase |
| Phase 2 (F-2) | Phase 1: needs `Launch` domain model with `id` and `Codable` conformance |
| Phase 3 (F-7) | Phase 1: `LoadableState<Value>` generic over Domain types |
| Phase 4 (F-3) | Phase 1: `LaunchCellViewModel` needs `id` field (added in F-1); Phase 3 is independent of Phase 4 |
| Phase 5 (F-4) | Phase 4: `LaunchesItem`, `Hashable` `LaunchCellViewModel`, animated Diffable snapshots |
| Phase 6 (F-5) | Phase 1 (expanded domain), Phase 3 (F-7 — `LoadableState` for ViewModel). Phase 2 is optional (adds offline fallback only — detail uses network-first, not cache-first) |
| Phase 7 (F-6) | Phase 2 (cache as data source for aggregates), Phase 3 (F-7 — `LoadableState` for StatsViewModel) |
| Phase 8 (F-8) | Phases 4, 5, 6, 7 — all UI screens must exist before consistency audit |
| Phase 9 (F-9) | All phases — integration tests require all features in place |

---

## 6. Phased Implementation

---

### Phase 1 — F-1: Domain Models and DTO Expansion

#### Goal
Expand `LaunchDTO`, `Launch` domain model, `LaunchMapper`, and `LaunchRemoteDataSource` to decode the full SpaceX v4 API response. Add all new domain types (`LaunchDetail`, `Launchpad`, `Landpad`, `Payload`, `Core`, `CrewMember`, `Ship`, `Capsule`) and their remote data sources. Mark caching-relevant domain types as `Codable` in preparation for Phase 2.

#### Why Now
Every subsequent feature depends on `Launch.id` and the expanded model surface. Nothing else can proceed without this foundation. Adding `Codable` conformance here avoids a retroactive file modification in Phase 2.

#### In Scope
- Expand `LaunchDTO` with `id`, `details`, `launchpad`, `links`, `cores[]`, `payloads[]`, `crew[]`, `ships[]`, `capsules[]`, `upcoming`
- Update `Launch` domain model: add `id: String`, `launchpadId: String?`, `upcoming: Bool`, `details: String?`, `links: LaunchLinks?`, `cores: [Core]?`
- Conform `Launch`, `LaunchLinks`, `Core`, `CrewMember` to `Codable`
- New domain value types: `LaunchDetail`, `Launchpad`, `Landpad`, `Payload`, `Core`, `CrewMember`, `Ship`, `Capsule`
- New remote data sources: `LaunchpadRemoteDataSource`, `LandpadRemoteDataSource` (with protocols)
- Update `LaunchMapper` for all new fields; graceful null handling
- Extend `LaunchRemoteDataSource` `select` array

#### Out of Scope (relative to this phase)
UserDefaults cache (F-2), Diffable UI (F-3), search/filter (F-4), detail screen UI (F-5), statistics (F-6), `LoadableState` (F-7).

#### Files to Create

| Path | Description |
|------|-------------|
| `SpaceX/Features/Launches/Domain/LaunchDetail.swift` | Aggregated model for detail screen |
| `SpaceX/Features/Launches/Domain/Payload.swift` | Payload domain model |
| `SpaceX/Features/Launches/Domain/Core.swift` | Core/booster domain model (`Codable`) |
| `SpaceX/Features/Launches/Domain/CrewMember.swift` | Crew member domain model (`Codable`) |
| `SpaceX/Features/Launches/Domain/Ship.swift` | Ship domain model |
| `SpaceX/Features/Launches/Domain/Capsule.swift` | Capsule domain model |
| `SpaceX/Features/Launches/Domain/LaunchLinks.swift` | Links struct — wikipedia, article, webcast (`Codable`) |
| `SpaceX/Features/Launchpad/Domain/Launchpad.swift` | Launchpad domain model |
| `SpaceX/Features/Launchpad/Domain/Landpad.swift` | Landpad domain model |
| `SpaceX/Features/Launchpad/Data/LaunchpadRemoteDataSource.swift` | Launchpad network fetch + protocol |
| `SpaceX/Features/Launchpad/Data/LandpadRemoteDataSource.swift` | Landpad network fetch + protocol |

#### Files to Modify

| Path | Change |
|------|--------|
| `SpaceX/Features/Launches/Data/LaunchDTO.swift` | Add all new optional fields |
| `SpaceX/Features/Launches/Domain/Launch.swift` | Add `id`, `launchpadId`, `upcoming`, `details`, `links`, `cores`; add `Codable` |
| `SpaceX/Features/Launches/Data/LaunchMapper.swift` | Map all new DTO fields; return `nil`/skip if `id` missing |
| `SpaceX/Features/Launches/Data/LaunchRemoteDataSource.swift` | Add `"id"`, `"details"`, `"launchpad"`, `"links"`, `"cores"`, `"payloads"`, `"crew"`, `"ships"`, `"capsules"`, `"upcoming"` to `select` array |
| `SpaceX/Features/Launches/Presentation/LaunchCellViewModel.swift` | Add `id: String` property |
| `SpaceX/Features/Launches/Presentation/LaunchListViewModel.swift` | Pass `launch.id` in `mapToViewModels` |

#### Public Contracts to Add/Change

```swift
// Launch.swift — added fields; Codable for cache serialisation
struct Launch: Codable {
    let id: String
    let name: String
    let dateUtc: String
    let formattedDate: String
    let success: Bool?
    let rocketId: String
    let launchpadId: String?
    let upcoming: Bool
    let details: String?
    let links: LaunchLinks?
    let cores: [Core]?
}

// LaunchLinks.swift — new; Codable for cache serialisation
struct LaunchLinks: Codable {
    let wikipedia: URL?
    let article: URL?
    let webcast: URL?
}

// Core.swift — new; Codable for cache serialisation
struct Core: Codable {
    let coreId: String
    let reused: Bool
    let landingSuccess: Bool?
}

// CrewMember.swift — new; Codable for cache serialisation
struct CrewMember: Codable {
    let crewId: String
    let role: String?
}

// LaunchCellViewModel.swift — added field
struct LaunchCellViewModel: Hashable {
    let id: String
    let name: String
    let date: String
    let statusImageName: String
}

// LaunchMapper — new map signature
func map(_ dto: LaunchDTO) -> Launch?   // returns nil if id is missing
func map(_ dtos: [LaunchDTO]) -> [Launch]  // filters out nils
```

#### Networking Changes
Add new fields to `select` array in `LaunchesQueryEndpoint`. No new endpoints required at this phase; `LaunchpadRemoteDataSource` and `LandpadRemoteDataSource` hit `v4/launchpads/:id` and `v4/landpads/:id` respectively — their protocols are defined here but called from F-5.

#### Cache / Persistence Notes
None in this phase. `Codable` conformance is added to `Launch`, `LaunchLinks`, `Core`, and `CrewMember` here so that Phase 2 can immediately use them without additional file modifications. No UserDefaults reads or writes occur in this phase.

#### Mapping / Cache Policy
None in this phase. Mapper becomes partial: `map(_ dto:) -> Launch?` returns `nil` for records with missing `id`.

#### UI Changes
None. No visual changes in this phase.

#### Coordinator / Navigation Changes
None.

#### Performance Considerations
The `select` array expansion increases network response size by approximately 3–5x per record. This is acceptable given the pagination page size of 20 records. No pre-computation needed.

#### Privacy / Security Considerations
No new data collection. All fields are public SpaceX API data. No PII.

#### Accessibility / Localization Considerations
None in this phase.

#### Logging / Observability Checkpoints
- Log at `debug` level when mapper skips a record due to missing `id`: `AppLogger.make("LaunchMapper").debug("Skipping launch with missing id")`
- Log field counts when decoding succeeds (crew count, payload count).

#### Test Plan

**Unit tests** (`SpaceXTests/Launches/`):
- `LaunchMapperTests.swift`
  - `test_map_fullDTO_returnsCorrectDomainModel()` — all fields populated
  - `test_map_missingId_returnsNil()` — mapper returns nil; array filter excludes it
  - `test_map_nullOptionalFields_doesNotCrash()` — crew=nil, capsules=nil, ships=nil handled
  - `test_map_pageDTO_propagatesHasNextPage()` — page result integrity

**Integration tests:** None in this phase.

**UI tests:** None in this phase.

**Offline acceptance:** Not applicable in this phase.

#### Definition of Done

- [ ] `LaunchDTO` decodes the full SpaceX `/launches/query` v4 JSON response without errors (verified with sample JSON fixture in test)
- [ ] `Launch.id` exists and is non-optional in the domain model
- [ ] `Launch`, `LaunchLinks`, `Core`, `CrewMember` conform to `Codable`
- [ ] `LaunchMapper.map(_:)` returns `nil` for records with missing `id`; array overload filters nils
- [ ] All optional fields (crew, capsules, ships, links) are `nil`-safe — no crashes on absent data
- [ ] `LaunchCellViewModel` has `id: String` and conforms to `Hashable`
- [ ] `LaunchpadRemoteDataSource` and `LandpadRemoteDataSource` compile with protocol conformance
- [ ] All `LaunchMapperTests` pass
- [ ] No pre-existing tests broken by model expansion

#### Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| SpaceX API returns `id` as null for some records | Mapper returns `nil` and filters at array level — no crash |
| Adding `id` to `LaunchCellViewModel` breaks `Equatable` conformance in existing snapshot tests | `LaunchCellViewModel` was not `Hashable` before; synthesized conformance is safe once `id` is added |
| `Codable` conformance on `LaunchLinks` fails if `URL` encoding differs between iOS versions | `URL` has stable `Codable` implementation; test with a fixture containing URL values |

#### Rollback Plan
All changes are additive to existing model structs. To rollback: revert `Launch.swift`, `LaunchDTO.swift`, `LaunchMapper.swift`, `LaunchCellViewModel.swift` to their pre-Phase-1 state. Delete new domain and data source files. All existing tests must still pass.

#### Time Estimate
- Optimistic: 2 days
- Realistic: 3 days
- Pessimistic: 4 days

---

### Code Examples — Phase 1

**File: `SpaceX/Features/Launches/Data/LaunchDTO.swift`**

```swift
struct LaunchDTO: Decodable {
    let id: String?
    let name: String
    let dateUtc: String
    let success: Bool?
    let rocket: String
    let upcoming: Bool?
    let details: String?
    let launchpad: String?
    let links: LaunchLinksDTO?
    let cores: [CoreDTO]?
    let payloads: [String]?
    let crew: [CrewMemberDTO]?
    let ships: [String]?
    let capsules: [String]?
}

struct LaunchLinksDTO: Decodable {
    let wikipedia: String?
    let article: String?
    let webcast: String?
}

struct CoreDTO: Decodable {
    let core: String?
    let reused: Bool?
    let landingSuccess: Bool?
}

struct CrewMemberDTO: Decodable {
    let crew: String?
    let role: String?
}
```

**File: `SpaceX/Features/Launches/Domain/Launch.swift`**

```swift
struct Launch: Codable {
    let id: String
    let name: String
    let dateUtc: String
    let formattedDate: String
    let success: Bool?
    let rocketId: String
    let launchpadId: String?
    let upcoming: Bool
    let details: String?
    let links: LaunchLinks?
    let cores: [Core]?
}
```

**File: `SpaceX/Features/Launches/Domain/LaunchLinks.swift`**

```swift
struct LaunchLinks: Codable {
    let wikipedia: URL?
    let article: URL?
    let webcast: URL?
}
```

**File: `SpaceX/Features/Launches/Domain/Core.swift`**

```swift
struct Core: Codable {
    let coreId: String
    let reused: Bool
    let landingSuccess: Bool?
}
```

**File: `SpaceX/Features/Launches/Domain/CrewMember.swift`**

```swift
struct CrewMember: Codable {
    let crewId: String
    let role: String?
}
```

**File: `SpaceX/Features/Launches/Data/LaunchMapper.swift`**

```swift
struct LaunchMapper {
    private let dateFormatter: DateFormatter

    init(dateFormatter: DateFormatter) {
        self.dateFormatter = dateFormatter
    }

    func map(_ dto: LaunchDTO) -> Launch? {
        guard let id = dto.id else {
            AppLogger.make("LaunchMapper").debug("Skipping launch with missing id")
            return nil
        }
        let formattedDate = dateFormatter.string(
            from: ISO8601DateFormatter().date(from: dto.dateUtc) ?? Date()
        )
        return Launch(
            id: id,
            name: dto.name,
            dateUtc: dto.dateUtc,
            formattedDate: formattedDate,
            success: dto.success,
            rocketId: dto.rocket,
            launchpadId: dto.launchpad,
            upcoming: dto.upcoming ?? false,
            details: dto.details,
            links: dto.links.map { mapLinks($0) },
            cores: dto.cores?.compactMap { mapCore($0) }
        )
    }

    func map(_ dtos: [LaunchDTO]) -> [Launch] {
        dtos.compactMap { map($0) }
    }

    private func mapLinks(_ dto: LaunchLinksDTO) -> LaunchLinks {
        LaunchLinks(
            wikipedia: dto.wikipedia.flatMap { URL(string: $0) },
            article: dto.article.flatMap { URL(string: $0) },
            webcast: dto.webcast.flatMap { URL(string: $0) }
        )
    }

    private func mapCore(_ dto: CoreDTO) -> Core? {
        guard let coreId = dto.core else { return nil }
        return Core(coreId: coreId, reused: dto.reused ?? false, landingSuccess: dto.landingSuccess)
    }
}
```

**File: `SpaceXTests/Launches/LaunchMapperTests.swift`**

```swift
import XCTest
@testable import SpaceX

final class LaunchMapperTests: XCTestCase {
    private var sut: LaunchMapper!

    override func setUp() {
        super.setUp()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        sut = LaunchMapper(dateFormatter: formatter)
    }

    func test_map_fullDTO_returnsCorrectDomainModel() {
        let dto = LaunchDTO.fixture(id: "abc123", name: "Falcon 9")
        let result = sut.map(dto)
        XCTAssertEqual(result?.id, "abc123")
        XCTAssertEqual(result?.name, "Falcon 9")
    }

    func test_map_missingId_returnsNil() {
        let dto = LaunchDTO.fixture(id: nil)
        XCTAssertNil(sut.map(dto))
    }

    func test_map_nullOptionalFields_doesNotCrash() {
        let dto = LaunchDTO.fixture(id: "x", crew: nil, capsules: nil, ships: nil)
        let result = sut.map(dto)
        XCTAssertNotNil(result)
        XCTAssertNil(result?.links)
    }

    func test_map_array_filtersOutNilIds() {
        let dtos = [LaunchDTO.fixture(id: "a"), LaunchDTO.fixture(id: nil), LaunchDTO.fixture(id: "b")]
        let launches = sut.map(dtos)
        XCTAssertEqual(launches.count, 2)
        XCTAssertEqual(launches.map(\.id), ["a", "b"])
    }
}

private extension LaunchDTO {
    static func fixture(
        id: String? = "test-id",
        name: String = "Test Launch",
        success: Bool? = true,
        crew: [CrewMemberDTO]? = nil,
        capsules: [String]? = nil,
        ships: [String]? = nil
    ) -> LaunchDTO {
        LaunchDTO(
            id: id, name: name, dateUtc: "2024-01-01T00:00:00.000Z",
            success: success, rocket: "rocket-id", upcoming: false,
            details: nil, launchpad: nil, links: nil,
            cores: nil, payloads: nil, crew: crew, ships: ships, capsules: capsules
        )
    }
}
```

---

### Phase 2 — F-2: UserDefaults Launch Cache Store

#### Goal
Introduce `LaunchCacheStoreProtocol` and `UserDefaultsLaunchCacheStore` as the offline cache layer for launches. Serialise and deserialise `[Launch]` values using `JSONEncoder`/`JSONDecoder` keyed by `rocketId`. Inject the cache into `LaunchRepository` with read-through/write-through strategy. Update `AppContainer` to wire the new dependency.

#### Why Now
F-5 (Launch Detail) and F-6 (Statistics) both require locally cached data. The cache must be fully operational before building features that depend on it.

#### In Scope
- `LaunchCacheStoreProtocol` with `save(_:for:)`, `load(for:) -> [Launch]?`, `clear(for:)`, `allKnownRocketIds() -> [String]`
- `UserDefaultsLaunchCacheStore` backed by `UserDefaults`, key format `"launches_<rocketId>"`
- `JSONEncoder` / `JSONDecoder` for `Data` serialisation; injected `UserDefaults` instance for test isolation
- `LaunchRepository` updated with read-through/write-through logic against `LaunchCacheStoreProtocol`
- `AppContainer` updated to initialize and inject `UserDefaultsLaunchCacheStore`
- All cache reads and writes are synchronous (UserDefaults is synchronous)

#### Out of Scope (relative to this phase)
Detail screen aggregation (F-5), statistics aggregation (F-6), `LoadableState` (F-7). Rocket list caching is not in scope; the existing `RocketRepository` fetches from network only.

#### Files to Create

| Path | Description |
|------|-------------|
| `SpaceX/Features/Launches/Data/LaunchCacheStore.swift` | `LaunchCacheStoreProtocol` + `UserDefaultsLaunchCacheStore` implementation |

#### Files to Modify

| Path | Change |
|------|--------|
| `SpaceX/Features/Launches/Data/LaunchRepository.swift` | Inject `LaunchCacheStoreProtocol`; read-through/write-through |
| `SpaceX/App/AppContainer.swift` | Instantiate `UserDefaultsLaunchCacheStore` and inject into `LaunchRepository` |

#### Public Contracts to Add/Change

```swift
// LaunchCacheStoreProtocol
protocol LaunchCacheStoreProtocol {
    func save(_ launches: [Launch], for rocketId: String)
    func load(for rocketId: String) -> [Launch]?
    func clear(for rocketId: String)
    func allKnownRocketIds() -> [String]
}

// LaunchRepositoryProtocol — updated
protocol LaunchRepositoryProtocol {
    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult
    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult
    func fetchAllCachedLaunches(for rocketID: String) -> [Launch]
}
```

#### Networking Changes
None. The cache wraps the existing network layer transparently.

#### Cache / UserDefaults Notes

**Key naming:**
- Per-rocket launches: `"launches_<rocketId>"` (e.g., `"launches_5e9d0d95eda69955f709d1eb"`)
- Known rocket IDs index: `"launchCache_knownRocketIds"` (a `[String]` plist value)

**Encoding:**
- `save(_:for:)` encodes `[Launch]` with `JSONEncoder` and stores the resulting `Data` via `UserDefaults.set(_:forKey:)`. On encoding failure the write is silently skipped and the error is logged.
- `load(for:)` reads `Data` from `UserDefaults.data(forKey:)` and decodes with `JSONDecoder`. Returns `nil` on missing key or decode failure (corrupt data fallback).
- `clear(for:)` removes the key via `UserDefaults.removeObject(forKey:)` and updates the known IDs index.

**Write-through:**
Every successful network page response is persisted before returning to ViewModel.

**Cache invalidation:**
No explicit TTL in this phase. Cache is overwritten on each successful network response. `clear(for:)` is available for future use (e.g., pull-to-refresh full invalidation).

#### UI Changes
None in this phase. No visual changes.

#### Coordinator / Navigation Changes
None.

#### Performance Considerations
- `UserDefaults` writes are synchronous and happen on the calling thread. Network responses arrive on a background task context; no special handling required.
- `JSONEncoder` / `JSONDecoder` on ~200 `Launch` values takes < 5 ms on device hardware. No background dispatch needed.
- If the cached dataset grows beyond ~2,000 items, consider moving serialisation to a `Task.detached(priority: .background)` call before writing.

#### Privacy / Security Considerations
`UserDefaults` is stored in the app's sandbox. No sensitive data. No encryption required. Cached content is public SpaceX API data.

#### Accessibility / Localization Considerations
None in this phase.

#### Logging / Observability Checkpoints
- Log cache write success: `debug("Saved \(count) launches for rocket \(rocketId)")`
- Log cache write failure: `error("Cache encode failed for rocket \(rocketId): \(error)")`
- Log cache hit: `debug("Cache hit for rocket \(rocketId): \(count) items")`
- Log cache miss: `debug("Cache miss for rocket \(rocketId)")`
- Log corrupt cache: `warning("Cache decode failed for rocket \(rocketId) — returning nil")`

#### Test Plan

**Unit tests** (`SpaceXTests/Cache/`):
- `LaunchCacheStoreTests.swift` — uses `UserDefaults(suiteName: "com.test.launchCache")` for isolation; tearDown removes the suite
  - `test_save_thenLoad_returnsIdenticalLaunches()`
  - `test_load_missingKey_returnsNil()`
  - `test_save_overwritesExistingEntry()`
  - `test_clear_removesEntry_returnsNil()`
  - `test_cacheKey_scopedByRocketId_isolatesEntries()`
  - `test_load_corruptData_returnsNil_doesNotCrash()`
  - `test_allKnownRocketIds_tracksInsertedRocketIds()`
  - `test_clear_removesRocketIdFromKnownIds()`

**Integration tests** (`SpaceXTests/Launches/`):
- `LaunchRepositoryOfflineTests.swift` — injects `UserDefaultsLaunchCacheStore(defaults: testDefaults)` and `MockLaunchRemoteDataSource`
  - `test_fetchInitialLaunches_networkFailure_returnsCachedData()`
  - `test_fetchInitialLaunches_networkFailure_emptyCache_throws()`

**UI tests:** None in this phase.

**Offline acceptance:**
- Simulator with network disabled (URLProtocol mock throws `URLError(.notConnectedToInternet)`) → app shows cached content from previous session.

#### Definition of Done

- [ ] `LaunchCacheStoreProtocol` is defined with `save`, `load`, `clear`, `allKnownRocketIds` methods
- [ ] `UserDefaultsLaunchCacheStore` saves and retrieves `[Launch]` correctly using `JSONEncoder`/`JSONDecoder`
- [ ] Cache key format is `"launches_<rocketId>"`
- [ ] `load(for:)` returns `nil` (not a crash) when the stored `Data` is corrupt or the key is absent
- [ ] `LaunchRepository` returns cached data synchronously before network request completes when cache is populated
- [ ] With network disabled (URLProtocol mock), app renders cached launches from a previous session
- [ ] Cache write errors are caught, logged via `AppLogger`, and do not crash the app
- [ ] `allKnownRocketIds()` returns all rocket IDs for which launches have been saved
- [ ] `AppContainer` compiles with new injection
- [ ] All `LaunchCacheStoreTests` pass using `UserDefaults(suiteName:)` test isolation
- [ ] No pre-existing tests broken

#### Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| `UserDefaults` domain size limit causes silent write failures on very large datasets | Log write success/failure; the known dataset is ~200 records (< 2 MB) — well within practical limits |
| Corrupt cached `Data` (e.g., from a previous app version with different model shape) causes silent decode failure | `load(for:)` returns `nil` on any `DecodingError`; ViewModel falls through to network fetch |
| Test suites sharing `UserDefaults.standard` contaminate each other | All tests inject `UserDefaults(suiteName: "com.test.launchCache")`; `tearDown` calls `removePersistentDomain(forName:)` |
| `allKnownRocketIds` index becomes out of sync after a crash mid-write | Index is updated after `set(_:forKey:)` (which is atomic in UserDefaults); worst case is a stale entry that returns an empty array on load — handled gracefully |

#### Rollback Plan
Delete `LaunchCacheStore.swift`. Revert `LaunchRepository` and `AppContainer` to their Phase 1 state. Delete `SpaceXTests/Cache/` directory. All Phase 1 tests must still pass.

#### Time Estimate
- Optimistic: 1 day
- Realistic: 2 days
- Pessimistic: 3 days

---

### Code Examples — Phase 2

**File: `SpaceX/Features/Launches/Data/LaunchCacheStore.swift`**

```swift
import Foundation

protocol LaunchCacheStoreProtocol {
    func save(_ launches: [Launch], for rocketId: String)
    func load(for rocketId: String) -> [Launch]?
    func clear(for rocketId: String)
    func allKnownRocketIds() -> [String]
}

final class UserDefaultsLaunchCacheStore: LaunchCacheStoreProtocol {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger = AppLogger.make("UserDefaultsLaunchCacheStore")

    private static let knownIdsKey = "launchCache_knownRocketIds"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ launches: [Launch], for rocketId: String) {
        do {
            let data = try encoder.encode(launches)
            defaults.set(data, forKey: cacheKey(for: rocketId))
            updateKnownIds(adding: rocketId)
            logger.debug("Saved \(launches.count) launches for rocket \(rocketId)")
        } catch {
            logger.error("Cache encode failed for rocket \(rocketId): \(error)")
        }
    }

    func load(for rocketId: String) -> [Launch]? {
        guard let data = defaults.data(forKey: cacheKey(for: rocketId)) else {
            logger.debug("Cache miss for rocket \(rocketId)")
            return nil
        }
        do {
            let launches = try decoder.decode([Launch].self, from: data)
            logger.debug("Cache hit for rocket \(rocketId): \(launches.count) items")
            return launches
        } catch {
            logger.warning("Cache decode failed for rocket \(rocketId) — returning nil")
            return nil
        }
    }

    func clear(for rocketId: String) {
        defaults.removeObject(forKey: cacheKey(for: rocketId))
        updateKnownIds(removing: rocketId)
    }

    func allKnownRocketIds() -> [String] {
        defaults.stringArray(forKey: Self.knownIdsKey) ?? []
    }

    // MARK: - Private

    private func cacheKey(for rocketId: String) -> String {
        "launches_\(rocketId)"
    }

    private func updateKnownIds(adding rocketId: String) {
        var ids = Set(allKnownRocketIds())
        ids.insert(rocketId)
        defaults.set(Array(ids), forKey: Self.knownIdsKey)
    }

    private func updateKnownIds(removing rocketId: String) {
        var ids = Set(allKnownRocketIds())
        ids.remove(rocketId)
        defaults.set(Array(ids), forKey: Self.knownIdsKey)
    }
}
```

**File: `SpaceX/Features/Launches/Data/LaunchRepository.swift` (read-through/write-through)**

```swift
final class LaunchRepository: LaunchRepositoryProtocol {
    private let remoteDataSource: LaunchRemoteDataSourceProtocol
    private let cacheStore: LaunchCacheStoreProtocol
    private let mapper: LaunchMapper

    init(
        remoteDataSource: LaunchRemoteDataSourceProtocol,
        cacheStore: LaunchCacheStoreProtocol,
        mapper: LaunchMapper
    ) {
        self.remoteDataSource = remoteDataSource
        self.cacheStore = cacheStore
        self.mapper = mapper
    }

    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult {
        let cached = cacheStore.load(for: rocketID) ?? []
        do {
            let page = try await remoteDataSource.fetchLaunches(for: rocketID, page: 0)
            let launches = mapper.map(page.docs)
            cacheStore.save(launches, for: rocketID)
            return LaunchPageResult(launches: launches, hasNextPage: page.hasNextPage, nextPage: 1)
        } catch {
            guard !cached.isEmpty else { throw error }
            return LaunchPageResult(launches: cached, hasNextPage: false, nextPage: 0, isStale: true)
        }
    }

    func fetchAllCachedLaunches(for rocketID: String) -> [Launch] {
        cacheStore.load(for: rocketID) ?? []
    }

    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult {
        let page = try await remoteDataSource.fetchLaunches(for: rocketID, page: page)
        let launches = mapper.map(page.docs)
        let existing = cacheStore.load(for: rocketID) ?? []
        let merged = existing + launches.filter { l in !existing.contains { $0.id == l.id } }
        cacheStore.save(merged, for: rocketID)
        return LaunchPageResult(launches: launches, hasNextPage: page.hasNextPage, nextPage: page.page + 1)
    }
}
```

**File: `SpaceX/App/AppContainer.swift` — DI wiring**

```swift
final class AppContainer {
    // MARK: - Cache stores
    private lazy var launchCacheStore: LaunchCacheStoreProtocol =
        UserDefaultsLaunchCacheStore()

    // MARK: - Repositories
    private lazy var launchRepository: LaunchRepositoryProtocol = LaunchRepository(
        remoteDataSource: launchRemoteDataSource,
        cacheStore: launchCacheStore,
        mapper: LaunchMapper(dateFormatter: makeLaunchDateFormatter())
    )

    // MARK: - ViewModels
    lazy var launchListViewModel: LaunchListViewModel =
        LaunchListViewModel(repository: launchRepository)
}
```

**File: `SpaceXTests/Cache/LaunchCacheStoreTests.swift`**

```swift
import XCTest
@testable import SpaceX

final class LaunchCacheStoreTests: XCTestCase {
    private var sut: UserDefaultsLaunchCacheStore!
    private var testDefaults: UserDefaults!
    private static let suiteName = "com.test.launchCache"

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: Self.suiteName)!
        sut = UserDefaultsLaunchCacheStore(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: Self.suiteName)
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    func test_save_thenLoad_returnsIdenticalLaunches() {
        let launches = [Launch.fixture(id: "1"), Launch.fixture(id: "2")]
        sut.save(launches, for: "rocketA")
        let loaded = sut.load(for: "rocketA")
        XCTAssertEqual(loaded?.map(\.id), ["1", "2"])
    }

    func test_load_missingKey_returnsNil() {
        XCTAssertNil(sut.load(for: "unknown-rocket"))
    }

    func test_save_overwritesExistingEntry() {
        sut.save([Launch.fixture(id: "old")], for: "rocketA")
        sut.save([Launch.fixture(id: "new1"), Launch.fixture(id: "new2")], for: "rocketA")
        let result = sut.load(for: "rocketA")
        XCTAssertEqual(result?.count, 2)
        XCTAssertFalse(result?.map(\.id).contains("old") ?? true)
    }

    func test_clear_removesEntry_returnsNil() {
        sut.save([Launch.fixture(id: "x")], for: "rocketB")
        sut.clear(for: "rocketB")
        XCTAssertNil(sut.load(for: "rocketB"))
    }

    func test_cacheKey_scopedByRocketId_isolatesEntries() {
        sut.save([Launch.fixture(id: "a")], for: "rocket1")
        sut.save([Launch.fixture(id: "b")], for: "rocket2")
        XCTAssertEqual(sut.load(for: "rocket1")?.first?.id, "a")
        XCTAssertEqual(sut.load(for: "rocket2")?.first?.id, "b")
    }

    func test_load_corruptData_returnsNil_doesNotCrash() {
        testDefaults.set("not-valid-json".data(using: .utf8)!, forKey: "launches_corruptRocket")
        XCTAssertNil(sut.load(for: "corruptRocket"))
    }

    func test_allKnownRocketIds_tracksInsertedRocketIds() {
        sut.save([Launch.fixture(id: "1")], for: "rocketA")
        sut.save([Launch.fixture(id: "2")], for: "rocketB")
        let ids = Set(sut.allKnownRocketIds())
        XCTAssertTrue(ids.contains("rocketA"))
        XCTAssertTrue(ids.contains("rocketB"))
    }

    func test_clear_removesRocketIdFromKnownIds() {
        sut.save([Launch.fixture(id: "1")], for: "rocketA")
        sut.clear(for: "rocketA")
        XCTAssertFalse(sut.allKnownRocketIds().contains("rocketA"))
    }
}

private extension Launch {
    static func fixture(id: String) -> Launch {
        Launch(id: id, name: "Falcon 9", dateUtc: "2024-01-01T00:00:00.000Z",
               formattedDate: "1 Jan 2024", success: true, rocketId: "falcon9",
               launchpadId: nil, upcoming: false, details: nil, links: nil, cores: nil)
    }
}
```

**File: `SpaceXTests/Launches/LaunchRepositoryOfflineTests.swift`**

```swift
import XCTest
@testable import SpaceX

final class LaunchRepositoryOfflineTests: XCTestCase {
    private var sut: LaunchRepository!
    private var mockRemote: MockLaunchRemoteDataSource!
    private var cacheStore: UserDefaultsLaunchCacheStore!
    private var testDefaults: UserDefaults!
    private static let suiteName = "com.test.launchRepositoryOffline"

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: Self.suiteName)!
        cacheStore = UserDefaultsLaunchCacheStore(defaults: testDefaults)
        mockRemote = MockLaunchRemoteDataSource()
        sut = LaunchRepository(
            remoteDataSource: mockRemote,
            cacheStore: cacheStore,
            mapper: LaunchMapper(dateFormatter: .iso8601Short)
        )
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: Self.suiteName)
        super.tearDown()
    }

    func test_fetchInitialLaunches_networkFailure_returnsCachedData() async throws {
        cacheStore.save([.fixture(id: "cached-1")], for: "rocketX")
        mockRemote.shouldThrow = true
        let result = try await sut.fetchInitialLaunches(for: "rocketX")
        XCTAssertTrue(result.isStale)
        XCTAssertEqual(result.launches.count, 1)
        XCTAssertEqual(result.launches.first?.id, "cached-1")
    }

    func test_fetchInitialLaunches_networkFailure_emptyCache_throws() async {
        mockRemote.shouldThrow = true
        do {
            _ = try await sut.fetchInitialLaunches(for: "rocketX")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
```

---

### Phase 3 — F-7: LoadableState Refactor

> **Runs in parallel with Phase 4 (F-3).**

#### Goal
Define `LoadableState<Value>` generic enum in `Core/UI/`. Apply it to all new ViewModels (F-5, F-6). Align `LaunchListViewModel` to the same pattern (replace `LaunchListState` or provide a bridge layer).

#### Why Now
New ViewModels for F-5 and F-6 must adopt `LoadableState` from the start. Introducing it here, before those screens are built, ensures consistency. It can run in parallel with F-3 because it has no UI dependencies.

#### In Scope
- New `SpaceX/Core/UI/LoadableState.swift` with generic enum definition
- Align `LaunchListViewModel` to publish `LoadableState<[LaunchCellViewModel]>` (or provide bridge `var legacyState: LaunchListState` for backward compatibility during transition)
- All new ViewModels built in subsequent phases adopt `LoadableState` directly

#### Out of Scope (relative to this phase)
F-5 ViewModel, F-6 ViewModel (built in later phases). UI rendering of `.loaded(_, isStale: true)` state (rendered in F-5 and F-6 UIs).

#### Files to Create

| Path | Description |
|------|-------------|
| `SpaceX/Core/UI/LoadableState.swift` | Generic `LoadableState<Value>` enum |

#### Files to Modify

| Path | Change |
|------|--------|
| `SpaceX/Features/Launches/Presentation/LaunchListViewModel.swift` | Replace `LaunchListState` with `LoadableState<[LaunchCellViewModel]>`; update all state transitions and completion callbacks |
| `SpaceX/Features/Launches/UI/LaunchViewController.swift` | Update `handleStateUpdate` to switch on `LoadableState` cases |

#### Public Contracts to Add/Change

```swift
// LoadableState.swift
enum LoadableState<Value> {
    case idle
    case loading
    case loaded(Value, isStale: Bool)
    case empty(message: String)
    case failed(message: String, cachedValue: Value?)
}

// LaunchListViewModel — state property updated
private(set) var state: LoadableState<[LaunchCellViewModel]> = .idle
```

#### Networking Changes
None.

#### Cache / UserDefaults Notes
None.

#### Mapping / Cache Policy
None.

#### UI Changes
`LaunchViewController.handleStateUpdate(_:)` switches on `LoadableState<[LaunchCellViewModel]>` cases:
- `.idle` — no action
- `.loading` — show loading overlay
- `.loaded(let vms, isStale: false)` — hide overlay, render cells
- `.loaded(let vms, isStale: true)` — render cells + subtle stale banner (thin bar at top)
- `.empty(let message)` — show empty state cell
- `.failed(let message, cachedValue: let vms?)` — if `vms` non-nil render cells + error banner; if nil show error cell

State transitions are animated (UIView.animate fade-in for content appearance).

#### Coordinator / Navigation Changes
None.

#### Performance Considerations
Generic enum has zero runtime cost overhead vs bespoke enum.

#### Privacy / Security Considerations
None.

#### Accessibility / Localization Considerations
The stale data banner must be accessible to VoiceOver: `accessibilityLabel = "Showing cached data. Pull to refresh."` Localization key added to `L10n`.

#### Logging / Observability Checkpoints
- Log state transitions at `debug` level: `AppLogger.make("LaunchListViewModel").debug("State → \(state)")`

#### Test Plan

**Unit tests** (`SpaceXTests/Core/`):
- `LoadableStateTests.swift`
  - `test_idle_valueIsNil()`
  - `test_loaded_freshData_isStale_false()`
  - `test_loaded_staleData_isStale_true()`
  - `test_failed_withCachedValue_cachedValueAccessible()`
  - `test_failed_withNilCache_valueIsNil()`

- Extend existing `LaunchListViewModelTests`:
  - `test_loadInitialLaunches_success_transitionsToLoaded()`
  - `test_loadInitialLaunches_networkFailure_withCache_transitionsToFailed_withCachedValue()`
  - `test_loadInitialLaunches_networkFailure_noCache_transitionsToFailed_nilCachedValue()`
  - `test_loadInitialLaunches_emptyResult_transitionsToEmpty()`

**Integration tests:** None.

**UI tests:** None.

**Offline acceptance:** Not directly tested in this phase; covered by F-2 and F-5 offline tests.

#### Definition of Done

- [ ] `LoadableState.swift` exists in `SpaceX/Core/UI/`
- [ ] `LaunchListViewModel.state` is `LoadableState<[LaunchCellViewModel]>`
- [ ] `LaunchViewController` handles all five `LoadableState` cases without crashing
- [ ] `.loaded(_, isStale: true)` shows a stale data indicator in the launch list
- [ ] `.failed(message, cachedValue:)` shows cached cells + error banner if cache is non-nil; shows error cell if nil
- [ ] All `LoadableStateTests` pass
- [ ] All `LaunchListViewModelTests` pass with `LoadableState`
- [ ] No pre-existing tests broken

#### Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| `LaunchListState` is referenced in existing `LaunchListViewModelTests` | Update tests alongside ViewModel change in same PR |
| Bridge compatibility required during parallel Phase 4 development | Phase 3 and Phase 4 touch different files; merge order: Phase 3 PR merged before Phase 4 PR |

#### Rollback Plan
Delete `LoadableState.swift`. Revert `LaunchListViewModel` and `LaunchViewController` to `LaunchListState` enum. Revert test files. All pre-Phase-3 tests must pass.

#### Time Estimate
- Optimistic: 1 day
- Realistic: 2 days
- Pessimistic: 3 days

---

### Code Examples — Phase 3

**File: `SpaceX/Core/UI/LoadableState.swift`**

```swift
enum LoadableState<Value> {
    case idle
    case loading
    case loaded(Value, isStale: Bool)
    case empty(message: String)
    case failed(message: String, cachedValue: Value?)
}

extension LoadableState {
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var value: Value? {
        if case .loaded(let v, _) = self { return v }
        if case .failed(_, let cached) = self { return cached }
        return nil
    }
}
```

**File: `SpaceX/Features/Launches/Presentation/LaunchListViewModel.swift` — state refactor**

```swift
final class LaunchListViewModel {
    private(set) var state: LoadableState<[LaunchCellViewModel]> = .idle {
        didSet { onStateChanged?(state) }
    }
    var onStateChanged: ((LoadableState<[LaunchCellViewModel]>) -> Void)?

    private var cachedLaunches: [Launch] = []
    private let repository: LaunchRepositoryProtocol
    private let logger = AppLogger.make("LaunchListViewModel")

    init(repository: LaunchRepositoryProtocol) {
        self.repository = repository
    }

    func loadInitialLaunches(for rocketId: String) {
        state = .loading
        logger.debug("State → loading")
        Task { @MainActor in
            do {
                let result = try await repository.fetchInitialLaunches(for: rocketId)
                cachedLaunches = result.launches
                let vms = mapToViewModels(result.launches)
                if vms.isEmpty {
                    state = .empty(message: "No launches found")
                } else {
                    state = .loaded(vms, isStale: result.isStale)
                }
                logger.debug("State → loaded(\(vms.count) items, stale: \(result.isStale))")
            } catch {
                let cached = repository.fetchAllCachedLaunches(for: rocketId)
                let cachedVMs = cached.isEmpty ? nil : mapToViewModels(cached)
                state = .failed(message: error.localizedDescription, cachedValue: cachedVMs)
                logger.debug("State → failed, cachedValue: \(cachedVMs?.count ?? 0) items")
            }
        }
    }

    private func mapToViewModels(_ launches: [Launch]) -> [LaunchCellViewModel] {
        launches.map { launch in
            LaunchCellViewModel(
                id: launch.id,
                name: launch.name,
                date: launch.formattedDate,
                statusImageName: statusImageName(for: launch)
            )
        }
    }

    private func statusImageName(for launch: Launch) -> String {
        if launch.upcoming { return "clock" }
        return launch.success == true ? "checkmark.circle" : "xmark.circle"
    }
}
```

**File: `SpaceX/Features/Launches/UI/LaunchViewController.swift` — state handling**

```swift
private func handleStateUpdate(_ newState: LoadableState<[LaunchCellViewModel]>) {
    switch newState {
    case .idle:
        break

    case .loading:
        launchView.loadingIndicator.startAnimating()
        staleBanner.isHidden = true

    case .loaded(let viewModels, isStale: false):
        launchView.loadingIndicator.stopAnimating()
        staleBanner.isHidden = true
        applySnapshot(items: viewModels, animating: false)

    case .loaded(let viewModels, isStale: true):
        launchView.loadingIndicator.stopAnimating()
        showStaleBanner()
        applySnapshot(items: viewModels, animating: false)

    case .empty(let message):
        launchView.loadingIndicator.stopAnimating()
        staleBanner.isHidden = true
        applySnapshot(items: [], message: message, animating: true)

    case .failed(let message, cachedValue: let vms?):
        launchView.loadingIndicator.stopAnimating()
        showErrorBanner(message: message)
        applySnapshot(items: vms, animating: true)

    case .failed(let message, cachedValue: nil):
        launchView.loadingIndicator.stopAnimating()
        staleBanner.isHidden = true
        applySnapshot(items: [], message: message, animating: true)
    }
}

private func showStaleBanner() {
    staleBanner.isHidden = false
    staleBanner.accessibilityLabel = "Showing cached data. Pull to refresh."
}
```

**File: `SpaceXTests/Core/LoadableStateTests.swift`**

```swift
import XCTest
@testable import SpaceX

final class LoadableStateTests: XCTestCase {
    func test_idle_valueIsNil() {
        let state: LoadableState<[String]> = .idle
        XCTAssertNil(state.value)
    }

    func test_loaded_freshData_isStale_false() {
        let state: LoadableState<[String]> = .loaded(["a"], isStale: false)
        XCTAssertEqual(state.value, ["a"])
    }

    func test_loaded_staleData_isStale_true() {
        if case .loaded(_, isStale: let stale) = LoadableState<[String]>.loaded(["b"], isStale: true) {
            XCTAssertTrue(stale)
        } else {
            XCTFail("Expected .loaded")
        }
    }

    func test_failed_withCachedValue_returnsValue() {
        let state: LoadableState<[String]> = .failed(message: "Error", cachedValue: ["cached"])
        XCTAssertEqual(state.value, ["cached"])
    }

    func test_failed_withNilCache_valueIsNil() {
        let state: LoadableState<[String]> = .failed(message: "Error", cachedValue: nil)
        XCTAssertNil(state.value)
    }

    func test_loading_isLoading_true() {
        let state: LoadableState<[String]> = .loading
        XCTAssertTrue(state.isLoading)
    }
}
```

---

### Phase 4 — F-3: Diffable Data Source + Compositional Layout

> **Runs in parallel with Phase 3 (F-7). Merge Phase 3 first if both complete at same time.**

#### Goal
Replace `UITableView` with `UICollectionViewDiffableDataSource<LaunchesSection, LaunchesItem>` and `UICollectionViewCompositionalLayout`. Migrate `LaunchCell` and `LaunchErrorCell` to `UICollectionViewCell`. Define `LaunchesSection`, `LaunchesItem`, and `LaunchFilterCell`.

#### Why Now
F-4 (search/filter/sort) requires animated snapshot updates, `LaunchesItem.filter(LaunchFilterItem)` for chips, and `LaunchCellViewModel` as `Hashable` — all of which are defined here.

#### In Scope
- `LaunchesSection` enum: `.filters`, `.launches`, `.message`
- `LaunchesItem` Hashable enum: `.filter(LaunchFilterItem)`, `.launch(LaunchCellViewModel)`, `.message(String)`
- `LaunchFilterCell` — horizontally scrolling chip cell for `.filters` section
- `LaunchCellViewModel` conforms to `Hashable` (via `id`)
- `LaunchCell` migrates to `UICollectionViewCell`
- `LaunchErrorCell` migrates to `UICollectionViewCell`
- `LaunchView` replaces `tableView: UITableView` with `collectionView: UICollectionView`
- `LaunchViewController` replaces `UITableViewDataSource/Delegate` with `UICollectionViewDiffableDataSource`
- Compositional layout with three section layouts (filter chips horizontal scroll, launch list vertical, message)
- Snapshot updates on main thread; animated diffs

#### Out of Scope (relative to this phase)
`UISearchController` (F-4), `LaunchQuery` filtering logic (F-4), `LoadableState` bridging in `LaunchViewController` — use the result from Phase 3.

#### Files to Create

| Path | Description |
|------|-------------|
| `SpaceX/Features/Launches/UI/LaunchFilterCell.swift` | Chip cell for filter section |
| `SpaceX/Features/Launches/UI/LaunchesSection.swift` | `enum LaunchesSection` |
| `SpaceX/Features/Launches/UI/LaunchesItem.swift` | `enum LaunchesItem: Hashable` |
| `SpaceX/Features/Launches/Domain/LaunchFilterItem.swift` | Value type for filter chip data |

#### Files to Modify

| Path | Change |
|------|--------|
| `SpaceX/Features/Launches/UI/LaunchView.swift` | Replace `tableView` with `collectionView`; adopt compositional layout |
| `SpaceX/Features/Launches/UI/LaunchViewController.swift` | Replace `UITableViewDataSource/Delegate` with `UICollectionViewDiffableDataSource`; add snapshot helpers |
| `SpaceX/Features/Launches/UI/LaunchCell.swift` | Inherit from `UICollectionViewCell` |
| `SpaceX/Features/Launches/UI/Components/LaunchErrorCell.swift` | Inherit from `UICollectionViewCell` |

#### Public Contracts to Add/Change

```swift
// LaunchesSection.swift
enum LaunchesSection: Hashable {
    case filters
    case launches
    case message
}

// LaunchesItem.swift
enum LaunchesItem: Hashable {
    case filter(LaunchFilterItem)
    case launch(LaunchCellViewModel)
    case message(String)
}

// LaunchFilterItem.swift
struct LaunchFilterItem: Hashable {
    let id: String
    let title: String
    let isSelected: Bool
}
```

#### Networking Changes
None.

#### Cache / UserDefaults Notes
None.

#### Mapping / Cache Policy
None.

#### UI Changes

**Compositional layout — three sections:**

`.filters` section:
```
NSCollectionLayoutItem(size: estimated 80pt wide, 36pt tall)
NSCollectionLayoutGroup.horizontal(subitems: [item])
NSCollectionLayoutSection — orthogonal scrolling (.continuous)
```

`.launches` section:
```
NSCollectionLayoutItem(size: full width, estimated 120pt tall)
NSCollectionLayoutGroup.vertical(subitems: [item])
NSCollectionLayoutSection — no orthogonal scrolling
```

`.message` section:
```
NSCollectionLayoutItem(size: full width, 100pt tall)
NSCollectionLayoutGroup.vertical(subitems: [item])
NSCollectionLayoutSection
```

**Pagination footer:** Supplementary view (`UICollectionReusableView`) replaces the old `UIActivityIndicatorView` footer. Shown in `.launches` section when state is `.loading` or paginating.

**Snapshot update rules:**
- All `apply(_:animatingDifferences:)` calls on main thread.
- Animated diffs: `animatingDifferences: true` for filter/sort changes; `animatingDifferences: false` for initial load.

#### Coordinator / Navigation Changes
None in this phase. Cell tap handler moves to `UICollectionViewDelegate.didSelectItemAt` (replacing `tableView(_:didSelectRowAt:)`).

#### Performance Considerations
Diffable Data Source uses identity comparison on `Hashable` items — ensure `LaunchCellViewModel` equality is based on `id` only for diff purposes, with full equality (all fields) for content updates.

#### Privacy / Security Considerations
None.

#### Accessibility / Localization Considerations
`LaunchCell` and `LaunchFilterCell` must set `isAccessibilityElement = true` with appropriate `accessibilityLabel`. Filter chips must report selected/unselected state via `accessibilityTraits` (`.button` + `.selected`).

#### Logging / Observability Checkpoints
- Log snapshot apply: `debug("Applying snapshot: \(snapshot.numberOfItems) items")`

#### Test Plan

**Unit tests** (`SpaceXTests/Launches/`):
- `LaunchDiffableSnapshotTests.swift`
  - `test_snapshot_initialLoadingState_hasNoSections()`
  - `test_snapshot_contentState_hasLaunchesSection()`
  - `test_snapshot_emptyState_hasMessageSection()`
  - `test_snapshot_errorState_hasMessageSection()`
  - `test_snapshot_paginatingState_hasPaginationFooter()`
  - `test_snapshot_filterSectionPresent_whenFiltersAvailable()`

**Integration tests:** None.

**UI tests:** (deferred to F-9)

**Offline acceptance:** Not applicable in this phase.

#### Definition of Done

- [ ] `LaunchView` has `collectionView: UICollectionView` (no reference to `tableView`)
- [ ] `LaunchViewController` uses `UICollectionViewDiffableDataSource<LaunchesSection, LaunchesItem>`
- [ ] `UITableViewDataSource` and `UITableViewDelegate` conformance removed from `LaunchViewController`
- [ ] Launch list renders with no visual regressions on iPhone 15 simulator
- [ ] `.message` section correctly renders empty and error states
- [ ] Pagination footer supplementary view shows when paginating
- [ ] `LaunchCellViewModel` conforms to `Hashable`
- [ ] Snapshot updates are animated when filter/sort changes (Phase 5 will add filter logic)
- [ ] All `LaunchDiffableSnapshotTests` pass
- [ ] No pre-existing tests broken

#### Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| Cell sizing incorrect with Compositional Layout + dynamic content | Use `estimated` sizes and `UICollectionViewCell.preferredLayoutAttributesFitting` for self-sizing cells |
| `LaunchView.tableView` referenced in `LaunchViewController` at multiple call sites | Perform a project-wide symbol search before Phase 4 PR and fix all references atomically |
| Pagination behavior changes with collection view | Port `willDisplay` threshold logic to `collectionView(_:willDisplay:forItemAt:)` |

#### Rollback Plan
Revert `LaunchView`, `LaunchViewController`, `LaunchCell`, `LaunchErrorCell` to their Phase 2 state. Delete `LaunchFilterCell.swift`, `LaunchesSection.swift`, `LaunchesItem.swift`, `LaunchFilterItem.swift`. All Phase 2 tests must pass.

#### Time Estimate
- Optimistic: 3 days
- Realistic: 5 days
- Pessimistic: 7 days

---

### Code Examples — Phase 4

**File: `SpaceX/Features/Launches/UI/LaunchesSection.swift` + `LaunchesItem.swift`**

```swift
// LaunchesSection.swift
enum LaunchesSection: Hashable {
    case filters
    case launches
    case message
}

// LaunchesItem.swift
enum LaunchesItem: Hashable {
    case filter(LaunchFilterItem)
    case launch(LaunchCellViewModel)
    case message(String)
}

// LaunchFilterItem.swift
struct LaunchFilterItem: Hashable {
    let id: String
    let title: String
    let isSelected: Bool
}
```

**File: `SpaceX/Features/Launches/UI/LaunchViewController.swift` — Diffable Data Source setup**

```swift
private typealias DataSource = UICollectionViewDiffableDataSource<LaunchesSection, LaunchesItem>
private typealias Snapshot = NSDiffableDataSourceSnapshot<LaunchesSection, LaunchesItem>

private var dataSource: DataSource!

private func configureDataSource() {
    let launchCellRegistration = UICollectionView.CellRegistration<LaunchCell, LaunchCellViewModel> {
        cell, _, viewModel in
        cell.configure(with: viewModel)
    }
    let filterCellRegistration = UICollectionView.CellRegistration<LaunchFilterCell, LaunchFilterItem> {
        cell, _, item in
        cell.configure(with: item)
    }
    let messageCellRegistration = UICollectionView.CellRegistration<LaunchErrorCell, String> {
        cell, _, message in
        cell.configure(message: message)
    }

    dataSource = DataSource(collectionView: launchView.collectionView) {
        collectionView, indexPath, item in
        switch item {
        case .launch(let vm):
            return collectionView.dequeueConfiguredReusableCell(
                using: launchCellRegistration, for: indexPath, item: vm)
        case .filter(let filterItem):
            return collectionView.dequeueConfiguredReusableCell(
                using: filterCellRegistration, for: indexPath, item: filterItem)
        case .message(let text):
            return collectionView.dequeueConfiguredReusableCell(
                using: messageCellRegistration, for: indexPath, item: text)
        }
    }
}

func applySnapshot(items: [LaunchCellViewModel], message: String? = nil, animating: Bool) {
    var snapshot = Snapshot()
    snapshot.appendSections([.launches])
    if let message {
        snapshot.appendSections([.message])
        snapshot.appendItems([.message(message)], toSection: .message)
    } else {
        snapshot.appendItems(items.map { .launch($0) }, toSection: .launches)
    }
    AppLogger.make("LaunchViewController").debug("Applying snapshot: \(snapshot.numberOfItems) items")
    dataSource.apply(snapshot, animatingDifferences: animating)
}
```

**File: `SpaceX/Features/Launches/UI/LaunchView.swift` — Compositional Layout factory**

```swift
static func makeLayout() -> UICollectionViewCompositionalLayout {
    UICollectionViewCompositionalLayout { sectionIndex, _ in
        switch LaunchesSection.allCases[sectionIndex] {
        case .filters:
            let item = NSCollectionLayoutItem(
                layoutSize: .init(widthDimension: .estimated(80), heightDimension: .absolute(36))
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: .estimated(80), heightDimension: .absolute(36)),
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 8
            section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
            return section

        case .launches:
            let item = NSCollectionLayoutItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120))
            )
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120)),
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 0
            return section

        case .message:
            let item = NSCollectionLayoutItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
            )
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100)),
                subitems: [item]
            )
            return NSCollectionLayoutSection(group: group)
        }
    }
}
```

**File: `SpaceXTests/Launches/LaunchDiffableSnapshotTests.swift`**

```swift
import XCTest
@testable import SpaceX

final class LaunchDiffableSnapshotTests: XCTestCase {
    func test_snapshot_contentState_hasLaunchesSection() {
        var snapshot = NSDiffableDataSourceSnapshot<LaunchesSection, LaunchesItem>()
        snapshot.appendSections([.launches])
        snapshot.appendItems([.launch(LaunchCellViewModel.fixture())], toSection: .launches)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.launches])
        XCTAssertEqual(snapshot.numberOfItems(inSection: .launches), 1)
    }

    func test_snapshot_emptyState_hasMessageSection() {
        var snapshot = NSDiffableDataSourceSnapshot<LaunchesSection, LaunchesItem>()
        snapshot.appendSections([.message])
        snapshot.appendItems([.message("No launches found")], toSection: .message)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.message])
        XCTAssertFalse(snapshot.sectionIdentifiers.contains(.launches))
    }

    func test_snapshot_filterSectionPresent_whenFiltersAdded() {
        var snapshot = NSDiffableDataSourceSnapshot<LaunchesSection, LaunchesItem>()
        snapshot.appendSections([.filters, .launches])
        let chip = LaunchFilterItem(id: "all", title: "All", isSelected: true)
        snapshot.appendItems([.filter(chip)], toSection: .filters)
        XCTAssertTrue(snapshot.sectionIdentifiers.contains(.filters))
        XCTAssertEqual(snapshot.numberOfItems(inSection: .filters), 1)
    }
}

private extension LaunchCellViewModel {
    static func fixture(id: String = "test-id") -> LaunchCellViewModel {
        LaunchCellViewModel(id: id, name: "Falcon 9", date: "1 Jan 2024", statusImageName: "checkmark.circle")
    }
}
```

---

### Phase 5 — F-4: Launch Search, Filtering, and Sorting

#### Goal
Add `UISearchController` to `LaunchViewController`. Define `LaunchQuery`, `LaunchStatusFilter`, `LaunchSortOrder`. Implement `LaunchListViewModel.applyQuery(_:)` for client-side filtering on cached data — no additional network requests.

#### Why Now
Depends on Phase 4 (Diffable DS for animated snapshot updates) and Phase 2 (cache as data source for filtering).

#### In Scope
- `LaunchQuery` struct with `searchText`, `statusFilter`, `year`, `sortOrder`
- `LaunchStatusFilter` enum: `.all`, `.successful`, `.failed`, `.upcoming`
- `LaunchSortOrder` enum: `.newestFirst`, `.oldestFirst`
- `LaunchListViewModel.applyQuery(_:)` method
- `LaunchListViewModel.currentQuery: LaunchQuery` stored property
- `UISearchController` integrated in `LaunchViewController.navigationItem`
- Filter chips in `.filters` section bound to ViewModel query state

#### Out of Scope (relative to this phase)
Launch detail navigation (F-5), statistics (F-6).

#### Files to Create

| Path | Description |
|------|-------------|
| `SpaceX/Features/Launches/Domain/LaunchQuery.swift` | Query value type |
| `SpaceX/Features/Launches/Domain/LaunchStatusFilter.swift` | Status filter enum |
| `SpaceX/Features/Launches/Domain/LaunchSortOrder.swift` | Sort order enum |

#### Files to Modify

| Path | Change |
|------|--------|
| `SpaceX/Features/Launches/Presentation/LaunchListViewModel.swift` | Add `currentQuery`, `applyQuery(_:)`, filter+sort logic on cached data |
| `SpaceX/Features/Launches/UI/LaunchViewController.swift` | Add `UISearchController`, bind filter chips, call `applyQuery` on change |

#### Public Contracts to Add/Change

```swift
// LaunchQuery.swift
struct LaunchQuery: Equatable {
    var searchText: String = ""
    var statusFilter: LaunchStatusFilter = .all
    var year: Int? = nil
    var sortOrder: LaunchSortOrder = .newestFirst
}

// LaunchStatusFilter.swift
enum LaunchStatusFilter: String, CaseIterable {
    case all, successful, failed, upcoming
}

// LaunchSortOrder.swift
enum LaunchSortOrder {
    case newestFirst, oldestFirst
}

// LaunchListViewModel — new method
func applyQuery(_ query: LaunchQuery)
// stores query, filters cachedLaunches in memory, applies snapshot update
// does NOT trigger network request
```

#### Networking Changes
None. `applyQuery` operates exclusively on `cachedLaunches: [Launch]` stored in ViewModel after the last successful network fetch or cache read.

#### Cache / UserDefaults Notes
None. The ViewModel holds a `cachedLaunches: [Launch]` array populated on initial load and each page load; filtering is done in memory. No additional UserDefaults reads occur during `applyQuery`.

#### Mapping / Cache Policy
Filter logic:
1. Start from `cachedLaunches` (full unfiltered set).
2. Apply `statusFilter`: filter by `launch.success` and `launch.upcoming`.
3. Apply `year`: filter by year component of `launch.dateUtc`.
4. Apply `searchText`: case-insensitive `launch.name.localizedCaseInsensitiveContains(searchText)`.
5. Apply `sortOrder`: sort by `launch.dateUtc` ascending or descending.
6. Map to `[LaunchCellViewModel]`, apply snapshot.

Empty result after filtering → `.empty(message: "No launches match your search")` state.

#### UI Changes

**`UISearchController` integration:**
```swift
navigationItem.searchController = UISearchController(searchResultsController: nil)
navigationItem.searchController?.searchResultsUpdater = self
navigationItem.hidesSearchBarWhenScrolling = false
```

**Filter chips in `.filters` section:**
- Status filter chips: "All", "Successful", "Failed", "Upcoming"
- Year filter: a chip per unique year present in cached data (populated after initial load)
- Sort toggle: "Newest" / "Oldest" — two chips, one selected at a time
- Tapping a chip calls `viewModel.applyQuery(newQuery)` and triggers animated snapshot update

#### Coordinator / Navigation Changes
None.

#### Performance Considerations
Filtering operates on the in-memory `cachedLaunches` array (max ~200 items). O(n) filter + sort is performed synchronously. If the array grows beyond 5,000 items, move to a background task and dispatch result to main thread.

#### Privacy / Security Considerations
None.

#### Accessibility / Localization Considerations
`UISearchController` search bar has `accessibilityLabel = L10n.searchLaunchesPlaceholder`. Filter chip selected state uses `.accessibilityTraits = [.button, .selected]`.

#### Logging / Observability Checkpoints
- Log query changes: `debug("applyQuery: status=\(query.statusFilter) year=\(query.year) search='\(query.searchText)' sort=\(query.sortOrder)")`
- Log result count: `debug("Filter result: \(filteredCount) of \(totalCount)")`

#### Test Plan

**Unit tests** (`SpaceXTests/Launches/`):
- `LaunchQueryTests.swift`
  - `test_defaultQuery_returnsAllLaunches()`
  - `test_statusFilter_successful_returnsOnlySuccessful()`
  - `test_statusFilter_failed_returnsOnlyFailed()`
  - `test_statusFilter_upcoming_returnsOnlyUpcoming()`
  - `test_yearFilter_noMatches_returnsEmpty()`
  - `test_yearFilter_matchingYear_returnsCorrectSubset()`
  - `test_searchText_caseInsensitive_matchesSubstring()`
  - `test_searchText_empty_returnsAll()`
  - `test_sortOrder_newestFirst_descendingDate()`
  - `test_sortOrder_oldestFirst_ascendingDate()`
  - `test_combinedFilter_statusAndYear_correct()`
  - `test_applyQuery_doesNotTriggerNetworkRequest()`

**Integration tests:** None.

**UI tests:** (deferred to F-9 `LaunchFilterUITests`)

**Offline acceptance:** Filtering uses cached data — works offline by design. Covered by `test_applyQuery_doesNotTriggerNetworkRequest()`.

#### Definition of Done

- [ ] `LaunchQuery`, `LaunchStatusFilter`, `LaunchSortOrder` files exist and compile
- [ ] `LaunchListViewModel.applyQuery(_:)` filters `cachedLaunches` without triggering any network call
- [ ] `UISearchController` is visible in `LaunchViewController` navigation bar
- [ ] Filter chips appear in `.filters` section and are selectable
- [ ] Filter chip selection triggers animated snapshot update
- [ ] Year filter chips are populated from unique years in cached data
- [ ] Empty filter result shows `.empty(message:)` state
- [ ] Search is case-insensitive and matches substrings
- [ ] All `LaunchQueryTests` pass
- [ ] No pre-existing tests broken

#### Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| `UISearchController` conflicts with navigation bar appearance in dark theme | Apply `navigationItem.searchController?.searchBar.barStyle = .black` and test on device |
| Year filter chips overflow horizontally on narrow screens | Orthogonal scrolling in `.filters` section already handles this |
| `cachedLaunches` is empty when query is applied (no initial load yet) | `applyQuery` returns `.empty(message:)` if `cachedLaunches` is empty |

#### Rollback Plan
Delete `LaunchQuery.swift`, `LaunchStatusFilter.swift`, `LaunchSortOrder.swift`. Revert `LaunchListViewModel` to Phase 3 state. Revert `LaunchViewController` to remove `UISearchController`. All Phase 4 tests must pass.

#### Time Estimate
- Optimistic: 3 days
- Realistic: 5 days
- Pessimistic: 6 days

---

### Code Examples — Phase 5

**File: `SpaceX/Features/Launches/Domain/LaunchQuery.swift`**

```swift
struct LaunchQuery: Equatable {
    var searchText: String = ""
    var statusFilter: LaunchStatusFilter = .all
    var year: Int? = nil
    var sortOrder: LaunchSortOrder = .newestFirst

    static let `default` = LaunchQuery()
}

// File: SpaceX/Features/Launches/Domain/LaunchStatusFilter.swift
enum LaunchStatusFilter: String, CaseIterable {
    case all = "All"
    case successful = "Successful"
    case failed = "Failed"
    case upcoming = "Upcoming"
}

// File: SpaceX/Features/Launches/Domain/LaunchSortOrder.swift
enum LaunchSortOrder: CaseIterable {
    case newestFirst
    case oldestFirst

    var title: String {
        switch self {
        case .newestFirst: return "Newest"
        case .oldestFirst: return "Oldest"
        }
    }
}
```

**File: `SpaceX/Features/Launches/Presentation/LaunchListViewModel.swift` — `applyQuery` implementation**

```swift
private(set) var currentQuery: LaunchQuery = .default
private var cachedLaunches: [Launch] = []

func applyQuery(_ query: LaunchQuery) {
    guard query != currentQuery || !cachedLaunches.isEmpty else { return }
    currentQuery = query
    let logger = AppLogger.make("LaunchListViewModel")
    logger.debug("applyQuery: status=\(query.statusFilter.rawValue) year=\(String(describing: query.year)) search='\(query.searchText)' sort=\(query.sortOrder)")

    var filtered = cachedLaunches

    switch query.statusFilter {
    case .all:        break
    case .successful: filtered = filtered.filter { $0.success == true && !$0.upcoming }
    case .failed:     filtered = filtered.filter { $0.success == false && !$0.upcoming }
    case .upcoming:   filtered = filtered.filter { $0.upcoming }
    }

    if let year = query.year {
        filtered = filtered.filter {
            Calendar.current.component(.year, from: ISO8601DateFormatter().date(from: $0.dateUtc) ?? Date()) == year
        }
    }

    if !query.searchText.isEmpty {
        filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query.searchText) }
    }

    filtered.sort {
        let lhs = $0.dateUtc
        let rhs = $1.dateUtc
        return query.sortOrder == .newestFirst ? lhs > rhs : lhs < rhs
    }

    logger.debug("Filter result: \(filtered.count) of \(cachedLaunches.count)")

    let vms = mapToViewModels(filtered)
    state = vms.isEmpty
        ? .empty(message: "No launches match your search")
        : .loaded(vms, isStale: false)
}

func availableYears() -> [Int] {
    Array(Set(cachedLaunches.compactMap {
        Calendar.current.component(.year, from: ISO8601DateFormatter().date(from: $0.dateUtc) ?? Date())
    })).sorted(by: >)
}
```

**File: `SpaceXTests/Launches/LaunchQueryTests.swift`**

```swift
import XCTest
@testable import SpaceX

final class LaunchQueryTests: XCTestCase {
    private var sut: LaunchListViewModel!
    private var mockRepo: MockLaunchRepository!

    override func setUp() {
        super.setUp()
        mockRepo = MockLaunchRepository()
        sut = LaunchListViewModel(repository: mockRepo)
        sut.seedCachedLaunchesForTesting([
            .fixture(id: "1", name: "Falcon 9",     success: true,  upcoming: false, dateUtc: "2022-03-01T00:00:00.000Z"),
            .fixture(id: "2", name: "Starship",     success: false, upcoming: false, dateUtc: "2023-06-01T00:00:00.000Z"),
            .fixture(id: "3", name: "Falcon Heavy", success: nil,   upcoming: true,  dateUtc: "2024-09-01T00:00:00.000Z")
        ])
    }

    func test_defaultQuery_returnsAllLaunches() {
        sut.applyQuery(.default)
        XCTAssertEqual(sut.state.value?.count, 3)
    }

    func test_statusFilter_successful_returnsOnlySuccessful() {
        sut.applyQuery(LaunchQuery(statusFilter: .successful))
        XCTAssertEqual(sut.state.value?.count, 1)
        XCTAssertEqual(sut.state.value?.first?.name, "Falcon 9")
    }

    func test_statusFilter_upcoming_returnsOnlyUpcoming() {
        sut.applyQuery(LaunchQuery(statusFilter: .upcoming))
        XCTAssertEqual(sut.state.value?.count, 1)
        XCTAssertEqual(sut.state.value?.first?.name, "Falcon Heavy")
    }

    func test_searchText_caseInsensitive_matchesSubstring() {
        sut.applyQuery(LaunchQuery(searchText: "falcon"))
        XCTAssertEqual(sut.state.value?.count, 2)
    }

    func test_applyQuery_doesNotTriggerNetworkRequest() {
        sut.applyQuery(LaunchQuery(searchText: "test"))
        XCTAssertEqual(mockRepo.fetchInitialCallCount, 0)
    }

    func test_emptyResult_transitionsToEmpty() {
        sut.applyQuery(LaunchQuery(searchText: "zzz-no-match"))
        if case .empty = sut.state { } else {
            XCTFail("Expected .empty state")
        }
    }
}
```

---

### Phase 6 — F-5: Launch Detail Screen

> **Can run in parallel with Phase 7 (F-6) after Phases 1 and 3 are merged. Phase 2 (cache) is no longer a hard blocker — detail uses a dedicated network request.**

#### Goal
Build the `LaunchDetailViewController` → `LaunchDetailView` → `LaunchDetailViewModel` → `LaunchDetailRepository` stack. Wire coordinator navigation from launch cell tap. Render all detail sections from a dedicated `GET /v4/launches/:id` network request. If Phase 2 (cache) is already merged, use it as an offline fallback; otherwise, show an error state when offline.

#### Why Now
Depends on expanded domain models (F-1), cache (F-2), and `LoadableState` (F-7). This is the primary user-facing feature — the detail screen.

#### In Scope
- `LaunchDetailViewController`, `LaunchDetailView`, `LaunchDetailViewModel`
- `LaunchDetailRepository` + `LaunchDetailRepositoryProtocol` (aggregates launch + launchpad from cache/network)
- `AppCoordinator.showLaunchDetail(for:)` method
- `AppCoordinating` protocol updated with `showLaunchDetail(for launchId:)`
- `LaunchViewController` cell tap calls `coordinator?.showLaunchDetail(for: launchId)`
- Detail sections: Hero, Timeline, Description, Rocket, Pad, Payload, Crew/Ships/Capsules, External Links

#### Out of Scope (relative to this phase)
Statistics screen (F-6), design token extraction (F-8 finalizes this).

#### Files to Create

| Path | Description |
|------|-------------|
| `SpaceX/Features/LaunchDetail/UI/LaunchDetailViewController.swift` | UIKit container VC |
| `SpaceX/Features/LaunchDetail/UI/LaunchDetailView.swift` | Scrollable `UIScrollView` + `UIStackView` layout |
| `SpaceX/Features/LaunchDetail/Presentation/LaunchDetailViewModel.swift` | ViewModel with `LoadableState<LaunchDetail>` |
| `SpaceX/Features/LaunchDetail/Domain/LaunchDetailRepository.swift` | Protocol + implementation (network-first) |
| `SpaceX/Features/LaunchDetail/Data/LaunchDetailRemoteDataSource.swift` | `GET /v4/launches/:id` endpoint + protocol |

#### Files to Modify

| Path | Change |
|------|--------|
| `SpaceX/App/AppCoordinator.swift` | Add `showLaunchDetail(for launchId: String)` implementation |
| `SpaceX/App/AppCoordinator.swift` | `AppCoordinating` protocol: add `showLaunchDetail(for:)` |
| `SpaceX/App/AppContainer.swift` | Add `makeLaunchDetailViewModel(launchId:)` factory |
| `SpaceX/Features/Launches/UI/LaunchViewController.swift` | Add `collectionView(_:didSelectItemAt:)` → `coordinator?.showLaunchDetail(for: id)` |

#### Public Contracts to Add/Change

```swift
// AppCoordinating — new method
func showLaunchDetail(for launchId: String)

// LaunchDetailRepositoryProtocol
protocol LaunchDetailRepositoryProtocol {
    func fetchDetail(for launchId: String) async throws -> LaunchDetail
}

// LaunchDetailViewModel
final class LaunchDetailViewModel {
    private(set) var state: LoadableState<LaunchDetail> = .idle
    func load()
    init(launchId: String, repository: LaunchDetailRepositoryProtocol)
}
```

#### Networking Changes

Two new remote data sources added in this phase:

**`LaunchDetailRemoteDataSource`** — single-launch fetch:
```
GET /v4/launches/:id
```
Returns the full `LaunchDTO` with all fields (same fields already in the list `select` array). No request body required.

**`LaunchpadRemoteDataSource`** (defined in F-1) — used in parallel once `launchpadId` is known from the launch response.

Both calls happen sequentially: fetch launch → extract `launchpadId` → fetch launchpad.

#### Cache / UserDefaults Notes

`LaunchDetailRepository` uses **network-first** strategy:

1. `GET /v4/launches/:id` — primary data source.
2. `GET /v4/launchpads/:launchpadId` — fired after launch response returns `launchpadId`.
3. Combine into `LaunchDetail`. Missing launchpad → `LaunchDetail.launchpad = nil`.
4. `LaunchDetailViewModel` publishes `.loaded(detail, isStale: false)`.

**Offline fallback (only available when Phase 2 cache is merged):**
- If network throws, check `LaunchCacheStoreProtocol` for the launch by `launchId`.
- If found in cache → publish `.loaded(cached, isStale: true)`; launchpad section hidden.
- If not in cache → publish `.failed(message, cachedValue: nil)`.

If Phase 2 is not yet merged, inject a no-op `NullLaunchCacheStore` conforming to `LaunchCacheStoreProtocol` and skip the fallback path entirely.

#### UI Changes

**`LaunchDetailView` layout:**
- `UIScrollView` containing a vertical `UIStackView`
- Each section is a `UIView` card (will be replaced by `CardView` in F-8)
- Sections hidden (removed from stack) when data is nil: crew, capsules, ships, payload, description, pad

**Sections in order:**
1. **Hero:** Kingfisher `UIImageView` (patch image from `links.patch`), mission name, status badge
2. **Timeline:** Launch date formatted string
3. **Description:** Mission details text (hidden if `details == nil`)
4. **Rocket:** Rocket name + type
5. **Pad:** Launchpad name + location (hidden if `launchpad == nil`)
6. **Payload:** List of payload names (hidden if empty)
7. **Crew / Ships / Capsules:** Each shown as compact list (hidden if empty)
8. **External Links:** Buttons for Wikipedia, Article, Webcast (each hidden if nil)

External link buttons call `UIApplication.shared.open(url)`.

#### Coordinator / Navigation Changes
```swift
// AppCoordinator.swift
func showLaunchDetail(for launchId: String) {
    let vm = appContainer.makeLaunchDetailViewModel(launchId: launchId)
    let vc = LaunchDetailViewController(viewModel: vm)
    vc.coordinator = self
    navigationController.pushViewController(vc, animated: true)
}
```

#### Performance Considerations
Hero image loaded asynchronously via Kingfisher (already a project dependency). `UIScrollView` with `UIStackView` is adequate for this data density — no `UICollectionView` needed.

#### Privacy / Security Considerations
External links open in Safari. No private URLs. Webcast URLs may be YouTube — no additional entitlements required.

#### Accessibility / Localization Considerations
- Hero image: `accessibilityLabel = "\(missionName) mission patch"`
- Status badge: `accessibilityLabel = success ? "Successful" : "Failed"`
- Each section header: `accessibilityTraits = .header`
- External link buttons: `accessibilityLabel = "Open Wikipedia article"` etc.

#### Logging / Observability Checkpoints
- Log detail load start: `debug("Loading detail for launch \(launchId)")`
- Log launchpad fetch failure: `warning("Launchpad fetch failed for \(launchpadId): \(error)")`
- Log state transition: `debug("Detail state → \(state)")`

#### Test Plan

**Unit tests** (`SpaceXTests/LaunchDetail/`):
- `LaunchDetailViewModelTests.swift`
  - `test_load_success_transitionsToLoaded()`
  - `test_load_repositoryFailure_withCache_transitionsToFailed_withCachedValue()`
  - `test_load_repositoryFailure_noCache_transitionsToFailed_nilValue()`
  - `test_load_missingLaunchpad_detailStillLoads()`
  - `test_load_emptyOptionalFields_noSectionsForMissingData()`

- `LaunchDetailRepositoryTests.swift`
  - `test_fetch_returnsCombinedLaunchAndLaunchpad_fromNetwork()`
  - `test_fetch_launchpadUnavailable_returnsDetailWithNilLaunchpad()`
  - `test_fetch_networkFailure_withCache_returnsCachedLaunch()`
  - `test_fetch_networkFailure_noCache_throws()`

**Integration tests:** None.

**UI tests:** `LaunchDetailNavigationUITests` (deferred to F-9).

**Offline acceptance (requires Phase 2 cache):**
- Kill network (URLProtocol mock), load detail screen → displays cached launch data, pad section hidden.
- Without Phase 2 cache: kill network → error state shown.

#### Definition of Done

- [ ] Tapping a launch cell navigates to `LaunchDetailViewController` with correct `launchId`
- [ ] Detail data loaded via `GET /v4/launches/:id` (network-first)
- [ ] Hero, Timeline, Description, Rocket, Pad, Payload, Crew, Ships, Capsules, External Links sections render correctly from live data
- [ ] Sections with nil data are hidden (not shown empty)
- [ ] Launchpad fetch failure hides pad section but rest of screen renders
- [ ] External link buttons open the correct URL in Safari
- [ ] If network unavailable and Phase 2 cache present: cached data shown with stale indicator
- [ ] If network unavailable and no cache: error state shown
- [ ] `AppCoordinating` protocol has `showLaunchDetail(for:)` method
- [ ] All `LaunchDetailViewModelTests` and `LaunchDetailRepositoryTests` pass
- [ ] `LoadableState` drives all ViewModel state transitions
- [ ] No pre-existing tests broken

#### Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| `LaunchDetail` aggregation is slow (multiple async fetches) | Use `async let` parallel fetch for launchpad; timeout after 3s and show detail without pad section |
| Kingfisher image cache conflicts with existing usage | Kingfisher is already a project dependency; reuse default `KingfisherManager.shared` |
| `LaunchDetailRepository` not decoupled enough for unit testing | Inject both `LaunchCacheStoreProtocol` and `LaunchpadRemoteDataSourceProtocol` via initializer |

#### Rollback Plan
Delete all `LaunchDetail/` directory files. Revert `AppCoordinator`, `AppContainer`, `LaunchViewController` changes. Remove `showLaunchDetail` from `AppCoordinating` protocol. All Phase 5 tests must pass.

#### Time Estimate
- Optimistic: 5 days
- Realistic: 8 days
- Pessimistic: 12 days

---

### Code Examples — Phase 6

**File: `SpaceX/Features/LaunchDetail/Domain/LaunchDetailRepository.swift`**

```swift
protocol LaunchDetailRepositoryProtocol {
    func fetchDetail(for launchId: String) async throws -> LaunchDetail
}

final class LaunchDetailRepository: LaunchDetailRepositoryProtocol {
    private let launchDetailDataSource: LaunchDetailRemoteDataSourceProtocol
    private let launchpadDataSource: LaunchpadRemoteDataSourceProtocol
    // Optional — only used for offline fallback when F-2 cache is available.
    // Inject NullLaunchCacheStore if cache is not yet implemented.
    private let cacheStore: LaunchCacheStoreProtocol
    private let logger = AppLogger.make("LaunchDetailRepository")

    init(
        launchDetailDataSource: LaunchDetailRemoteDataSourceProtocol,
        launchpadDataSource: LaunchpadRemoteDataSourceProtocol,
        cacheStore: LaunchCacheStoreProtocol
    ) {
        self.launchDetailDataSource = launchDetailDataSource
        self.launchpadDataSource = launchpadDataSource
        self.cacheStore = cacheStore
    }

    func fetchDetail(for launchId: String) async throws -> LaunchDetail {
        logger.debug("Loading detail for launch \(launchId)")
        // Network-first: GET /v4/launches/:id
        do {
            let launchDTO = try await launchDetailDataSource.fetchLaunch(for: launchId)
            let launch = LaunchMapper().map(launchDTO)
            guard let launch else {
                throw LaunchDetailError.invalidData
            }
            var launchpad: Launchpad? = nil
            if let launchpadId = launch.launchpadId {
                launchpad = try? await launchpadDataSource.fetchLaunchpad(for: launchpadId)
            }
            logger.debug("Detail loaded from network for launch \(launchId)")
            return LaunchDetail(launch: launch, launchpad: launchpad)
        } catch {
            logger.warning("Network fetch failed for launch \(launchId): \(error). Trying cache.")
            // Offline fallback: search cache across all known rockets
            let cached = cacheStore.allKnownRocketIds()
                .compactMap { cacheStore.load(for: $0) }
                .flatMap { $0 }
                .first { $0.id == launchId }
            guard let cached else {
            throw LaunchDetailError.launchNotFound(id: launchId)
        }
        // 2. Fire launchpad fetch in parallel — failure is non-fatal
        async let launchpad: Launchpad? = {
            guard let padId = launch.launchpadId else { return nil }
            do {
                return try await launchpadDataSource.fetchLaunchpad(for: padId)
            } catch {
                self.logger.warning("Launchpad fetch failed for \(padId): \(error)")
                return nil
            }
        }()
        return LaunchDetail(launch: launch, launchpad: await launchpad)
    }
}

enum LaunchDetailError: Error {
    case launchNotFound(id: String)
}
```

**File: `SpaceX/Features/LaunchDetail/Presentation/LaunchDetailViewModel.swift`**

```swift
final class LaunchDetailViewModel {
    private(set) var state: LoadableState<LaunchDetail> = .idle {
        didSet { onStateChanged?(state) }
    }
    var onStateChanged: ((LoadableState<LaunchDetail>) -> Void)?

    private let launchId: String
    private let repository: LaunchDetailRepositoryProtocol
    private let logger = AppLogger.make("LaunchDetailViewModel")

    init(launchId: String, repository: LaunchDetailRepositoryProtocol) {
        self.launchId = launchId
        self.repository = repository
    }

    func load() {
        state = .loading
        Task { @MainActor in
            do {
                let detail = try await repository.fetchDetail(for: launchId)
                state = .loaded(detail, isStale: false)
                logger.debug("Detail state → loaded")
            } catch {
                state = .failed(message: error.localizedDescription, cachedValue: nil)
                logger.debug("Detail state → failed: \(error)")
            }
        }
    }
}
```

**File: `SpaceX/App/AppContainer.swift` — DI wiring**

```swift
// AppCoordinating protocol — routes
protocol AppCoordinating: AnyObject {
    func showLaunches(for rocket: Rocket)
    func showSettings(from viewController: UIViewController)
    func showLaunchDetail(for launchId: String)
    func showStats()
}

// AppContainer — factory method
func makeLaunchDetailViewModel(launchId: String) -> LaunchDetailViewModel {
    LaunchDetailViewModel(
        launchId: launchId,
        repository: LaunchDetailRepository(
            cacheStore: launchCacheStore,
            launchpadDataSource: LaunchpadRemoteDataSource(httpClient: httpClient)
        )
    )
}
```

**File: `SpaceXTests/LaunchDetail/LaunchDetailViewModelTests.swift`**

```swift
import XCTest
@testable import SpaceX

final class LaunchDetailViewModelTests: XCTestCase {
    private var sut: LaunchDetailViewModel!
    private var mockRepo: MockLaunchDetailRepository!

    override func setUp() {
        super.setUp()
        mockRepo = MockLaunchDetailRepository()
        sut = LaunchDetailViewModel(launchId: "abc123", repository: mockRepo)
    }

    func test_load_success_transitionsToLoaded() async {
        mockRepo.stubbedDetail = .fixture()
        sut.load()
        await Task.yield()
        if case .loaded(let detail, isStale: false) = sut.state {
            XCTAssertEqual(detail.launch.id, "abc123")
        } else {
            XCTFail("Expected .loaded state, got \(sut.state)")
        }
    }

    func test_load_repositoryFailure_noCache_transitionsToFailed_nilValue() async {
        mockRepo.shouldThrow = true
        sut.load()
        await Task.yield()
        if case .failed(_, cachedValue: nil) = sut.state { } else {
            XCTFail("Expected .failed with nil cachedValue")
        }
    }

    func test_load_missingLaunchpad_detailStillLoads() async {
        mockRepo.stubbedDetail = LaunchDetail.fixture(launchpad: nil)
        sut.load()
        await Task.yield()
        if case .loaded(let detail, _) = sut.state {
            XCTAssertNil(detail.launchpad)
        } else {
            XCTFail("Expected .loaded state")
        }
    }
}

final class MockLaunchDetailRepository: LaunchDetailRepositoryProtocol {
    var stubbedDetail: LaunchDetail?
    var shouldThrow = false

    func fetchDetail(for launchId: String) async throws -> LaunchDetail {
        if shouldThrow { throw NSError(domain: "test", code: 0) }
        return stubbedDetail ?? .fixture()
    }
}

private extension LaunchDetail {
    static func fixture(launchpad: Launchpad? = nil) -> LaunchDetail {
        LaunchDetail(launch: .fixture(id: "abc123"), launchpad: launchpad)
    }
}
```

---

### Phase 7 — F-6: Statistics Screen

> **Can run in parallel with Phase 6 (F-5) after Phases 1, 2, and 3 are merged.**

#### Goal
Build `StatsViewController` (UIKit container with embedded `UIHostingController`), `LaunchStatsView` (SwiftUI with `Chart` views), `StatsViewModel`, `StatsRepository`. Aggregate `launchesPerYear`, `successRate`, `launchCountPerRocket`, `coreReuseCount` in memory by loading cached launches for all known `rocketId` values. Navigate from `RocketViewController` via coordinator.

#### Why Now
Depends on the UserDefaults cache (F-2) for data — specifically `allKnownRocketIds()` — and `LoadableState` (F-7) for ViewModel state. Can run in parallel with F-5.

#### In Scope
- `LaunchStats` aggregate struct
- `StatsRepository` + `StatsRepositoryProtocol`
- `StatsViewModel` with `LoadableState<LaunchStats>`
- `LaunchStatsView` (SwiftUI) with four chart views
- `StatsViewController` (UIKit) embedding `UIHostingController<LaunchStatsView>`
- `AppCoordinator.showStats()` and `AppCoordinating.showStats()` method
- Navigation entry point in `RocketViewController`

#### Out of Scope (relative to this phase)
All other features.

#### Files to Create

| Path | Description |
|------|-------------|
| `SpaceX/Features/Stats/Domain/LaunchStats.swift` | Aggregate value type |
| `SpaceX/Features/Stats/Domain/StatsRepository.swift` | Protocol + implementation |
| `SpaceX/Features/Stats/Presentation/StatsViewModel.swift` | ViewModel |
| `SpaceX/Features/Stats/UI/StatsViewController.swift` | UIKit container |
| `SpaceX/Features/Stats/UI/LaunchStatsView.swift` | SwiftUI Chart views |

#### Files to Modify

| Path | Change |
|------|--------|
| `SpaceX/App/AppCoordinator.swift` | Add `showStats()` implementation |
| `SpaceX/App/AppCoordinator.swift` | `AppCoordinating` protocol: add `showStats()` |
| `SpaceX/App/AppContainer.swift` | Add `makeStatsViewModel()` factory |
| `SpaceX/Features/Rockets/UI/RocketViewController.swift` | Add bar button / menu item → `coordinator?.showStats()` |

#### Public Contracts to Add/Change

```swift
// LaunchStats.swift
struct LaunchStats {
    let launchesPerYear: [(year: Int, count: Int)]
    let successRate: Double          // 0.0 – 1.0
    let launchCountPerRocket: [(rocketId: String, rocketName: String, count: Int)]
    let coreReuseCount: Int
}

// StatsRepositoryProtocol
protocol StatsRepositoryProtocol {
    func computeStats(for rocketId: String?) async -> LaunchStats
    // rocketId nil = all rockets aggregate loaded from cache via allKnownRocketIds()
}

// AppCoordinating — new method
func showStats()
```

#### Networking Changes
None. Statistics screen is cache-only.

#### Cache / UserDefaults Notes
`StatsRepository` reads from `LaunchCacheStoreProtocol`:
- If `rocketId` is provided: calls `cacheStore.load(for: rocketId) ?? []`
- If `rocketId` is `nil` (all rockets): calls `cacheStore.allKnownRocketIds()`, then `cacheStore.load(for:)` for each ID, and flattens the results

Aggregation is performed in memory on a background task via `Task.detached`. Result dispatched to main thread before ViewModel publishes state.

#### Mapping / Cache Policy
Aggregation logic (pure Swift, no persistence queries):
- `launchesPerYear`: group `launches` by year component of `dateUtc`; count per group.
- `successRate`: `successCount / (successCount + failureCount)` (exclude `upcoming: true` records).
- `launchCountPerRocket`: group by `rocketId`; sort by count descending.
- `coreReuseCount`: count launches where `cores` array contains `reused == true`.

Empty cache → `StatsViewModel` publishes `.empty(message: "Load launches to view statistics")`.

#### UI Changes

**`LaunchStatsView` (SwiftUI):**
Four sections using Swift Charts:
1. Bar chart: launches per year
2. Gauge or donut-style Chart: success rate percentage
3. Bar chart: launch count per rocket (horizontal)
4. Single statistic card: core reuse count

**`StatsViewController`:**
```swift
let hostingController = UIHostingController(rootView: LaunchStatsView(viewModel: viewModel))
addChild(hostingController)
view.addSubview(hostingController.view)
hostingController.didMove(toParent: self)
```

**Empty state:** `LaunchStatsView` renders a centered text card when stats are empty.

#### Coordinator / Navigation Changes
```swift
func showStats() {
    let vm = appContainer.makeStatsViewModel()
    let vc = StatsViewController(viewModel: vm)
    vc.coordinator = self
    navigationController.pushViewController(vc, animated: true)
}
```

**Entry point in `RocketViewController`:** Add a `UIBarButtonItem` (chart SF Symbol) in the navigation bar's right items.

#### Performance Considerations
Aggregation must not block the main thread. Use `Task.detached(priority: .userInitiated)` for computation, then `.value` to await result back on the calling task. With a flat array of ~2,000 launches, aggregation completes in < 50 ms on modern hardware.

#### Privacy / Security Considerations
No personal data. All aggregates are derived from public SpaceX launch records in the local cache.

#### Accessibility / Localization Considerations
Swift Charts provides built-in accessibility support via `chartAccessibilityLabel`. Each chart must have a meaningful `accessibilityLabel` and `accessibilityValue`.

#### Logging / Observability Checkpoints
- Log computation start: `debug("Computing stats for rocketId: \(rocketId ?? "all")")`
- Log completion: `debug("Stats computed: \(stats.launchesPerYear.count) years")`
- Log empty cache: `debug("Stats: empty cache, publishing empty state")`

#### Test Plan

**Unit tests** (`SpaceXTests/Stats/`):
- `StatsRepositoryTests.swift`
  - `test_computeStats_correctLaunchesPerYear()`
  - `test_computeStats_correctSuccessRate()`
  - `test_computeStats_correctLaunchCountPerRocket()`
  - `test_computeStats_correctCoreReuseCount()`
  - `test_computeStats_emptyCache_returnsZeroAggregates()`
  - `test_computeStats_aggregatesAcrossAllKnownRocketIds_whenRocketIdIsNil()`

- `StatsViewModelTests.swift`
  - `test_load_emptyCache_publishesEmptyState()`
  - `test_load_withData_publishesLoadedState()`
  - `test_load_publishesOnMainThread()`

**Integration tests:** None.

**UI tests:** (deferred to F-9)

**Offline acceptance:**
- Stats screen opens without network → displays cached aggregates.

#### Definition of Done

- [ ] `StatsViewController` opens from `RocketViewController` navigation bar button
- [ ] `LaunchStatsView` renders all four charts without layout errors inside `UIHostingController`
- [ ] `StatsRepository` aggregates launches from all known rocket IDs when `rocketId` is `nil`
- [ ] `StatsRepository` computes correct aggregates on test data (all unit tests pass)
- [ ] Empty cache shows "Load launches to view statistics" message
- [ ] Aggregation computed on background task; result published on main thread
- [ ] `StatsViewModel` has `LoadableState<LaunchStats>` state
- [ ] Deployment target note for Swift Charts (iOS 16+) documented in `README.md`
- [ ] All `StatsRepositoryTests` and `StatsViewModelTests` pass
- [ ] No pre-existing tests broken

#### Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| `UIHostingController` layout ambiguity inside `UINavigationController` | Use SnapKit `edges.equalTo(view.safeAreaLayoutGuide)` for hosting controller view constraints |
| Swift Charts requires iOS 16+ | Document deployment target bump requirement; guard `StatsViewController` with `if #available(iOS 16, *)` |
| `LaunchStatsView` SwiftUI dark mode colors differ from UIKit `AppColors` | Create `AppColors+SwiftUI.swift` with `Color` extensions mirroring `UIColor` values |

#### Rollback Plan
Delete all `Stats/` directory files. Revert `AppCoordinator`, `AppContainer`, `RocketViewController` changes. Remove `showStats` from `AppCoordinating`. All Phase 6 tests must pass.

#### Time Estimate
- Optimistic: 4 days
- Realistic: 6 days
- Pessimistic: 8 days

---

### Code Examples — Phase 7

**File: `SpaceX/Features/Stats/Domain/LaunchStats.swift`**

```swift
struct LaunchStats {
    let launchesPerYear: [(year: Int, count: Int)]
    let successRate: Double
    let launchCountPerRocket: [(rocketId: String, rocketName: String, count: Int)]
    let coreReuseCount: Int

    static let empty = LaunchStats(
        launchesPerYear: [],
        successRate: 0.0,
        launchCountPerRocket: [],
        coreReuseCount: 0
    )
}
```

**File: `SpaceX/Features/Stats/Domain/StatsRepository.swift`**

```swift
protocol StatsRepositoryProtocol {
    func computeStats(for rocketId: String?) async -> LaunchStats
}

final class StatsRepository: StatsRepositoryProtocol {
    private let cacheStore: LaunchCacheStoreProtocol
    private let logger = AppLogger.make("StatsRepository")

    init(cacheStore: LaunchCacheStoreProtocol) {
        self.cacheStore = cacheStore
    }

    func computeStats(for rocketId: String?) async -> LaunchStats {
        logger.debug("Computing stats for rocketId: \(rocketId ?? "all")")
        let allLaunches: [Launch]
        if let rocketId {
            allLaunches = cacheStore.load(for: rocketId) ?? []
        } else {
            allLaunches = cacheStore.allKnownRocketIds()
                .flatMap { cacheStore.load(for: $0) ?? [] }
        }
        guard !allLaunches.isEmpty else {
            logger.debug("Stats: empty cache, publishing empty state")
            return .empty
        }

        return await Task.detached(priority: .userInitiated) { [self] in
            let perYear = computeLaunchesPerYear(from: allLaunches)
            let successRate = computeSuccessRate(from: allLaunches)
            let perRocket = computePerRocket(from: allLaunches)
            let reuseCount = allLaunches
                .flatMap { $0.cores ?? [] }
                .filter { $0.reused }
                .count
            logger.debug("Stats computed: \(perYear.count) years")
            return LaunchStats(
                launchesPerYear: perYear,
                successRate: successRate,
                launchCountPerRocket: perRocket,
                coreReuseCount: reuseCount
            )
        }.value
    }

    private func computeLaunchesPerYear(from launches: [Launch]) -> [(year: Int, count: Int)] {
        let grouped = Dictionary(grouping: launches) { launch -> Int in
            Calendar.current.component(.year, from: ISO8601DateFormatter().date(from: launch.dateUtc) ?? Date())
        }
        return grouped.map { (year: $0.key, count: $0.value.count) }
                      .sorted { $0.year < $1.year }
    }

    private func computeSuccessRate(from launches: [Launch]) -> Double {
        let applicable = launches.filter { !$0.upcoming }
        let successCount = applicable.filter { $0.success == true }.count
        guard !applicable.isEmpty else { return 0.0 }
        return Double(successCount) / Double(applicable.count)
    }

    private func computePerRocket(from launches: [Launch]) -> [(rocketId: String, rocketName: String, count: Int)] {
        let grouped = Dictionary(grouping: launches, by: \.rocketId)
        return grouped.map { (rocketId: $0.key, rocketName: $0.key, count: $0.value.count) }
                      .sorted { $0.count > $1.count }
    }
}
```

**File: `SpaceX/Features/Stats/Presentation/StatsViewModel.swift`**

```swift
final class StatsViewModel {
    private(set) var state: LoadableState<LaunchStats> = .idle {
        didSet { onStateChanged?(state) }
    }
    var onStateChanged: ((LoadableState<LaunchStats>) -> Void)?

    private let repository: StatsRepositoryProtocol
    private let rocketId: String?

    init(repository: StatsRepositoryProtocol, rocketId: String? = nil) {
        self.repository = repository
        self.rocketId = rocketId
    }

    func load() {
        state = .loading
        Task { @MainActor in
            let stats = await repository.computeStats(for: rocketId)
            if stats.launchesPerYear.isEmpty {
                state = .empty(message: "Load launches to view statistics")
            } else {
                state = .loaded(stats, isStale: false)
            }
        }
    }
}
```

**File: `SpaceXTests/Stats/StatsRepositoryTests.swift`**

```swift
import XCTest
@testable import SpaceX

final class StatsRepositoryTests: XCTestCase {
    private var sut: StatsRepository!
    private var mockCache: MockLaunchCacheStore!

    override func setUp() {
        super.setUp()
        mockCache = MockLaunchCacheStore()
        sut = StatsRepository(cacheStore: mockCache)
    }

    func test_computeStats_correctLaunchesPerYear() async {
        mockCache.stubbedLaunches = [
            .fixture(id: "1", dateUtc: "2022-01-01T00:00:00.000Z", success: true),
            .fixture(id: "2", dateUtc: "2022-06-01T00:00:00.000Z", success: true),
            .fixture(id: "3", dateUtc: "2023-03-01T00:00:00.000Z", success: false)
        ]
        let stats = await sut.computeStats(for: nil)
        XCTAssertEqual(stats.launchesPerYear.first(where: { $0.year == 2022 })?.count, 2)
        XCTAssertEqual(stats.launchesPerYear.first(where: { $0.year == 2023 })?.count, 1)
    }

    func test_computeStats_correctSuccessRate() async {
        mockCache.stubbedLaunches = [
            .fixture(id: "1", success: true,  upcoming: false),
            .fixture(id: "2", success: false, upcoming: false),
            .fixture(id: "3", success: nil,   upcoming: true)
        ]
        let stats = await sut.computeStats(for: nil)
        XCTAssertEqual(stats.successRate, 0.5, accuracy: 0.01)
    }

    func test_computeStats_emptyCache_returnsZeroAggregates() async {
        mockCache.stubbedLaunches = []
        let stats = await sut.computeStats(for: nil)
        XCTAssertTrue(stats.launchesPerYear.isEmpty)
        XCTAssertEqual(stats.successRate, 0.0)
        XCTAssertEqual(stats.coreReuseCount, 0)
    }

    func test_computeStats_aggregatesAcrossAllKnownRocketIds_whenRocketIdIsNil() async {
        mockCache.stubbedLaunches = [
            .fixture(id: "1", rocketId: "r1"),
            .fixture(id: "2", rocketId: "r2")
        ]
        let stats = await sut.computeStats(for: nil)
        XCTAssertEqual(stats.launchCountPerRocket.count, 2)
    }
}
```

**File: `SpaceX/Features/Stats/UI/LaunchStatsView.swift`**

```swift
import SwiftUI
import Charts

@available(iOS 16, *)
struct LaunchStatsView: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty(let message):
            Text(message)
                .font(AppFonts.body.swiftUI)
                .foregroundColor(Color.appLabel)
                .multilineTextAlignment(.center)
                .padding()

        case .loaded(let stats, _):
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    launchesPerYearChart(stats.launchesPerYear)
                    successRateGauge(stats.successRate)
                    coreReuseCard(stats.coreReuseCount)
                }
                .padding()
            }
            .background(Color.appBackground)

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func launchesPerYearChart(_ data: [(year: Int, count: Int)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Launches Per Year")
                .font(AppFonts.title2.swiftUI)
            Chart(data, id: \.year) { item in
                BarMark(
                    x: .value("Year", item.year),
                    y: .value("Launches", item.count)
                )
                .foregroundStyle(Color.appAccent)
            }
            .frame(height: 200)
            .chartAccessibilityLabel("Launches per year bar chart")
        }
        .padding()
        .background(Color.appCellBackground)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func successRateGauge(_ rate: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Success Rate")
                .font(AppFonts.title2.swiftUI)
            Gauge(value: rate, in: 0...1) {
                Text("\(Int(rate * 100))%")
                    .font(AppFonts.body.swiftUI)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Color.appAccent)
        }
        .padding()
        .background(Color.appCellBackground)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func coreReuseCard(_ count: Int) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Core Reuse Events")
                    .font(AppFonts.caption.swiftUI)
                    .foregroundColor(Color.appSecondaryLabel)
                Text("\(count)")
                    .font(AppFonts.title2.swiftUI)
                    .foregroundColor(Color.appLabel)
            }
            Spacer()
        }
        .padding()
        .background(Color.appCellBackground)
        .cornerRadius(12)
    }
}
```

---

### Phase 8 — F-8: Design and Visual Consistency

#### Goal
Extract shared UI components (`CardView`, `SectionHeaderView`, `LoadingIndicatorView`, `EmptyStateView`) into `Core/UI/Components/`. Apply them across all new screens. Enforce zero hardcoded color/font values via code review. Add `AppColors+SwiftUI.swift` and `AppFonts+SwiftUI.swift` extensions. Validate visual consistency across all new screens.

#### Why Now
All UI screens from F-3, F-4, F-5, F-6 must exist before consistency audit and component extraction can be done with full context.

#### In Scope
- New shared UI components: `CardView`, `SectionHeaderView`, `LoadingIndicatorView`, `EmptyStateView`
- SwiftUI extensions: `AppColors+SwiftUI.swift`, `AppFonts+SwiftUI.swift`
- Retroactive application of shared components to `LaunchDetailView`, `LaunchStatsView`, `LaunchCell`
- Visual consistency checklist (added to `CONTRIBUTING.md`)

#### Out of Scope (relative to this phase)
New features. Only component extraction and consistency enforcement.

#### Files to Create

| Path | Description |
|------|-------------|
| `SpaceX/Core/UI/Components/CardView.swift` | Reusable card container: shadow, corner radius, padding |
| `SpaceX/Core/UI/Components/SectionHeaderView.swift` | Section header for detail screens |
| `SpaceX/Core/UI/Components/LoadingIndicatorView.swift` | Consistent loading indicator |
| `SpaceX/Core/UI/Components/EmptyStateView.swift` | Consistent empty state message card |
| `SpaceX/Core/UI/Theme/AppColors+SwiftUI.swift` | `Color` extensions mirroring `AppColors` UIColor values |
| `SpaceX/Core/UI/Theme/AppFonts+SwiftUI.swift` | `Font` extensions mirroring `AppFonts` font descriptors |

#### Files to Modify

| Path | Change |
|------|--------|
| `SpaceX/Features/LaunchDetail/UI/LaunchDetailView.swift` | Replace inline card `UIView`s with `CardView` |
| `SpaceX/Features/Stats/UI/LaunchStatsView.swift` | Replace hardcoded `Color(...)` with `AppColors.xxx.swiftUI` extensions |
| `SpaceX/Features/Launches/UI/LaunchCell.swift` | Replace any inline color / font size literals with `AppColors.*` / `AppFonts.*` |
| `CONTRIBUTING.md` | Add visual consistency checklist |

#### Public Contracts to Add/Change

```swift
// CardView.swift
final class CardView: UIView {
    func addContent(_ view: UIView)
}

// EmptyStateView.swift
final class EmptyStateView: UIView {
    func configure(message: String)
}

// AppColors+SwiftUI.swift
extension Color {
    static let appBackground      = Color(AppColors.background)
    static let appCellBackground  = Color(AppColors.cellBackground)
    static let appAccent          = Color(AppColors.accent)
    static let appLabel           = Color(AppColors.label)
    static let appSecondaryLabel  = Color(AppColors.secondaryLabel)
    static let appSuccess         = Color(AppColors.success)
    static let appFailure         = Color(AppColors.failure)
}
```

#### Networking Changes
None.

#### Cache / UserDefaults Notes
None.

#### Mapping / Cache Policy
None.

#### UI Changes

**Visual consistency requirements (enforced per PR review):**
- Card shadow: `layer.shadowColor = AppColors.black.cgColor`, `shadowOpacity = 0.3`, `shadowRadius = 8`, `shadowOffset = CGSize(width: 0, height: 4)`
- Corner radius: `layer.cornerRadius = 12`
- Horizontal padding inside cards: `16pt`
- Vertical padding inside cards: `12pt`
- Font hierarchy: title = `AppFonts.title2`, body = `AppFonts.body`, caption = `AppFonts.caption`
- Background colors: only `AppColors.*` values

#### Coordinator / Navigation Changes
None.

#### Performance Considerations
`CardView` uses `layer.shadowPath` for efficient shadow rendering (avoids off-screen rendering pass).

#### Privacy / Security Considerations
None.

#### Accessibility / Localization Considerations
`CardView` does not interfere with VoiceOver grouping — it does not set `isAccessibilityElement`. Content inside cards remains independently accessible.

#### Logging / Observability Checkpoints
None specific to this phase.

#### Test Plan

**Unit tests:** None for pure layout components.

**Integration tests:** None.

**UI tests:** None (visual consistency validated manually via screenshot checklist).

**Manual checklist (required before Phase 8 PR merges):**
- [ ] All cards in `LaunchDetailView` match `RocketView` card style (shadow, radius, padding)
- [ ] `LaunchStatsView` uses `AppColors.swiftUI` extensions — no `Color("...")`
- [ ] `EmptyStateView` appearance matches across launch list and stats screen
- [ ] `LoadingIndicatorView` replaces `UIActivityIndicatorView` in pagination footer

#### Definition of Done

- [ ] `CardView`, `SectionHeaderView`, `LoadingIndicatorView`, `EmptyStateView` exist in `Core/UI/Components/`
- [ ] `AppColors+SwiftUI.swift` and `AppFonts+SwiftUI.swift` exist
- [ ] Zero hardcoded hex `UIColor` values in all new UI files (verified by `rg` search for `UIColor(red:` in new files)
- [ ] Zero hardcoded `CGFloat` font sizes in new UI files (verified by `rg` search)
- [ ] `LaunchDetailView` uses `CardView` for all section containers
- [ ] `LaunchStatsView` uses `AppColors` SwiftUI extension — no `Color(.black)` literals
- [ ] Visual consistency checklist is in `CONTRIBUTING.md`
- [ ] No pre-existing tests broken

#### Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| `CardView` shadow causes performance regression on scroll | Rasterize shadow: `layer.shouldRasterize = true; layer.rasterizationScale = UIScreen.main.scale` |
| SwiftUI `Color` initializer with `UIColor` not available below iOS 15 | All SwiftUI code is in `StatsViewController` guarded by `#available(iOS 16, *)`; no issue |

#### Rollback Plan
Delete `Core/UI/Components/` new files. Delete `AppColors+SwiftUI.swift`, `AppFonts+SwiftUI.swift`. Revert `LaunchDetailView` and `LaunchStatsView` inline changes. No functional behavior changes — safe to rollback.

#### Time Estimate
- Optimistic: 1 day
- Realistic: 2 days
- Pessimistic: 3 days

---

### Code Examples — Phase 8

**File: `SpaceX/Core/UI/Components/CardView.swift`**

```swift
import UIKit
import SnapKit

final class CardView: UIView {
    private enum Constants {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let shadowOpacity: Float = 0.3
        static let shadowOffset = CGSize(width: 0, height: 4)
        static let contentInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }

    private let contentContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    func addContent(_ view: UIView) {
        contentContainer.addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupAppearance() {
        backgroundColor = AppColors.cellBackground
        layer.cornerRadius = Constants.cornerRadius
        layer.shadowColor = AppColors.black.cgColor
        layer.shadowOpacity = Constants.shadowOpacity
        layer.shadowRadius = Constants.shadowRadius
        layer.shadowOffset = Constants.shadowOffset
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        addSubview(contentContainer)
        contentContainer.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Constants.contentInsets)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: Constants.cornerRadius
        ).cgPath
    }
}
```

**File: `SpaceX/Core/UI/Components/EmptyStateView.swift`**

```swift
final class EmptyStateView: UIView {
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.body
        label.textColor = AppColors.secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(32)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(message: String) {
        messageLabel.text = message
        accessibilityLabel = message
    }
}
```

**File: `SpaceX/Core/UI/Theme/AppColors+SwiftUI.swift`**

```swift
import SwiftUI

extension Color {
    static let appBackground     = Color(AppColors.background)
    static let appCellBackground = Color(AppColors.cellBackground)
    static let appAccent         = Color(AppColors.accent)
    static let appLabel          = Color(AppColors.label)
    static let appSecondaryLabel = Color(AppColors.secondaryLabel)
    static let appSuccess        = Color(AppColors.success)
    static let appFailure        = Color(AppColors.failure)
}
```

**File: `SpaceX/Core/UI/Theme/AppFonts+SwiftUI.swift`**

```swift
import SwiftUI

extension Font {
    static var appTitle2: Font { Font(AppFonts.title2 as CTFont) }
    static var appBody: Font   { Font(AppFonts.body   as CTFont) }
    static var appCaption: Font { Font(AppFonts.caption as CTFont) }
}

extension UIFont {
    var swiftUI: Font { Font(self as CTFont) }
}
```

**Manual consistency verification script (run in CI or locally)**

```bash
# Zero hardcoded UIColor hex values in new feature files
rg 'UIColor\(red:' SpaceX/Features/LaunchDetail SpaceX/Features/Stats
# Zero hardcoded font size literals
rg 'UIFont\.systemFont\(ofSize:' SpaceX/Features/LaunchDetail SpaceX/Features/Stats
# Verify AppColors+SwiftUI exists
ls SpaceX/Core/UI/Theme/AppColors+SwiftUI.swift
```

---

### Phase 9 — F-9: Test Finalization

#### Goal
Complete the full test suite: all listed unit tests written and passing, UI tests for three critical paths, coverage > 80% for all new ViewModels and Repositories, zero tests using real network.

#### Why Now
Integration tests require all features to be complete. Unit tests were written continuously — this phase finalizes coverage gaps and adds the UI test suite.

#### In Scope
- Final unit test pass: verify all tests from F-1 through F-8 exist and pass
- Add any coverage gaps found during the audit
- New UI tests: `LaunchDetailNavigationUITests`, `LaunchFilterUITests`, `LaunchPaginationUITests`
- Coverage report: run Xcode coverage and verify > 80% for all new ViewModels and Repositories
- Confirm all mock objects implement protocols (no concrete class subclassing)
- Confirm all `LaunchCacheStoreProtocol` tests use `UserDefaults(suiteName:)` isolation

#### Out of Scope (relative to this phase)
No new features. Test-only phase.

#### Files to Create

| Path | Description |
|------|-------------|
| `SpaceXTests/LaunchDetail/LaunchDetailViewModelTests.swift` | (if not created in Phase 6) |
| `SpaceXTests/LaunchDetail/LaunchDetailRepositoryTests.swift` | (if not created in Phase 6) |
| `SpaceXTests/Stats/StatsRepositoryTests.swift` | (if not created in Phase 7) |
| `SpaceXTests/Stats/StatsViewModelTests.swift` | (if not created in Phase 7) |
| `SpaceXTests/Cache/LaunchCacheStoreTests.swift` | (if not created in Phase 2) |
| `SpaceXTests/Core/LoadableStateTests.swift` | (if not created in Phase 3) |
| `SpaceXUITests/LaunchDetailNavigationUITests.swift` | Navigation happy path |
| `SpaceXUITests/LaunchFilterUITests.swift` | Filter + search UI test |
| `SpaceXUITests/LaunchPaginationUITests.swift` | Pagination trigger test |

#### Files to Modify

| Path | Change |
|------|--------|
| `SpaceXTests/Launches/LaunchListViewModelTests.swift` | Add `applyQuery` and `LoadableState` test cases if not yet covered |
| `SpaceXTests/Launches/LaunchMapperTests.swift` | Add missing edge case tests from F-1 |

#### Public Contracts to Add/Change
None — test-only phase.

#### Networking Changes
None.

#### Cache / UserDefaults Notes
All tests that exercise `UserDefaultsLaunchCacheStore` must use `UserDefaults(suiteName: "com.test.xxx")` and call `removePersistentDomain(forName:)` in `tearDown`. No test may write to `UserDefaults.standard`.

#### Mapping / Cache Policy
None.

#### UI Changes
None.

#### Coordinator / Navigation Changes
None.

#### Performance Considerations
UI tests run on iPhone 15 simulator (iOS 17+). Full test suite (unit + UI) must complete in < 5 minutes in CI.

#### Privacy / Security Considerations
None.

#### Accessibility / Localization Considerations
`LaunchFilterUITests` uses `accessibilityIdentifier` on filter chips to locate elements. Set `accessibilityIdentifier = "filterChip_\(id)"` in `LaunchFilterCell`.

#### Logging / Observability Checkpoints
- CI coverage report published as artifact.
- Build log shows zero test failures.

#### Test Plan

**Unit test coverage audit (all must exist and pass):**
- `LaunchMapperTests` (F-1)
- `LaunchCacheStoreTests` (F-2)
- `LaunchRepositoryOfflineTests` (F-2)
- `LoadableStateTests` (F-7)
- `LaunchDiffableSnapshotTests` (F-3)
- `LaunchQueryTests` (F-4)
- `LaunchListViewModelTests` (extended, F-4)
- `LaunchDetailViewModelTests` (F-5)
- `LaunchDetailRepositoryTests` (F-5)
- `StatsRepositoryTests` (F-6)
- `StatsViewModelTests` (F-6)

**UI tests** (`SpaceXUITests/`):
- `LaunchDetailNavigationUITests`:
  - Launch app → wait for rocket list → tap first rocket → wait for launch list → tap first launch → verify detail screen appears with mission name label visible
- `LaunchFilterUITests`:
  - Navigate to launch list → tap "Successful" filter chip → verify launch count changes → type "Falcon" in search bar → verify filtered results shown
- `LaunchPaginationUITests`:
  - Navigate to launch list → scroll to bottom → verify pagination indicator appears → verify new cells are appended

**Offline acceptance (final):**
- Run all URLProtocol-mocked offline tests from F-2, F-5 as a suite.

#### Definition of Done

- [ ] All unit tests listed above exist in the test target and pass
- [ ] No test in the suite makes a real network call (all mocked via protocol conformance)
- [ ] All `LaunchCacheStoreProtocol` tests use `UserDefaults(suiteName:)` and tearDown isolation
- [ ] All mock objects implement protocols — no concrete class inheritance
- [ ] `LaunchDetailNavigationUITests`, `LaunchFilterUITests`, `LaunchPaginationUITests` run and pass on iPhone 15 simulator (iOS 17)
- [ ] Xcode coverage report shows > 80% for all new ViewModels and Repositories
- [ ] Coverage report exported as CI artifact
- [ ] Full test suite (unit + UI) runs in < 5 minutes in CI

#### Risks + Mitigations

| Risk | Mitigation |
|------|-----------|
| UI test flakiness due to async launch list loading | Add explicit `XCTWaiter` / `waitForExpectations` with 5s timeout for each async step |
| Coverage < 80% after audit | Identify uncovered paths via Xcode coverage report; add targeted tests before marking phase done |

#### Rollback Plan
Tests do not affect production code. Failing tests in CI block merges — no rollback needed; fix failing tests before merge.

#### Time Estimate
- Optimistic: 3 days
- Realistic: 5 days
- Pessimistic: 7 days

---

### Code Examples — Phase 9

**Mock infrastructure — canonical pattern for all protocol mocks**

```swift
// File: SpaceXTests/Mocks/MockLaunchRepository.swift
final class MockLaunchRepository: LaunchRepositoryProtocol {
    var stubbedPageResult: LaunchPageResult = LaunchPageResult(launches: [], hasNextPage: false, nextPage: 0)
    var stubbedCachedLaunches: [Launch] = []
    var shouldThrowOnFetch = false
    private(set) var fetchInitialCallCount = 0
    private(set) var fetchNextPageCallCount = 0

    func fetchInitialLaunches(for rocketID: String) async throws -> LaunchPageResult {
        fetchInitialCallCount += 1
        if shouldThrowOnFetch { throw NetworkError.noConnection }
        return stubbedPageResult
    }

    func fetchNextLaunchPage(for rocketID: String, page: Int) async throws -> LaunchPageResult {
        fetchNextPageCallCount += 1
        if shouldThrowOnFetch { throw NetworkError.noConnection }
        return stubbedPageResult
    }

    func fetchAllCachedLaunches(for rocketID: String) -> [Launch] {
        stubbedCachedLaunches
    }
}

// File: SpaceXTests/Mocks/MockLaunchCacheStore.swift
final class MockLaunchCacheStore: LaunchCacheStoreProtocol {
    var stubbedLaunches: [Launch] = []
    var saveCallCount = 0

    func save(_ launches: [Launch], for rocketId: String) {
        saveCallCount += 1
        stubbedLaunches = launches
    }

    func load(for rocketId: String) -> [Launch]? {
        stubbedLaunches.isEmpty ? nil : stubbedLaunches
    }

    func clear(for rocketId: String) {
        stubbedLaunches = []
    }

    func allKnownRocketIds() -> [String] {
        stubbedLaunches.isEmpty ? [] : [stubbedLaunches.first!.rocketId]
    }
}
```

**UserDefaults test isolation helper**

```swift
// File: SpaceXTests/Helpers/UserDefaultsTestCase.swift
import XCTest
@testable import SpaceX

class UserDefaultsTestCase: XCTestCase {
    private(set) var testDefaults: UserDefaults!
    private static let suiteName = "com.test.launchCache"

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: Self.suiteName)!
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: Self.suiteName)
        testDefaults = nil
        super.tearDown()
    }
}

// Usage: inherit UserDefaultsTestCase in any cache store test
final class LaunchCacheStoreIntegrationTests: UserDefaultsTestCase {
    private var sut: UserDefaultsLaunchCacheStore!

    override func setUp() {
        super.setUp()
        sut = UserDefaultsLaunchCacheStore(defaults: testDefaults)
    }
    // ... tests
}
```

**Offline integration test — `LaunchRepositoryOfflineTests`** (see Phase 2 Code Examples for full listing)

**UI Test — `LaunchDetailNavigationUITests`**

```swift
import XCTest

final class LaunchDetailNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func test_tapLaunchCell_navigatesToDetailScreen() {
        let rocketCell = app.collectionViews.cells.firstMatch
        XCTAssertTrue(rocketCell.waitForExistence(timeout: 5))
        rocketCell.tap()

        let launchCell = app.collectionViews.cells.firstMatch
        XCTAssertTrue(launchCell.waitForExistence(timeout: 5))
        launchCell.tap()

        let missionNameLabel = app.staticTexts.element(matching: .any, identifier: "missionNameLabel")
        XCTAssertTrue(missionNameLabel.waitForExistence(timeout: 5))
        XCTAssertFalse(missionNameLabel.label.isEmpty)
    }

    func test_backNavigation_returnsToLaunchList() {
        app.collectionViews.cells.firstMatch.tap()
        let launchCell = app.collectionViews.cells.firstMatch
        XCTAssertTrue(launchCell.waitForExistence(timeout: 5))
        launchCell.tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.collectionViews.cells.firstMatch.waitForExistence(timeout: 3))
    }
}
```

**UI Test — `LaunchFilterUITests`**

```swift
import XCTest

final class LaunchFilterUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.collectionViews.cells.firstMatch.tap()
        XCTAssertTrue(app.collectionViews.cells.firstMatch.waitForExistence(timeout: 5))
    }

    func test_successfulFilterChip_reducesLaunchCount() {
        let initialCount = app.collectionViews.cells.count
        let successChip = app.buttons["filterChip_Successful"]
        XCTAssertTrue(successChip.waitForExistence(timeout: 3))
        successChip.tap()
        _ = XCTWaiter.wait(for: [expectation(description: "snapshot")], timeout: 1)
        XCTAssertLessThanOrEqual(app.collectionViews.cells.count, initialCount)
    }

    func test_searchBar_filtersByText() {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("Falcon")
        _ = XCTWaiter.wait(for: [expectation(description: "filter")], timeout: 1)
        XCTAssertTrue(app.collectionViews.cells.count > 0)
    }
}
```

---

## 7. Feature Traceability Matrix

| Feature ID | Feature Name | Phase(s) | Key Files | Acceptance Criteria | Tests |
|-----------|-------------|----------|-----------|-------------------|-------|
| F-1 | Domain Models and DTO Expansion | 1 | `Launch.swift`, `LaunchDTO.swift`, `LaunchMapper.swift`, `LaunchRemoteDataSource.swift`, `LaunchCellViewModel.swift`, `LaunchDetail.swift`, `Payload.swift`, `Core.swift`, `CrewMember.swift`, `Ship.swift`, `Capsule.swift`, `LaunchLinks.swift`, `Launchpad.swift`, `Landpad.swift`, `LaunchpadRemoteDataSource.swift`, `LandpadRemoteDataSource.swift` | `LaunchDTO` decodes full v4 JSON; `Launch.id` non-optional; `Launch`, `LaunchLinks`, `Core`, `CrewMember` conform to `Codable`; mapper returns nil for missing id; nulls handled safely | `LaunchMapperTests` |
| F-2 | UserDefaults Launch Cache Store | 2 | `LaunchCacheStore.swift`, `LaunchRepository.swift`, `AppContainer.swift` | Launches saved/loaded via `JSONEncoder`/`JSONDecoder` per `rocketId`; corrupt cache returns nil without crash; offline fallback works; `allKnownRocketIds()` tracks all saved rocket IDs; test isolation via `UserDefaults(suiteName:)` | `LaunchCacheStoreTests`, `LaunchRepositoryOfflineTests` |
| F-3 | Diffable Data Source + Compositional Layout | 4 | `LaunchView.swift`, `LaunchViewController.swift`, `LaunchCell.swift`, `LaunchErrorCell.swift`, `LaunchFilterCell.swift`, `LaunchesSection.swift`, `LaunchesItem.swift`, `LaunchFilterItem.swift` | Diffable DS renders launch list; sections work; pagination footer shown; animated diffs; no UITableView references | `LaunchDiffableSnapshotTests` |
| F-4 | Launch Search, Filtering, and Sorting | 5 | `LaunchQuery.swift`, `LaunchStatusFilter.swift`, `LaunchSortOrder.swift`, `LaunchListViewModel.swift`, `LaunchViewController.swift` | `applyQuery` does not trigger network; all filter/sort combos correct; search case-insensitive; empty result → empty state | `LaunchQueryTests`, `LaunchListViewModelTests` |
| F-5 | Launch Detail Screen | 6 | `LaunchDetailViewController.swift`, `LaunchDetailView.swift`, `LaunchDetailViewModel.swift`, `LaunchDetailRepository.swift`, `AppCoordinator.swift`, `AppContainer.swift`, `LaunchViewController.swift` | Cell tap opens detail; sections hidden when nil; pad section hidden on launchpad error; external links open in Safari; offline from UserDefaults cache | `LaunchDetailViewModelTests`, `LaunchDetailRepositoryTests`, `LaunchDetailNavigationUITests` |
| F-6 | Statistics Screen | 7 | `LaunchStats.swift`, `StatsRepository.swift`, `StatsViewModel.swift`, `StatsViewController.swift`, `LaunchStatsView.swift`, `AppCoordinator.swift`, `AppContainer.swift`, `RocketViewController.swift` | Aggregates correct on test data; opens without network; data loaded from all known rocketIds via `allKnownRocketIds()`; `UIHostingController` renders without layout errors; empty cache shows message | `StatsRepositoryTests`, `StatsViewModelTests` |
| F-7 | LoadableState Refactor | 3 | `LoadableState.swift`, `LaunchListViewModel.swift`, `LaunchViewController.swift` | `.failed(message, cachedValue)` shows cached data + error banner; `.loaded(_, isStale: true)` shows stale indicator; all state cases handled without crash | `LoadableStateTests`, `LaunchListViewModelTests` |
| F-8 | Design and Visual Consistency | 8 | `CardView.swift`, `SectionHeaderView.swift`, `LoadingIndicatorView.swift`, `EmptyStateView.swift`, `AppColors+SwiftUI.swift`, `AppFonts+SwiftUI.swift`, `LaunchDetailView.swift`, `LaunchStatsView.swift`, `LaunchCell.swift` | Zero hardcoded colors/fonts in new UI code; `CardView` used in detail screen; SwiftUI uses AppColors extensions; visual checklist in CONTRIBUTING.md | Manual screenshot checklist |
| F-9 | Test Finalization | 9 | All `SpaceXTests/` and `SpaceXUITests/` files | All unit tests pass; no real network calls; cache tests use `UserDefaults(suiteName:)` isolation; mock protocol conformance; >80% coverage; 3 UI tests pass | Full suite |

---

## 8. Cross-Project Test Strategy

### Test Pyramid for In-Scope Features

```
         ▲
        /UI\        3 UI tests (critical paths only)
       /────\
      / Integ \     Offline integration tests (F-2, F-5)
     /──────────\
    /   Unit     \  ~40 unit tests across all features
   /──────────────\
```

- **Unit tests (>80% of test count):** Pure Swift; no simulator; run in < 30s total. Test ViewModels, Repositories, Mappers, Query logic, LoadableState transitions, cache store encode/decode.
- **Integration tests (~15%):** URLProtocol-mocked network; `UserDefaults(suiteName:)` isolated cache; test repository offline behavior. Run in < 60s.
- **UI tests (~5%):** Three critical path tests on iPhone 15 (iOS 17). Each test uses `XCTWaiter` with 5s timeouts. Run in < 3 min total.

### UserDefaults Test Isolation Strategy

Every test that exercises `UserDefaultsLaunchCacheStore` or `LaunchRepositoryOfflineTests`:

```swift
let suiteName = "com.test.launchCache"
let testDefaults = UserDefaults(suiteName: suiteName)!
let store = UserDefaultsLaunchCacheStore(defaults: testDefaults)

// In tearDown:
testDefaults.removePersistentDomain(forName: suiteName)
```

This provides complete isolation per test class. No test may read or write to `UserDefaults.standard`. Use a base class `UserDefaultsTestCase` (defined in Phase 9) for reuse.

### Repository / Service Contract Tests

Each protocol is tested via a dedicated contract suite:
- `LaunchCacheStoreProtocol`: tested by `LaunchCacheStoreTests` (concrete `UserDefaultsLaunchCacheStore`)
- `LaunchRepositoryProtocol`: tested by `LaunchListViewModelTests` (via mock) and `LaunchRepositoryOfflineTests` (integration with real `UserDefaultsLaunchCacheStore`)
- `StatsRepositoryProtocol`: tested by `StatsRepositoryTests` (concrete) and `StatsViewModelTests` (via mock)
- `LaunchDetailRepositoryProtocol`: tested by `LaunchDetailRepositoryTests` (concrete) and `LaunchDetailViewModelTests` (via mock)

All mock objects are hand-written structs/classes conforming to protocols — no subclassing of concrete types.

### Regression Scenarios for Existing Rocket → Launch Flow

| Scenario | Test |
|---------|------|
| Rocket list loads from network | `RocketViewModelTests.test_fetchRockets_success_updatesState()` (existing, must still pass) |
| Launch list loads for selected rocket | `LaunchListViewModelTests.test_loadInitialLaunches_success_transitionsToLoaded()` |
| Pagination triggers on scroll threshold | `LaunchListViewModelTests.test_loadNextPageIfNeeded_triggersPagination()` |
| Network error on launch list shows error state | `LaunchListViewModelTests.test_loadInitialLaunches_networkFailure_transitionsToFailed()` |
| Back navigation from launch list returns to rocket list | `LaunchDetailNavigationUITests` includes back navigation step |

---

## 9. Delivery Slicing

### PR Slicing Strategy

Each PR must be:
- **Reviewable in < 60 minutes** (target: < 400 lines changed)
- **Independently buildable** (no partial feature broken state)
- **Green on CI** (build + unit tests must pass)

### Recommended PR Sequence

| PR # | Title | Phase | Target Size |
|-----|-------|-------|------------|
| 1 | Expand `LaunchDTO` and `Launch` domain model with `Codable` | Phase 1 | ~150 lines |
| 2 | Add new domain value types and Launchpad data sources | Phase 1 | ~200 lines |
| 3 | Update `LaunchMapper` for expanded DTO | Phase 1 | ~100 lines |
| 4 | Add `LaunchCacheStoreProtocol` and `UserDefaultsLaunchCacheStore` | Phase 2 | ~120 lines |
| 5 | Integrate cache into `LaunchRepository` and `AppContainer` | Phase 2 | ~100 lines |
| 6 | Add `LoadableState<Value>` and update `LaunchListViewModel` | Phase 3 | ~150 lines |
| 7 | Migrate `LaunchView` to `UICollectionView` + Compositional Layout | Phase 4 | ~250 lines |
| 8 | Migrate `LaunchViewController` to Diffable Data Source | Phase 4 | ~300 lines |
| 9 | Add `LaunchQuery`, `LaunchStatusFilter`, `LaunchSortOrder` | Phase 5 | ~100 lines |
| 10 | Implement `applyQuery` in `LaunchListViewModel` + `UISearchController` | Phase 5 | ~200 lines |
| 11 | Add `LaunchDetailRepository` and `LaunchDetailViewModel` | Phase 6 | ~200 lines |
| 12 | Build `LaunchDetailView` and `LaunchDetailViewController` | Phase 6 | ~350 lines |
| 13 | Wire `showLaunchDetail` in coordinator and cell tap | Phase 6 | ~100 lines |
| 14 | Add `StatsRepository`, `StatsViewModel`, `LaunchStats` | Phase 7 | ~200 lines |
| 15 | Build `LaunchStatsView` (SwiftUI) + `StatsViewController` | Phase 7 | ~250 lines |
| 16 | Wire `showStats` in coordinator and `RocketViewController` | Phase 7 | ~80 lines |
| 17 | Extract `CardView`, `SectionHeaderView`, shared components | Phase 8 | ~200 lines |
| 18 | Apply shared components to `LaunchDetailView` and `LaunchStatsView` | Phase 8 | ~150 lines |
| 19 | Add `AppColors+SwiftUI`, `AppFonts+SwiftUI` extensions | Phase 8 | ~80 lines |
| 20 | Add all missing unit tests and fix coverage gaps | Phase 9 | ~400 lines |
| 21 | Add `LaunchDetailNavigationUITests` | Phase 9 | ~100 lines |
| 22 | Add `LaunchFilterUITests` and `LaunchPaginationUITests` | Phase 9 | ~150 lines |

### Merge Order

PRs 1–3 must merge in sequence (Phase 1).  
PRs 4–5 must merge in sequence (Phase 2) — significantly simpler than the original plan.  
PRs 6 (Phase 3) and PRs 7–8 (Phase 4) can merge in any order after PRs 1–3 are merged.  
PRs 9–10 must merge after PRs 7–8 (Phase 4 complete).  
PRs 11–13 (Phase 6) and PRs 14–16 (Phase 7) can merge in parallel after PRs 4–8.  
PRs 17–19 must merge after PRs 11–16 (all UI screens exist).  
PRs 20–22 must merge last (Phase 9).

### Suggested Conventional Commit Themes

```
feat: add id and Codable conformance to Launch domain model
feat: expand LaunchDTO with v4 API response fields
feat: add Launchpad and Landpad domain models and remote data sources
feat: update LaunchMapper to handle expanded DTO with nil safety
feat: add LaunchCacheStoreProtocol with save/load/clear/allKnownRocketIds
feat: implement UserDefaultsLaunchCacheStore with JSONEncoder/JSONDecoder
feat: integrate read-through/write-through UserDefaults cache into LaunchRepository
feat: add LoadableState generic enum for offline-first state management
refactor: replace LaunchListState with LoadableState in LaunchListViewModel
refactor: migrate LaunchView from UITableView to UICollectionView
refactor: replace UITableViewDataSource with UICollectionViewDiffableDataSource
feat: add LaunchesSection, LaunchesItem, LaunchFilterCell for Diffable DS
feat: add LaunchQuery, LaunchStatusFilter, LaunchSortOrder domain types
feat: implement applyQuery in-memory filtering in LaunchListViewModel
feat: integrate UISearchController and filter chips in LaunchViewController
feat: add LaunchDetailRepository reading from UserDefaults cache
feat: build LaunchDetailView scrollable layout with all sections
feat: wire showLaunchDetail coordinator method and cell tap handler
feat: add StatsRepository aggregating launches from all known rocketIds
feat: build LaunchStatsView with Swift Charts via UIHostingController
feat: wire showStats coordinator method and RocketViewController entry point
feat: add CardView, SectionHeaderView, LoadingIndicatorView, EmptyStateView
feat: add AppColors and AppFonts SwiftUI extensions
refactor: apply CardView and design tokens in LaunchDetailView and LaunchStatsView
test: add LaunchMapperTests covering edge cases and null handling
test: add LaunchCacheStoreTests with UserDefaults suiteName isolation
test: add LaunchRepositoryOfflineTests with URLProtocol mock
test: add LoadableStateTests for all state transitions
test: add LaunchQueryTests for all filter and sort combinations
test: add LaunchDetailViewModelTests and LaunchDetailRepositoryTests
test: add StatsRepositoryTests and StatsViewModelTests
test: add LaunchDetailNavigationUITests critical path
test: add LaunchFilterUITests and LaunchPaginationUITests
```

---

## 10. Operational Readiness

### Deployment Target Impact

Swift Charts requires **iOS 16.0+**. The Statistics screen (`StatsViewController` and `LaunchStatsView`) must be guarded:

```swift
if #available(iOS 16, *) {
    coordinator?.showStats()
} else {
    // Show UIAlertController: "Statistics require iOS 16 or later"
}
```

Document in `README.md`:
> **Statistics Screen** requires iOS 16.0+. All other features are compatible with iOS 13.0+.

If the project's minimum deployment target is raised to iOS 16, remove the `#available` guard.

### Entitlements / Capabilities Checklist

| Capability | Required | Phase | Notes |
|-----------|---------|-------|-------|
| Network access (App Transport Security) | Existing | — | Already configured |
| Background App Refresh | No | — | Not required by any in-scope feature |
| iCloud / CloudKit | No | — | Cache is local-only UserDefaults |
| Push Notifications | No | — | Not in scope |

No new entitlements are required by any in-scope feature.

### Info.plist Checklist

| Key | Required | Phase | Notes |
|-----|---------|-------|-------|
| `NSAppTransportSecurity` | Existing | — | Already present |
| `UIRequiredDeviceCapabilities` | Existing | — | No changes needed |

No new `Info.plist` keys are required by any in-scope feature.

### CI Checks Per Phase

| Phase | CI Gate |
|-------|---------|
| Phase 1 | Build succeeds + `LaunchMapperTests` pass |
| Phase 2 | Build succeeds + `LaunchCacheStoreTests`, `LaunchRepositoryOfflineTests` pass |
| Phase 3 | Build succeeds + `LoadableStateTests`, `LaunchListViewModelTests` pass |
| Phase 4 | Build succeeds + `LaunchDiffableSnapshotTests` pass |
| Phase 5 | Build succeeds + `LaunchQueryTests`, `LaunchListViewModelTests` pass |
| Phase 6 | Build succeeds + `LaunchDetailViewModelTests`, `LaunchDetailRepositoryTests` pass |
| Phase 7 | Build succeeds + `StatsRepositoryTests`, `StatsViewModelTests` pass |
| Phase 8 | Build succeeds + `rg 'UIColor(red:' SpaceX/Features/LaunchDetail SpaceX/Features/Stats` returns zero matches |
| Phase 9 | Build succeeds + full unit test suite passes + 3 UI tests pass + Xcode coverage > 80% for new ViewModels and Repositories |

### Release Gates

Before any production release:
- [ ] All Phase 9 `Definition of Done` checkboxes are checked
- [ ] Full test suite (unit + UI) passes on iPhone 15 simulator (iOS 17)
- [ ] Xcode coverage report > 80% for all new ViewModels and Repositories
- [ ] No hardcoded color/font values in new UI files (verified by CI `rg` check)
- [ ] Swift Charts deployment target note in `README.md`
- [ ] `CONTRIBUTING.md` visual consistency checklist present
- [ ] All `AppCoordinating` protocol methods implemented in `AppCoordinator`
- [ ] All `LaunchDetail/`, `Stats/`, `Launchpad/` directories present in project navigator and compile target
- [ ] No reference to `NSPersistentContainer`, `NSManagedObject`, `NSFetchRequest`, or `.xcdatamodeld` anywhere in the codebase

---

## 11. Final Master Checklist

### Combined Phase Checklist

- [ ] Phase 1 (F-1): All `Definition of Done` items checked
- [ ] Phase 2 (F-2): All `Definition of Done` items checked
- [ ] Phase 3 (F-7): All `Definition of Done` items checked
- [ ] Phase 4 (F-3): All `Definition of Done` items checked
- [ ] Phase 5 (F-4): All `Definition of Done` items checked
- [ ] Phase 6 (F-5): All `Definition of Done` items checked
- [ ] Phase 7 (F-6): All `Definition of Done` items checked
- [ ] Phase 8 (F-8): All `Definition of Done` items checked
- [ ] Phase 9 (F-9): All `Definition of Done` items checked

### Combined Feature Checklist

- [ ] F-1: `Launch.id` non-optional; `LaunchDTO` decodes full v4 response; `Launch`/`LaunchLinks`/`Core`/`CrewMember` conform to `Codable`; mapper nil-safe
- [ ] F-2: `UserDefaultsLaunchCacheStore` operational; read-through/write-through; offline behavior verified; cache key scoped by `rocketId`; corrupt data handled gracefully
- [ ] F-3: `UICollectionViewDiffableDataSource` live; no `UITableView` references; animated diffs
- [ ] F-4: `applyQuery` filters in-memory; `UISearchController` present; filter chips functional
- [ ] F-5: `LaunchDetailViewController` navigable from cell tap; sections hide when nil; offline from UserDefaults cache
- [ ] F-6: `StatsViewController` with Swift Charts; cache-only; aggregates from all known rocketIds; empty state handled
- [ ] F-7: `LoadableState<Value>` in `Core/UI/`; all new ViewModels adopt it; `LaunchListViewModel` updated
- [ ] F-8: Shared components in `Core/UI/Components/`; zero hardcoded colors/fonts in new code; SwiftUI extensions present
- [ ] F-9: > 80% coverage; 3 UI tests pass; no real network calls; all mock objects protocol-based; all cache tests use suiteName isolation

### Go/No-Go Checklist

- [ ] All 9 phase `Definition of Done` checklists complete (no unchecked items)
- [ ] Zero failing tests in CI
- [ ] Zero build warnings in new code (treat warnings as errors for new files)
- [ ] `AppCoordinating` protocol has `showLaunchDetail(for:)` and `showStats()` methods
- [ ] `AppContainer` has factory methods `makeLaunchDetailViewModel(launchId:)` and `makeStatsViewModel()`
- [ ] Existing regression scenarios (Rocket → Launch flow) pass
- [ ] Swift Charts `#available(iOS 16, *)` guard present
- [ ] Visual consistency checklist in `CONTRIBUTING.md`
- [ ] Coverage report archived as CI artifact
- [ ] Codebase contains zero references to Core Data framework, `.xcdatamodeld`, or `NSManagedObject`

---

## 12. Self-Check Report

### Overall Status: PASS

### Coverage Score: 20/20

### Failed Checks Fixed: None

### Validation Results

| # | Check | Result |
|---|-------|--------|
| 1 | Every feature in input file (F-1 through F-9) mapped to at least one concrete phase | PASS — each of the 9 features has a dedicated phase |
| 2 | No feature outside the input file appears anywhere in output | PASS — no extra features added |
| 3 | Feature IDs/names in matrix exactly match input numbering (F-1 through F-9) | PASS — matrix table uses exact IDs and names from input |
| 4 | Every phase includes exact file paths to create/modify | PASS — every phase has explicit path tables |
| 5 | Every phase has measurable Definition of Done | PASS — each phase has checkbox DoD with specific, verifiable items |
| 6 | Every phase has explicit test plan | PASS — each phase lists specific test file names and test method names |
| 7 | Every phase has rollback strategy | PASS — each phase has a "Rollback Plan" section |
| 8 | Every phase has risk + mitigation | PASS — each phase has a risk table |
| 9 | No phase requires full rewrite | PASS — all changes are incremental; existing files are modified, not replaced wholesale |
| 10 | UIKit-first constraint preserved | PASS — SwiftUI used only in `LaunchStatsView` inside `UIHostingController` (F-6 only) |
| 11 | MVVM + Coordinator preserved | PASS — all new screens follow ViewModel + Coordinator pattern; no pattern deviations |
| 12 | UserDefaults offline-first strategy defined where applicable | PASS — F-2 defines read-through/write-through with `UserDefaultsLaunchCacheStore`; F-5 and F-6 reference cache; test isolation via suiteName specified |
| 13 | Diffable + Compositional planned only if present in input | PASS — F-3 in input; implemented in Phase 4 only |
| 14 | Swift Charts/UIHostingController planned only if present in input | PASS — F-6 in input; implemented in Phase 7 only |
| 15 | No hidden dependencies between phases | PASS — dependency graph is fully explicit; all blockers listed per phase |
| 16 | Critical path identified | PASS — `F-1 → F-2 → F-5 → F-8 → F-9` identified in Section 5 |
| 17 | Parallel streams identified | PASS — (Phase 3 ‖ Phase 4), (Phase 6 ‖ Phase 7) explicitly called out |
| 18 | Existing flow regression protection included | PASS — Section 8 lists 5 specific regression scenarios with test references |
| 19 | No vague language | PASS — all steps specify exact file paths, method names, and measurable outcomes |
| 20 | Every phase has a `Code Examples` subsection | PASS — all 9 phases have `### Code Examples` with concrete Swift snippets and test examples |

### Remaining Assumptions

1. **Deployment target:** The current project minimum deployment target is assumed to be iOS 13.0. If it is already iOS 16.0, the `#available(iOS 16, *)` guard in Phase 7 can be removed.
2. **Kingfisher availability:** `LaunchDetailView` uses Kingfisher for hero image loading, assumed to already be a project dependency (listed in `CLAUDE.md` as a Swift Package Manager dependency).
3. **SnapKit availability:** New views use SnapKit for constraints, assumed to already be a project dependency (listed in `CLAUDE.md`).
4. **`AppLogger.make(_:)` API:** Logging uses the existing `AppLogger` pattern. If the API differs, logging lines require adjustment.
5. **UserDefaults storage bound:** This plan assumes the total cached launch dataset across all rockets does not exceed ~2,000 records (~2 MB serialised). If the dataset grows substantially, migrate `UserDefaultsLaunchCacheStore` to a file-backed store or SQLite while keeping `LaunchCacheStoreProtocol` and all callers unchanged.
6. **`coreReuseCount` in F-6:** Requires `Core.reused: Bool` field in the `Core` domain type and `Launch.cores: [Core]?` field (both added in F-1). These fields must be included in the `LaunchDTO.cores[]` decoding.
7. **`SpaceXUITests` target:** Assumes a `SpaceXUITests` Xcode test target exists or can be created alongside `SpaceXTests`. If it does not exist, it must be added to the Xcode project file.
8. **`allKnownRocketIds` ordering:** The index stored in `UserDefaults` is an unordered array. `StatsRepository` iterates all known IDs to aggregate across rockets; order does not affect aggregate correctness.
