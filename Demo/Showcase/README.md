# DelaStudy showcase

## Current edition: unchanged walkthrough, concise explanations

[DelaStudy-Explained-2m15.mp4](DelaStudy-Explained-2m15.mp4) keeps the approved
phone walkthrough, frame, transitions and exact 135-second timeline. It uses the
finished 2:15 movie itself as the base, with no source-range changes or retiming.
Only the right-hand presentation area is replaced. The approved movie and its
original narration document are preserved as separate, unchanged files.

Ten compact, source-grounded diagrams replace most code windows: preferences
converging into a saved plan, course discovery, the five-unit structure, practice
and one-time XP, resource categories, college steps, task-to-Focus, playback
states, Zen’s timer/task relationship, and earned progress. Timed highlights
follow the feature being explained. Diagrams are at most 900 × 340 pixels, aligned
near the lower right, with the upper webcam area clear. No new app UI or data is
composited inside the phone.

Exactly two actual source excerpts remain: saving the lesson position before
advancing (0:41–0:51), and validating a notification’s account/session IDs before
opening Focus (1:56–2:07). Both show real source lines, not example pseudocode.

[DelaStudy-Team-Narration.docx](DelaStudy-Team-Narration.docx) is the matching
257-word, three-page script: M’hamed at 0:00–0:41, Ibby at 0:41–1:36, and Sai at
1:36–2:15. Read the main text at its timestamps; the wording covers the diagrams
and both code snippets, so no improvised technical explanation is needed. The
script is separate from the silent video. All pages are rendered and visually
checked, including smaller cues for onboarding, question types and the alert tap.

`explained-edit-manifest.json` and `explained-narration.json` record the exact
overlay timing and narration. The approved source SHA-256 remains
`9b8a7ebb2494dd887889a6e0c7adece0962a3175ee607bec3292c77af7e5c7b8`.
Video re-encoding introduces minor pixel differences; the phone’s source footage,
ordering, speed and framing are preserved, not claimed to be losslessly copied.

## Approved earlier edition: 2:15, no hand

[DelaStudy-Walkthrough-2m15.mp4](DelaStudy-Walkthrough-2m15.mp4) is the current
silent 1920 × 1080 showcase. It keeps the white background, iPhone 14 Pro-style
frame and lower-right Mac code windows, with open webcam space above. The hand
and holding animation are removed. No narration, captions or marketing titles
are burned into the video; app text and actual source excerpts remain.

[DelaStudy-Showcase-Script.docx](DelaStudy-Showcase-Script.docx) is the separate
time-aligned narration document, split between M’hamed and two optional teammates.
Its three pages were rendered and visually checked. Use this script with the
2:15 video, not the earlier 2:48 presenter notes.

The footage creates **Waffles123**, shows all seven onboarding stages, browses
courses, completes a short Geometry lesson and its three question types, opens
the separate resource categories, checks a college-planning item, saves a task,
and demonstrates sound playback, Zen and the earned profile record. Colored
sound glyphs now animate only during playback, with a static Reduce Motion
alternative. These are playback indicators, not measured audio spectra.

The notification scene is a real, opt-in **Study interval complete** local alert
on the Simulator’s Home Screen. Tapping it opens that account’s matching Focus
session. A genuine one-minute interval was used; the edit omits the wait and
shows only one delivered notification. A targeted retake uses the same account
and saved work. The first automation attempt did not successfully enable the
Form switch; the retake hits the switch itself, checks persistence and passes.
Nothing in this sequence is a simulated notification overlay.

The app’s Home Screen display name, audio attribution and shown lesson credit
now use DelaStudy. Bundle IDs, project names and account storage paths are kept
unchanged. Ordinary accounts on the separate iPhone 17 Pro Simulator were not
used or reset. This is Simulator evidence, not a physical-device test or public
release. `waffles-edit-manifest.json` records the 135-second edit and real source
code ranges; `waffles-narration.json` drives the companion document.

## Archived 2:48 editions

All public video filenames, presenter scripts and presentation titles now use
**DelaStudy**. A small publisher-credit line in the captured lesson is composited
to read "DelaStudy · original instruction". The brief navigation transitions
around that lesson are trimmed so this edit stays clean; scene durations and
the real study interactions are preserved. Technical project/source paths are
unchanged so the code references still resolve. This is a video branding update,
not a rename of the native app's data stores or project.

## Earlier webcam-ready edition

[DelaStudy-Webcam-Ready.mp4](DelaStudy-Webcam-Ready.mp4)
moves all eight code windows to the lower right, aligned 60 pixels above the
bottom edge. The white space above is left empty for your live webcam overlays;
there are no baked-in webcam placeholders. The handheld phone, code font size,
source excerpts, animations and silent 2:48 timing are otherwise unchanged.

At 1920 × 1080, a suggested three-person webcam arrangement is three 320 × 240
rectangles at `(760, 60)`, `(1100, 60)` and `(1440, 60)` (top-left coordinates).
That keeps them above the code and away from the phone. These are placement
suggestions for your recording software, not new content inside the video.
The [presenter notes](Code-presenter-notes.md) still match. Earlier versions are
preserved. `webcam-edit-manifest.json` controls this layout;
`webcam-verification.json` records the final media checks.

## Earlier handheld edition

[DelaStudy-Handheld-Walkthrough.mp4](DelaStudy-Handheld-Walkthrough.mp4)
keeps the same silent 2:48 walkthrough, white background and eight code windows.
It adds an original illustrated hand holding an iPhone 14 Pro-style dark-metal
frame: rounded screen corners, side buttons, front-camera detail, Dynamic Island
and a home indicator. A shared animation rig keeps the hand and phone together,
with small grip and holding movements that do not cover the app or code.

The Pro model is intentional: Apple's [iPhone 14 Pro specifications](https://support.apple.com/en-us/111849)
list Dynamic Island. This is presentation artwork around the original iPhone 14
Simulator recording, not a new recording from an actual iPhone 14 Pro or a filmed
human hand. No new hardware, Dynamic Island integration, or physical-device
behavior is being claimed. The [code presenter notes](Code-presenter-notes.md)
still match every scene. Earlier exports remain available below.

The local renderer now compiles with its code-native device/hand helper:

```sh
xcrun swiftc -parse-as-library scripts/render_showcase.swift scripts/showcase_handheld.swift scripts/showcase_diagrams.swift -o /tmp/lens-showcase-render
/tmp/lens-showcase-render render Demo/Showcase/handheld-edit-manifest.json OUTPUT.mp4
```

Raw source clips referenced by the manifest are local temporary files. The
renderer refuses to overwrite an existing output. `handheld-verification.json`
contains the measured properties of the final handheld export.

## Updated code edition

[DelaStudy-Code-Walkthrough.mp4](DelaStudy-Code-Walkthrough.mp4)
is the revised silent 2:48 landscape video. It keeps the same phone walkthrough
on a pure white background and removes the original presentation headings,
captions, branding, footer and progress rail. Eight Mac-style code windows
animate in beside the relevant app feature, with real source excerpts, syntax
coloring, original line numbers and highlighted logic. No app screen is covered.

[Code presenter notes](Code-presenter-notes.md) provide 363 spoken words and
suggested handoffs for M'hamed and two teammates, plus source references that
are not meant to be read aloud. These notes replace the earlier narration when
presenting the code edition. `code-edit-manifest.json` records the exact excerpt
ranges and popup timings; `code-verification.json` records measured output data.
The code-window artwork is composited for explanation, not an interactive Mac
editor or an in-app feature. The original videos below are preserved.

## Original edition

Prepared for M'hamed. Both videos are **2 minutes 48 seconds** and intentionally
silent, ready for your own narration.

## Files

- `DelaStudy-Walkthrough.mp4`: 1920 × 1080 landscape presentation, with
  actual app footage, concise section titles, and room to follow your narration.
- `DelaStudy-Screen-Recording.mp4`: the same edit as a clean, full-size
  portrait phone recording, without presentation text.
- [Timed narration](Narration-script.md): 349 words, split into sections matching
  the edit. Read the quoted paragraphs, not the headings. About 130 words per
  minute leaves room for pauses.
- [Plain narration](Narration.txt): the same spoken script without timestamps or
  stage directions, suitable for a teleprompter.
- `Preview.png`: a frame from the completed landscape video.
- `edit-manifest.json`: source ranges and final scene durations.
- `verification.json`: measured media properties of both exported files.

## Recording notes

Footage is from the actual native app running in iPhone 14 Simulator, not a
slideshow or reconstructed interface. The separate `MhamedDemo` test account was
created for filming. Its starter achievement was earned by answering a real
foundation practice round before filming; the Geometry study/practice shown in
the film earns additional actual XP. No levels, grades, streaks or users were
invented to populate the screens. Ordinary account data was not reset or used.

The edit removes account/password entry, test setup, and unnecessary waits.
Scene timing is adjusted to match the narration. The clean portrait version
contains the same real interactions as the presentation version. No voice,
music, system audio or third-party video audio is included. The YouTube resource
shows an embedded player; it is not an inserted copy of the publisher's video.

Demonstrated course paths cover selected material. AP preparation is not a claim
of official AP authorization, complete AP coverage, course credit, or state
endorsement. The civics lesson's source credits and a separate Algebra I module's
published partial mapping are shown. The civics course has no published registry
mapping, so the video does not claim one. Focus is an app study timer, not automatic control of other
apps' notifications. Sounds are optional, not a claim of guaranteed study gains.
Simulator footage is not evidence of physical-device or App Store readiness.

Typography uses the app's bundled Manrope font under its SIL Open Font License;
the existing course-image/source credits remain in the app. The local editor
uses AVFoundation and CoreText (`scripts/render_showcase.swift`), with no new app
runtime dependency. A capture run uses the opt-in showcase UI journey in
`FirstStateLensUITests.swift`; the regular app's production code was not changed
for the recording.
