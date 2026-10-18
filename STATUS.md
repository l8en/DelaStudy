# Product and technical audit

Verified October 17, 2026.

## Scope

First State Lens is a 29-path high-school and early-college study experience. Students browse humanities, mathematics, science, computing, social science, and personal-finance paths grounded in public standards and openly licensed curricula.

This is an original practice tool, not an official assessment. It does not claim that Delaware students broadly lack civics resources; the defensible product opportunity is that official material currently published as teacher-oriented web pages and PDFs can be made into a guided, offline, progress-aware student experience.

## Architecture

- SwiftUI iPhone app, iOS 17+
- Pure Swift domain/content/validation/mastery code in `FirstStateCore`
- JSON file persistence with atomic replacement and explicit errors
- `@Observable` application model for navigation and session coordination
- Bundled notes for 36 lessons and 72 authored test questions with source metadata
- Smooth inline YouTube playback through a privacy-enhanced `WKWebView`, plus a direct YouTube fallback
- Local learner profile, current-course selection, daily goal, XP, levels, streaks, awards, community responses, challenges, and college checklist
- No accounts, analytics, advertising, or third-party packages; only streaming video and outbound readings require a network

## Mastery rules

For each objective, attempts are ordered by timestamp and stable identifier. Starting at zero, a correct answer moves the estimate halfway toward 1.0; an incorrect answer multiplies it by 0.65. An objective is `demonstrated` only after at least two correct answers and a score of at least 0.70. A latest incorrect answer marks it for review. Recommendations consider only objectives whose prerequisites are demonstrated, then prioritize review, in-progress work, and new work; ties use score, authored order, then stable ID.

This is an explainable practice heuristic, not a validated measurement of student knowledge.

## Current product criteria

- Student chooses a course, display name, and study intention on first launch.
- Student can search and filter 29 course pages grouped into 17 High School and 12 College pathways.
- Every lesson includes an overview, key ideas, notes, a sourced reading, and a two-question test; the original twelve lessons also include embedded video.
- Each question can be submitted once and shows accurate feedback.
- Attempts, sessions, profile, course selection, rewards, community writing, challenge state, college checklist, and onboarding state persist after relaunch.
- Home, Learn, Community, College, Awards, and Profile derive their state from local saved work.
- Main screens use a scroll-responsive header that transforms into a compact material capsule.
- Empty, completed, locked, and persistence-error states have explicit UI.
- Content validator rejects broken references, missing lesson material, malformed YouTube identifiers, duplicate IDs, invalid answers, empty required text, and prerequisite cycles.
- Core tests and an iOS Simulator build pass before a completion claim.

## Risks and boundaries

- The 72-question bank and 36 lessons are curriculum-backed foundation modules, not complete reproductions of 29 full-year curricula or college credit.
- The app uses facts found in official public records and standards, but educator review remains a public-release gate.
- Embedded media availability, captions, ads, and data handling are controlled by YouTube; every lesson provides a direct fallback link.
- Simulator validation does not substitute for VoiceOver, performance, and physical-device testing.
- No claim is made that this heuristic improves grades or predicts assessment performance.

## Current verification

- `swift test`: 23 tests passed across content and video validation, answer evaluation, duplicate prevention, course-scoped mastery, reward calculations, streaks, schema migration, and persistence recovery.
- `xcodebuild ... test` on iPhone 17 Pro Simulator: both UI tests passed. The end-to-end journey covers onboarding, the 29-path catalog, Community challenge state, the College checklist, lesson notes, loaded embedded video, testing, awards, and relaunch persistence; the focused motion test verifies the compact course header after scrolling.
- Home, catalog, Community, College, profile, awards, and the compact scroll header were visually inspected on iPhone 17 Pro Simulator.
- The redesigned Home screen was checked again in dark appearance with readable text, controls, metrics, cards, and tab labels.
- Accessibility Extra Large text was checked on an earlier build; the expanded catalog and new Community and College surfaces still need that repeat check.
- Physical-device performance, hands-on VoiceOver traversal, and educator review remain release gates.
