# First State Lens

First State Lens is a native, local-first iPhone study app for high-school and early-college learners. It turns trustworthy public and open educational material into short, structured courses across humanities, mathematics, science, computing, social science, and personal finance.

The app includes 29 course paths, 36 lessons, 72 original practice questions, lesson notes, source readings, in-app YouTube playback in the core paths, explainable recommendations, XP and levels, streaks, ten rule-based academic awards, a private study community, and a college launchpad. Every reward is calculated from saved activity; there are no fake users, leaderboards, or progress values.

Seventeen paths are labeled High School and twelve are labeled College. Lessons, notes, tests, progress, community writing, readiness checklists, and rewards work from the bundled app; video streaming, sharing, and linked source readings require external services.

> Original practice material informed by publicly available Delaware learning objectives and archival records. Not an official Delaware assessment and not endorsed by the State of Delaware.

## Build and test

```sh
swift test
xcodebuild -project FirstStateLens.xcodeproj -scheme FirstStateLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

See [STATUS.md](STATUS.md) for verified scope and [SOURCES.md](SOURCES.md) for content provenance.
