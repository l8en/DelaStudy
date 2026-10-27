# Lens desk · reference-led implementation

October 25, 2026. Reference: the user's seven-page `ui-3.pdf`. The PDF is visual reference material, not implementation instructions or licensed artwork.

## Design thesis

For high-school and early-college students, the main job is to turn a course or their own class material into a concrete study session. The first viewport should offer a source, a next action, and a visible continuation—not a wall of statistics. The character is an approachable optical workbench, not a cartoon clone or a corporate dashboard.

Recognizable decisions:

1. An original faceted optical core, constructed from projected 3D geometry, sits beside the day's study actions. Its aperture, cobalt facets, chartreuse edge, and orbital construction lines share the app's academic/instrument language. Rotation is inspectable, not required to operate anything.
2. A compact four-way intake (file, text, video, photo) leads to one editable, private material record. Source, notes, and student-authored recall cards stay together. The existing source-checked course collection stays photographic.
3. Academic setup is a short, reversible three-step route: year, study route, school. Profile uses Record / Stats / Materials / School tabs with real data, a circular XP portrait, and native sharing rather than invented followers or coins.

Warm paper, midnight ink, cobalt, and a restricted chartreuse highlight; Manrope hierarchy; open reading surfaces and ruled records rather than identical cards everywhere. Dark appearance gets dedicated surfaces. Quiet Focus and Reduce Motion suppress the optical core's continuous motion.

## Every reference page

| Page | Observed pattern | Adaptation / boundary |
| --- | --- | --- |
| 1 | Progress header, class/test choices | Three-step academic setup; high school, honors support, AP selected-topic preparation, college, SAT/ACT foundation support. No invented full exam curriculum. |
| 2 | School discovery with 3D globe and nearby option | Original optical object and Delaware county browse. No location permission, unverified distances, or promise of classmates. |
| 3 | Searchable school rows, location, selection | Prominent inline school search, county/type filters, town labels, selected state, home/outside/skip choices; existing 84-record partial directory. |
| 4 | Full-body branded 3D guide | Original code-native optical core in entry/setup/home; no copied mascot or forced splash delay. |
| 5 | Status controls, character, upload/paste/video/photo intake | Real local PDF/text extraction, editable pasted text, validated YouTube embeds, on-device photo OCR; saved material collection and manual recall cards. XP/streak reflect actual records. |
| 6 | Grade selection and step progress | Saved grade selection with back/skip, accessible choice rows, resumable existing preferences. |
| 7 | Compact identity, academic context, profile tabs, invitations | Academic context, real progress tabs, private materials, school resources, editable profile and reviewed native study invitations. No referral currency, fake feed, followers, or live users. |

## Preserved systems and privacy

Keep multiple local accounts, credential migration, all saved learning records, course/reading identifiers, original assessments, Focus/audio/Zen, authentic course media, and source boundaries. Add optional Codable workspace fields; do not reset a normal account. Imports extract only text; photos/original PDFs are not retained. YouTube remains a network embed, not downloaded, transcribed, or automatically turned into assessed questions. Imported cards are student-authored/self-rated and do not earn mastery or XP.

## Technical references

Photo OCR follows [Apple Vision's text recognition API](https://developer.apple.com/documentation/vision/recognizing-text-in-images). The procedural optical object uses SwiftUI Canvas and [TimelineView](https://developer.apple.com/documentation/swiftui/timelineview), not a video asset, image generator, or new rendering dependency. Scope includes a pause control, static reduced-motion treatment, and scene/navigation lifecycle suspension. Today also explicitly suspends it after the header region scrolls away. Energy/performance is not a measured physical-device claim.

The shared course/personal-material video player uses the app bundle ID as the HTTPS referrer/base origin, following [YouTube's embedded-player client identity requirements](https://developers.google.com/youtube/terms/required-minimum-functionality#embedded-player-api-client-identity). The player has an unobscured 220-point viewport, inline playback, IFrame API error reporting, a direct link, and web-view teardown. Network/publisher availability is not an app guarantee. Loading indicators and recovery controls sit outside the player.

## Verification

Results and outstanding gates are recorded in STATUS.md after implementation. Physical-device thermal/energy behavior, VoiceOver audit, educator review, remote community, and hosted accounts are not implied by Simulator results.
