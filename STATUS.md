# Product and technical audit

Verified October 16, 2026.

## Scope

First State Lens is a multi-course high-school and early-college study experience. Students choose among U.S. History, Algebra I, AP Biology, College Algebra, and General Biology I, then move through prerequisite-linked lesson paths grounded in public standards and openly licensed curricula.

This is an original practice tool, not an official assessment. It does not claim that Delaware students broadly lack civics resources; the defensible product opportunity is that official material currently published as teacher-oriented web pages and PDFs can be made into a guided, offline, progress-aware student experience.

## Architecture

- SwiftUI iPhone app, iOS 17+
- Pure Swift domain/content/validation/mastery code in `FirstStateCore`
- JSON file persistence with atomic replacement and explicit errors
- `@Observable` application model for navigation and session coordination
- Bundled lesson notes and 24 authored test questions with source metadata
- Smooth inline YouTube playback through a privacy-enhanced `WKWebView`, plus a direct YouTube fallback
- Local learner profile, current-course selection, daily goal, XP, levels, streaks, and awards
- No accounts, analytics, advertising, or third-party packages; only streaming video and outbound readings require a network

## Mastery rules

For each objective, attempts are ordered by timestamp and stable identifier. Starting at zero, a correct answer moves the estimate halfway toward 1.0; an incorrect answer multiplies it by 0.65. An objective is `demonstrated` only after at least two correct answers and a score of at least 0.70. A latest incorrect answer marks it for review. Recommendations consider only objectives whose prerequisites are demonstrated, then prioritize review, in-progress work, and new work; ties use score, authored order, then stable ID.

This is an explainable practice heuristic, not a validated measurement of student knowledge.

## Current product criteria

- Student chooses a course, display name, and study intention on first launch.
- Student can browse five course pages grouped by High School and College and see actual lesson status and completion.
- Every lesson includes an overview, key ideas, notes, a sourced reading, a playable video, and a two-question test.
- Each question can be submitted once and shows accurate feedback.
- Attempts, sessions, profile, course selection, rewards, and onboarding state persist after relaunch.
- Home, Learn, Awards, and Profile derive their state from stored attempts and sessions.
- Empty, completed, locked, and persistence-error states have explicit UI.
- Content validator rejects broken references, missing lesson material, malformed YouTube identifiers, duplicate IDs, invalid answers, empty required text, and prerequisite cycles.
- Core tests and an iOS Simulator build pass before a completion claim.

## Risks and boundaries

- The 24-question bank and 12 lessons are a credible curriculum-backed product slice, not complete reproductions of the source curricula.
- The app uses facts found in official public records and standards, but educator review remains a public-release gate.
- Embedded media availability, captions, ads, and data handling are controlled by YouTube; every lesson provides a direct fallback link.
- Simulator validation does not substitute for VoiceOver, performance, and physical-device testing.
- No claim is made that this heuristic improves grades or predicts assessment performance.

## Current verification

- `swift test`: 22 tests passed across content and video validation, answer evaluation, duplicate prevention, course-scoped mastery, reward calculations, streaks, schema migration, and persistence recovery.
- `xcodebuild ... test` on iPhone 17 Pro Simulator: the end-to-end UI journey passed, including onboarding, high-school and college catalog discovery, lesson notes, loaded embedded video, testing, awards, and relaunch persistence.
- The redesigned Home screen was visually inspected on iPhone 17 Pro Simulator.
- Earlier single-course builds were checked on iPhone 17e, dark appearance, and Accessibility Extra Large text; the new multi-course surfaces still require those repeat checks.
- Physical-device performance, hands-on VoiceOver traversal, and educator review remain release gates.
