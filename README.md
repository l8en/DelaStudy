# First State Lens

First State Lens is a native, local-first iPhone study app for high-school and early-college learners. It turns trustworthy public and open educational material into short, structured courses in U.S. history, algebra, and biology.

The app includes five course paths, 12 prerequisite-linked lessons, 24 original practice questions, lesson notes, source readings, in-app YouTube playback, explainable recommendations, XP and levels, streaks, six earned awards, and a private local profile. Every reward is calculated from saved lesson activity; there are no fake users, leaderboards, or progress values.

Three courses are labeled High School: U.S. History, Algebra I, and AP Biology. Two are labeled College: College Algebra and General Biology I. Core lessons, notes, tests, progress, and rewards work from the bundled app; video streaming and linked source readings require internet access.

> Original practice material informed by publicly available Delaware learning objectives and archival records. Not an official Delaware assessment and not endorsed by the State of Delaware.

## Build and test

```sh
swift test
xcodebuild -project FirstStateLens.xcodeproj -scheme FirstStateLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

See [STATUS.md](STATUS.md) for verified scope and [SOURCES.md](SOURCES.md) for content provenance.
