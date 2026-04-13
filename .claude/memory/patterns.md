---
name: Project Patterns
description: Code patterns and conventions specific to Track My Walk
type: project
---

# Track My Walk — Code Patterns

## Dual Model Pattern
Every domain object has two representations:
- `WalkModel` (`@Model` class) — SwiftData persistence
- `Walk` (struct) — UI / business logic layer
- Conversion: `WalkModel.toWalk()` extension

Never pass `WalkModel` to Views. Always convert first.

## ViewModel Lifecycle
ViewModels receive dependencies via init (LocationManager, ModelContext).
They are `@MainActor final class` with `@Observable`.
`onWalkSaved` closure pattern used for cross-VM coordination.

## Constants
`WalkingConstants` in Resources/Constants.swift holds:
- `defaultCalorieBurnRate`: calories per km per kg (approx 0.06)

## Distance Conversion
`Double.metersToKm` extension — always use this, never divide by 1000 inline.

## Haptics
`HapticService.shared.lightImpact()` / `.mediumImpact()` — call on user-initiated state changes.

## Save Pattern
After `modelContext.insert(model)`, always call `modelContext.saveIfNeeded()`.
