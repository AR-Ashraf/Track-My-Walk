---
name: Project Context
description: Track My Walk iOS app overview, goals, and current state
type: project
---

# Track My Walk

## Overview
An iOS walk tracking app built on an iOS boilerplate. Tracks walks with GPS, records route on a map, shows stats (distance, duration, calories, pace), and persists history with SwiftData.

## Current State (as of Apr 2026)
- Core walk tracking implemented: start/pause/resume/stop/cancel
- MapKit route rendering in progress (MapViewRepresentable)
- SwiftData persistence complete (WalkModel, WalkPoint)
- Tab shell in place: Tracking tab + History tab + Settings tab
- Auth screens exist (Login, SignUp) but may be boilerplate placeholders
- Example feature is leftover boilerplate — likely to be removed

## Key Files
- Entry: `Boilerplate/App/BoilerplateApp.swift`
- Core VM: `Boilerplate/Features/WalkTracking/ViewModels/TrackingViewModel.swift`
- Walk model (SwiftData): `Boilerplate/Core/Database/` (WalkModel)
- Walk model (UI): `Boilerplate/Features/WalkTracking/Models/Walk.swift`
- Location: `Boilerplate/Core/Location/LocationManager.swift`
- Tab root: `Boilerplate/Features/WalkTracking/Views/WalkMainTabView.swift`

## Target Platform
iOS 17+ (required for @Observable macro and SwiftData)

## Xcode Project
`Boilerplate.xcodeproj` — target name is still "Boilerplate" (rename pending)
