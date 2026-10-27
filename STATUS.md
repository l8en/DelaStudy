# Product and technical audit

Updated October 26, 2026.

## Diagram-led team presentation

The new `Demo/Showcase/DelaStudy-Explained-2m15.mp4` replaces only the side panel
of the approved 135-second movie. It retains the exact phone footage, timing,
frame, onboarding, earned Waffles123 profile and native alert/tap. The approved
movie and earlier script retain their original SHA-256 hashes. Ten compact
diagrams and two source excerpts explain the workflows, with the upper-right
webcam space left clear. No app code, account data or Simulator state was changed
for this presentation revision.

The matching `DelaStudy-Team-Narration.docx` is 257 spoken words, with explicit
parts for M’hamed, Ibby and Sai and smaller action-level time cues. Its three
final pages were rendered and visually inspected; the document accessibility
audit reports no findings. The video remains silent, 1920 × 1080 H.264, exactly
135 seconds. All 21 chapter midpoints and representative full-size frames were
inspected. Equal-time comparison of 135 phone crops shows zero timestamp drift,
42.48 dB minimum / 47.40 dB average PSNR; the small pixel differences are normal
video re-encoding, not a claim of lossless identity. Details are recorded in
`Demo/Showcase/explained-verification.json`. Existing device/release gates below
remain; this media-only revision does not add new app-validation evidence.

## DelaStudy 2:15 showcase and notification routing

`Demo/Showcase/DelaStudy-Walkthrough-2m15.mp4` is a silent 135-second,
1920 × 1080 H.264 export with no hand, the retained iPhone 14 Pro-style frame,
white background and lower-right code windows. The separate three-page
`DelaStudy-Showcase-Script.docx` has scene timestamps and finer question/notification
cues; all final pages were rendered and visually inspected. The isolated
Waffles123 account is created on camera and completes the full onboarding flow.
The shown Geometry work earns actual XP; no progress is seeded.

Sound tiles now use a playback-gated Canvas timeline, distinct sound colors and
a static Reduce Motion alternative. Screenshot comparisons on iPhone 14 Simulator
found 2,282 changed glyph pixels while playing, zero while paused, and zero while
playing with the system Reduce Motion preference enabled (two samples per state).
Both targeted playback/relaunch UI runs pass. The original system preference is
restored after verification. These are playback indicators, not measured spectra.

One real local Focus-completion alert is shown on the Simulator Home Screen.
The passing targeted test checks saved opt-in switches, waits for a real
one-minute deadline, taps the native banner, and verifies the matching completed
session opens over a different active tab. Routing validates account and session
IDs and retains a tap until the account is ready. No mock alert overlay is used.
The first capture’s Form-row tap did not enable the switch; the retake hits the
switch control and confirms persistence. The final video omits the wait and shows
only one delivered notification. Ordinary accounts on iPhone 17 Pro were untouched.

The display name, Now Playing attribution and displayed short-lesson credit use
DelaStudy; stable bundle IDs and account storage paths remain. The app/test builds
and all 73 core tests pass. This is targeted Simulator verification, not a full
historical UI-suite rerun, a physical-device test, a public app release or a push
of the current dirty worktree. Earlier device, review and licensing gates remain.

## Bite-sized lessons and separate course resources

All 417 readings now open as three edited, plain-language steps, followed by
MCQ, fill-in-the-blank and matching practice. The 396 distinct authored topics
compile into 45–72 words per short lesson (about 59 on average). These are
selected key ideas, not mechanically clipped source excerpts or complete chapter
coverage. Examples and definitions target high-school understanding; no measured
grade-level or learning-effectiveness certification is claimed. The original
five-unit/30-activity course structures, 1,170 activity IDs, foundation assessments,
source chapters, diagrams, licenses, notes, accounts and historical XP remain.

Step changes save before navigation and resume after leaving/relaunching. Back
does not change XP; final completion uses the existing one-time award IDs.
Versioned new practice tests the ideas actually taught in the short steps.
Older saved rounds retain their questions and cleared count, with an optional
evidence review; explicit replay uses current questions without repeat XP.
Unmarking a reading remains available in its credits sheet. Geometry's first
lesson uses explanatory code-native angle diagrams with equivalent accessible
descriptions. Short directional/fade transitions respect quiet Focus and Reduce
Motion; large text scrolls rather than shrinking.

Every course has Lessons / Resources tabs. Resources provides four vertical,
animated dropdowns: Videos, Textbooks, Full readings, Curriculum & standards.
The records derive from that course's real linked catalog/foundation/framework
sources, with deduplication and honest empty categories. Resources never count
as activities or award XP. Textbooks open in the native in-app browser; complete
readings retain the offline, script-free mathematics/diagram reader and saved
scroll positions. Videos use the shared embedded player with retry/direct-link
recovery. Foundation videos and external readings have moved out of the lesson
sequence into the resource workflow; personal notes, interactive examples, AP
writing and original foundation assessments are retained. The video sound-pause
preference now applies on video entry, not on entering a text lesson.

Verification: 73 core tests in 13 suites pass (`/tmp/lens-bites-core-final.log`).
New coverage checks every short lesson, taught/check alignment, source membership,
unique HTTPS resource records, textbook deduplication, saved/clamped steps,
legacy workspace decoding, older quiz compatibility and preservation of prior
notes/reader positions/awards. The source compiler reproduces all 417 lessons;
project-file validation and `git diff --check` pass. The final unsigned generic
iPhone build passes (`/tmp/lens-bites-device-final.log`).

Eight distinct iPhone 14 / iOS 26.5 UI journeys have passing results across the
targeted runs: short-step/back/relaunch/practice, retained one-tap/Focus behavior,
resource category/browser/offline chapter/video entry, MCQ/blank/drag-and-tap
matching with correction and saved XP, foundation notes/review persistence,
offline mathematics/diagram scroll restoration, native dark/larger-text resource
and lesson layouts, and the native larger-text Focus offer. The four-journey
final regression bundle passes (`/tmp/Lens-Bites-Final-Regression.xcresult`).
The short-step and Focus journeys pass in `/tmp/Lens-Bites-Proof.xcresult`;
that earlier bundle also contains the superseded college-filter test failure,
which is corrected and passes in Final-Regression. Native appearance proof is in
`/tmp/Lens-Bites-Native-Proof.xcresult` and the passing Focus-appearance target in
`/tmp/Lens-Bites-Native-Accessibility.xcresult`. Intermediate checks also exposed
an outdated Safari Done-button assumption (iOS 26 uses Close); tests now scope to
the browser bar, explicitly choose the catalog level, and terminate the previous
test process before launch. This is targeted coverage, not a claim that the
entire historical UI suite was rerun.

Actual normal/dark/larger-text screens and a comparable before/after U.S. History
lesson were inspected. The test Simulator's original text size, light appearance
and Reduce Motion-off settings are restored. The latest ordinary no-test/no-reset
build is installed and open on iPhone 17 Pro Simulator. Ordinary progress storage
was empty before installation and remains unchanged; no ordinary account was
created or reset. UI tests use isolated credentials and files.

[Screen gallery and comparison](Design/Previews/BiteLessons/README.md) ·
[content, interaction and preservation decisions](Design/BITE_LESSONS_AND_RESOURCES.md).
Educator review of the new explanations, comprehensive VoiceOver traversal,
physical-device media/background behavior, credential review and the existing
noncommercial/share-alike release gate remain. Embedded-player entry/loading is
not proof of uninterrupted streaming or permanent external-link availability.
Simulator/unsigned compilation is not release readiness.

## Direct lesson entry and optional Focus offers

Today now puts the next lesson and a single Start lesson / Continue lesson action before Focus and material intake. It opens the actual reader/practice, not a course setup screen. Course pages put the same action above the photograph and outline. Opening a lesson remembers its course and unfinished activity; completed study paths retain a direct review action. Foundation assessments remain available from the course outline without competing with the main Today action.

A compact in-app notice offers **Enable** / **Disable** on first entry to an unstarted reading or foundation lesson. Enable starts the existing linked Focus timer without navigating away or opening Zen; Disable keeps Focus off. The notice does not block reading, repeat on revisits/source/note returns, or duplicate the offer for a reading's practice round. Ignored offers disappear when practice starts. Existing timers are retained, not overwritten. Manual timer controls remain in the lesson, with an On/Paused indicator when applicable. The video's sound-pause preference is respected when enabling Focus from a foundation lesson.

The per-account **Offer Focus for new lessons** switch is at Profile → Settings → Focus & Zen → Lessons, enabled by default. Turning it off does not auto-enable Focus or change existing timer preferences. New optional workspace keys preserve older records; existing reading completion, awarded XP, scroll position, check progress and foundation study evidence prevent old lessons being treated as fresh. Starting or declining a lesson does not award learning XP. These are in-app Focus sessions, not permission to silence other apps or automatic control of iPhone system Focus.

Verification: 67 core tests in twelve suites pass (`/tmp/lens-lesson-entry-core.log`). Five new tests cover first-entry/pair identity, opt-out and timer preservation, historical study evidence, continuing the right unfinished activity, backward decoding and account-scoped persistence. Two new iPhone 14 UI journeys pass in `/tmp/Lens-Lesson-Entry-Proof.xcresult`: one-tap start/continue, both Focus choices, relaunch without repeat offers, setting persistence, foundation/note-return behavior and retaining a running timer across lessons. Three regression journeys pass in `/tmp/Lens-Lesson-Regression.xcresult`: MCQ/blank/match and reading progression/relaunch, lesson notes and assessed review, and reading-to-manual-Focus context. Initial UI-test failures exposed inherited container accessibility identifiers and taps on a switch's label instead of its native thumb; child identifiers and switch targeting were corrected before the passing proof run.

The native larger-text/dark/Reduce Motion journey also passes (`/tmp/Lens-Lesson-Accessibility.xcresult`), bringing this pass to six distinct UI journeys. Actual rendered screens were inspected, including both fully visible prompt actions and the one-tap entry at accessibility text sizes. The test Simulator's original text size, light appearance and Reduce Motion-off values were restored. The latest unsigned generic iPhone build passes (`/tmp/lens-lesson-device-final.log`), project-file validation and `git diff --check` pass, and the normal no-test/no-reset-flag build is installed and open on iPhone 17 Pro Simulator. Ordinary progress storage remains empty as before installation; no ordinary account was created or reset.

[Rendered screen comparison and settings location](Design/Previews/LessonEntry/README.md). Ordinary account data is preserved; test accounts/files are separate. Physical-device notification/background audio, full VoiceOver traversal, credential security and educator review remain separate gates. Simulator/unsigned compilation is not release readiness.

## Student lens · guided setup and simpler settings

This update supersedes the optional three-step setup and decorative entry core described in the earlier desk checkpoint below.

- Username/password creation now leads directly into seven account-scoped stages: year, study goal, subjects, academic route, optional school, study rhythm, and an editable course/plan preview. The chosen course, daily goal, work/break lengths and sound configure real app behavior. An optional first task is created only by explicit choice. School remains private by default; no new permissions are requested or audio played during setup.
- Every required choice and stage is saved before advancing. Login after a relaunch resumes the unfinished draft. Completion applies the plan and clears the draft atomically. Existing accounts without a draft are not forced through setup, and password recovery retains the same draft/account. Reopening preferences from Settings creates a cancellable edit draft without deleting any learning data.
- The original optical instrument now opens its aperture and fills its ring with setup progress. Today's instrument shows saved Focus minutes against the student's goal and opens the real Focus workflow. No idle spinning or random sphere was added. Motion uses brief progress/selection springs and short directional transitions, with static geometry/fades under Reduce Motion. The redundant school-search graphic and repeated setup subtitle are removed.
- Settings is five destinations plus sign-out: Account, Study preferences, Focus & Zen, Notifications & Lock Screen, About & data. Advanced long-break/feedback options and the destructive per-account reset are one level deeper. The active-study screen no longer contains the entire settings wall. Notification changes reschedule/cancel the active session alert; duration changes apply to the next session. iOS system Focus remains user-controlled.
- Number/dash prefixes are removed from native activity/check navigation labels. Source text, mathematics, citations and stable identifiers are retained. Choice states use both contrast and checkmarks; large text reflows into single columns and stacked summaries, with the main action in a safe-area dock.

Verification: 62 core tests in eleven suites pass (`/tmp/lens-student-core-final.log`), including required-choice validation, actual route/subject matching, preservation of notes/materials/learning records, no manufactured XP, optional-task idempotence, old-account decoding, draft round trips and title cleanup. Eight distinct iPhone 14 / iOS 26.5 UI journeys pass across `/tmp/Lens-Student-Flow-Proof.xcresult`, `/tmp/Lens-Student-Regression.xcresult`, `/tmp/Lens-Student-Final.xcresult` (materials/review journey), and `/tmp/Lens-Student-Native-Accessibility.xcresult`. These cover signup → resumed setup → personalized desk → Focus defaults, cancellation, school selection, multiple-account isolation, retained material/notes/card persistence, planner/landscape Zen, dark appearance, and actual native larger-text/Reduce Motion settings. An intermediate flow check exposed taps landing during a full-width transition or beneath the action dock; the transition was shortened and tests now require fully visible choices. The complete flow passes again in Flow-Proof. The native system settings are restored after verification; environment-only modal previews are not counted as proof of actual larger text.

The unsigned generic iPhone build passes (`/tmp/lens-student-device-final.log`). The final large-text plan polish passes again in `/tmp/Lens-Student-Layout-Final.xcresult`. Actual rendered normal/dark/accessibility-sized screens were inspected; the test Simulator's original text size, appearance and Reduce Motion settings are restored. The normal no-flag build is installed and open on iPhone 17 Pro Simulator at Create account / Log in, with its ordinary progress directory still empty as before installation; no ordinary account was created or reset. [Screen gallery](Design/Previews/StudentSetup/README.md) · [design and state decisions](Design/STUDENT_LENS_SETUP.md). Ordinary accounts and study files are preserved; UI testing uses separate accounts/files. No hosted accounts, remote school verification, public deployment or fabricated course accreditation was introduced. Physical-device behavior, comprehensive VoiceOver traversal, credential security review and educator review remain separate gates; Simulator success is not release readiness.

## Lens desk · PDF-reference implementation

All seven screenshots in the user's `ui-3.pdf` were rendered and inspected. Their setup, school-discovery, four-way material-intake, branded 3D guide, and tabbed-profile patterns were adapted rather than their artwork copied. The blue logo tile on the photographic profile banner is removed. The actual iOS launcher icon is unchanged.

The visual direction is a warm-paper optical study desk: Manrope, midnight/cobalt controls, a restricted chartreuse highlight, authentic course images, and an original faceted 3D optical core. The core is calculated from projected vertices, shaded faces, aperture geometry, and an XP/setup-progress arc. It supports direct rotation and a 44-point pause control; scene inactivity, navigation/offscreen state, quiet Focus, and native Reduce Motion suspend continuous animation. No generated bitmap, copied mascot, downloaded 3D model, or rendering dependency was added.

Delivered workflows:

- Today exposes PDF/text file, pasted text, YouTube, and photo-to-text entry points; existing course continuation, planner, Focus, and review remain connected below them.
- PDFKit extracts selectable PDF/plain-text content; Vision recognizes photo text locally. Students inspect/edit before saving. Limits are explicit (20 MB/60-page document, 30 MB photo, 60,000 source characters); oversized input is rejected rather than silently truncated. Original documents/photos are not retained. Failed/empty recognition is recoverable by retrying or pasting.
- Up to 60 private materials per account keep source text/video, editable notes, and up to 100 student-authored recall cards together. Search, source editing, notes saving, card creation/editing/deletion, answer reveal/self-rating, material deletion, contextual Focus, explicit sharing, and relaunch persistence are implemented. Self-rated cards do not earn assessed mastery or XP.
- An optional, reversible three-step setup saves academic year, study route, and school. Choices include foundation, honors support, selected-topic AP preparation, introductory college, and SAT/ACT foundation support—not invented full test curricula. The saved route initializes Library's level filter; the user can change it.
- School search keeps results visible over the keyboard, supports name/town/alias and county/type filters, and retains home/outside/skip choices. The existing 84-record partial directory is unchanged. No location permission, unverified distance, classmates, enrollment verification, or school partnership is invented.
- Profile has Record / Stats / Materials / School tabs, private academic context, real saved-session statistics, original achievements, and reviewed study invitations/summary sharing. Existing circular photo/XP, account editing, sign-out, and per-account progress reset remain.
- The shared course/personal video player uses a bundle-ID HTTPS base/referrer, privacy-enhanced inline embeds, IFrame error reporting, a bounded readiness timeout, unobscured controls, direct-link recovery, reload, and teardown when dismissed. Video availability remains YouTube/publisher controlled.

Preservation: additive optional workspace fields retain schema-4 compatibility. Existing accounts, Keychain migration, course/objective/activity identifiers, original assessments, and saved academic work are preserved. No ordinary account was reset. UI tests use isolated accounts and files; the import pipeline's synthetic PDF/photo fixture controls require two explicit Debug test flags and are absent from Release.

Verification so far: 56 core tests in ten suites pass (`/tmp/lens-desk-core-handoff.log`), including new URL/input validation, no-manufactured-XP, backward decoding, and account-isolated material/context persistence. Ten distinct iPhone 14 / iOS 26.5 UI journeys pass across `/tmp/Lens-Desk-Initial.xcresult`, `/tmp/Lens-Desk-Connected.xcresult` (academic setup journey), `/tmp/Lens-Desk-Recall-Proof.xcresult`, `/tmp/Lens-Desk-Regression-Final.xcresult`, `/tmp/Lens-Desk-Handoff.xcresult`, and `/tmp/Lens-Desk-Reduced-Motion.xcresult`. They cover new setup/import/notes/recall/edit/delete/relaunch, compact account entry/header, course-to-Focus, dark/larger-text, multiple accounts, planner/landscape Zen, manual animation pause, and native system Reduce Motion. The system setting was restored to its original off value. Actual rendered screens were inspected; keyboard obstruction, hit regions, search hierarchy, placeholder contrast, and large-text reflow were corrected during review.

The latest unsigned generic iPhone build passes (`/tmp/lens-desk-device-final.log`); `git diff --check` and project-file validation pass. The final video journey also passes in `/tmp/Lens-Desk-Video-Recovery.xcresult`: editable PDF/photo fixtures, invalid-link correction, a loaded inline player, a delivered play request with native player controls, and changing the source to an unavailable video with working recovery UI. This does not establish sustained streaming on all networks. The normal app is installed and running without test/reset flags on iPhone 17 Pro Simulator; the new account-entry screen was visually inspected. Its ordinary progress directory remains empty, as before installation; no account was created, replaced, or reset for the handoff. [Screen comparison and gallery](Design/Previews/LensDesk/README.md), [every reference-page decision](Design/LENS_DESK_REFERENCE.md).

Limits: PDF/photo pipeline tests use controlled fixtures, not an exhaustive Files-provider/camera/language audit. No remote community, referral currency, hosted accounts, new full SAT/ACT course, or geolocated friend discovery was added. Continuous video streaming, physical-device OCR/energy/thermal/background media, full VoiceOver traversal, and educator review remain separate checks. Simulator/unsigned compilation is not release readiness.

## Multiple local accounts

The one-account restriction below is superseded. Create account accepts additional unique usernames without replacing existing users. Login matches the entered username case-insensitively to its own salted password verifier. Only duplicate handles show “That username is taken. Try another.”

An atomic device-only Keychain vault holds credential records with stable UUIDs. Each UUID routes to its own `Accounts/<UUID>/progress-v1.json` in Application Support. Notes, courses, tasks, XP, photos, school preferences, sounds, and Focus state come from that account's snapshot. The former single credential migrates to the vault; only its owner (or the first account when no credential ever existed) can inherit the legacy study file. Existing account files take precedence over legacy data. The original study file is retained as a migration backup.

Sign-out saves drafts, pauses that account’s Focus interval, stops audio/alerts/Live Activity, and clears in-memory navigation and study state. Late reader saves and old Focus controllers are account-fenced. A single Live Activity coordinator serializes transitions across accounts. Widget links wait for authentication. Reset learning progress now names—and affects—only the signed-in account.

Password recovery targets the entered username, authenticates the device owner through iOS, and replaces only that verifier while retaining the account UUID and study data. These remain local accounts, not hosted identities, cross-device sync, separate iOS sandboxes, or independently encrypted per-account databases. Device-owner recovery and physical-device security behavior remain separate review gates.

Verification: 52 core tests in nine suites pass (`/tmp/lens-multi-account-core.log`), including account-file isolation and explicit/idempotent legacy import. Three iPhone 14 UI journeys pass in `/tmp/Lens-Multi-Accounts.xcresult`: three-account signup/switch/relaunch/password/task/XP isolation, legacy credential migration, and duplicate-handle/full-reset behavior. Three regression journeys pass in `/tmp/Lens-Multi-Regression.xcresult`: lesson/notes/review, planner/Focus/landscape Zen, and photo import/persistence/removal. Rendered account profiles/plans were inspected. Latest handoff/device-build results are recorded below after completion. No ordinary account was reset for this update.

Final handoff: the multiple-account journey passed again alongside the reading-to-contextual-Focus journey in `/tmp/Lens-Multi-Handoff.xcresult` (seven distinct UI journeys across this pass's three bundles). The unsigned generic iPhone build passes in `/tmp/lens-multi-device-final.log`; `git diff --check` passes. The normal, no-test/no-reset-flag app is installed and running on iPhone 17 Pro Simulator. Its Create account / Log in screen was visually inspected. [Isolation screenshots](Design/Previews/MultiAccount/README.md). Physical-device owner recovery and security review remain outstanding; no hosted account service or release readiness is claimed.

## Earlier account entry and requested local reset

Create account and Log in are now explicit, switchable modes rather than a form chosen only by the presence of credentials. Switching modes clears the password/error state and reconstructs the native secure field with the correct entry semantics. Missing-account and duplicate-account errors guide users to the other mode; signup does not overwrite an existing local account. The app still supports one private account on this iPhone, not hosted identities or cross-device login.

At the user's explicit request, the iPhone 17 Pro Simulator's ordinary credential, profile, and study records were reset. The old study records were backed up first at `/tmp/first-state-account-backup.3xACH0/FirstStateLens/progress-v1.json`. Credential verifiers were not exported. The app's ordinary progress directory is empty after reset and its normal, no-flag launch shows Create account and Log in. This requested reset supersedes the earlier preserved-35-XP handoff below; it was not an accidental migration or overwrite.

The one-shot `--reset-local-account` development switch is compiled only for Debug Simulator builds. With `--ui-testing`, it targets only the isolated test credential/progress/avatar locations. It is absent from physical-device builds.

Verification: 50 core tests pass (`/tmp/lens-account-choices-core.log`); two iPhone 14 UI journeys pass in `/tmp/Lens-Account-Choices.xcresult` (signup/login/duplicate prevention/full reset to zero XP, and existing identity/header regression). Large-text and dark create/login forms pass and were rendered for review in `/tmp/Lens-Account-Appearance.xcresult`. The unsigned generic device build passes (`/tmp/lens-account-choice-device.log`). No physical-device or hosted-account verification is implied.

## Interactive practice and identity update

The Today wordmark capsule and numbered section labels were removed. The profile entry is only a circular learner portrait/photo and XP ring, with the iOS 26 shared toolbar capsule hidden. The default academic portrait is original SwiftUI artwork. Manrope is bundled under SIL OFL and applied to reusable, Dynamic Type-aware app typography.

Username/password setup replaces default-name onboarding. This is a private on-device profile, not a hosted account. Credentials use a device-only Keychain record with a random salt and PBKDF2-HMAC-SHA256 verifier; raw passwords never enter progress JSON. Sign-out, relaunch sign-in, and device-owner password-reset recovery are implemented. Existing learning progress remains in place. Test identity and test progress storage are isolated from ordinary data.

The 585 former written recall activities now open three-question practice rounds: MCQ, typed blank, and drag-to-match with a tap alternative. All 417 distinct readings have an offline check bank. Source-excerpt checks and a small set of original concept checks are graded, with retries, animated answer feedback, saved question position, and one-time XP. Existing activity IDs and old written responses are retained. These checks do not contribute to foundation mastery or claim full conceptual assessment. Automatically selected blanks still require educator review.

See [design, security, and source boundaries](Design/INTERACTIVE_PRACTICE_AND_IDENTITY.md). Verification results below identify completed runs for this update.

### October 25 verification

- `swift test`: 50 tests in eight suites pass (`/tmp/lens-interactive-core-release.log`). New coverage checks every reading's bank, distinct answer choices, case/spacing normalization, and compatibility of interactive progress with earlier written responses.
- Three iPhone 14 UI journeys pass in `/tmp/Lens-Interactive-Workflows.xcresult`: complete reading/MCQ/blank/actual drag/tap matching and relaunch/XP; the existing lesson/notes/review flow; and private-profile creation, compact hit target, wrong-password recovery, sign-out, and relaunch sign-in.
- Four iPhone 14 UI journeys pass in `/tmp/Lens-Interactive-Visual-Final.xcresult`: dark and larger-text app navigation with keyboard; resuming an unfinished question round at larger text; identity/header; and photo import/relaunch/removal. There are six distinct journeys across these runs; the identity journey repeats. Rendered screens were inspected, not only compiled.
- The final unsigned generic iPhone build passes (`/tmp/lens-interactive-device-final.log`). This is compilation evidence, not a signed physical-device install.
- Final reading/MCQ/blank/actual drag-and-match/XP/relaunch and identity journeys pass again in `/tmp/Lens-Interactive-Handoff.xcresult`, including the scrolled native header's reachable circular profile control. The settled feedback, matching, and compact header were visually inspected. [Screenshot gallery](Design/Previews/Interactive/README.md).
- The final ordinary app is installed and running without test flags on iPhone 17 Pro Simulator. It presents username/password setup because this learner has no local credential yet. The progress file's SHA-256 is identical before and after reinstall/launch; the existing two attempts, one completed practice session, and 35 practice XP were not replaced by test data. `git diff --check` passes; no commit or public deployment was performed.
- Physical-device password recovery/AutoFill behavior, full VoiceOver traversal, an actual system Reduce Motion toggle, and educator review of selected blanks remain unverified. Earlier background-media/device gates also remain. The Keychain-survives-reinstall branch is implemented but was not exercised by uninstalling an ordinary learner's app.

## Implemented scope

First State Lens is a native SwiftUI study workspace with an original offset-frame identity, navy/cobalt controls, and a source-traceable image collection. Today, Library, Plan, Review, and Explore form the five primary destinations. Profile, achievements, College, school resources, Community, and sound controls are reachable through that structure.

- 39 paths: 17 high-school foundations, 12 introductory college paths, and 10 independent AP preparation modules.
- Five selected units and 30 activities in every course: 15 readings and 15 interactive practice rounds per path, 1,170 course activities total. The 417 distinct readings include 357 OpenStax sections, 15 literary primary-text chapters, and 45 original Geometry/Java/personal-finance mini-lessons. Related courses reuse appropriate readings; this is not a claim of 1,170 distinct lectures or full year-long/AP coverage.
- 46 original foundation lessons, 112 original multiple-choice questions, and 10 AP written tasks with self-review rubrics remain available separately.
- The original 12 video lessons retain inline YouTube embeds and direct fallback links.
- 35 bundled photographic/archival/technical assets cover all 39 courses, with per-file provenance and licensing, individual crops, an image inspector, and searchable credits. Images total 7.83 MiB and require no runtime image service.
- Procedural subject-cover decoration was removed. The interactive linear-function lab, source-versus-context activity, actual graphs, and original achievement glyphs remain.
- Searchable, filterable, saved courses; lesson-level scope, curriculum links, and standards inspection.
- Planner task creation, editing, completion, deletion and undo, with optional date, time estimate, course, and lesson.
- Saved lesson notes, persistent drafts, note search, editing/deletion, and return to the source lesson.
- Latest-incorrect-answer review and independent question bookmarks.
- Configurable Focus work/break intervals, pause/resume, relaunch recovery, optional notifications, and session history.
- Landscape Zen with three static environments, hideable tasks, configurable display options, and independent exit/session-end actions.
- Seven sound/silence options using original synthesis, favorites, level control, and a separate research view.
- System photo picker, private resized profile photo, editable name/goal/banner/interests, animated XP ring and earned level arrival, inspectable awards, featured earned achievements, and student-controlled sharing summaries. Valid study activities earn 10 XP once; completion is not assessed mastery.
- Native ActivityKit/WidgetKit Lock Screen timer, MediaPlayer Now Playing/remote handlers, resumable audio, and a gentle one-minute reset. iOS 17+ supports iPhone 14 without requiring Dynamic Island.
- A partial 84-record Delaware school directory; private school preference, goals, subject links, and assessment date.
- College/career planning notes, counselor questions, a saved checklist, and official resource links.
- Local discussion responses, challenge state, and shareable study activities. No hosted community or fabricated engagement.

## Architecture and preservation

SwiftUI iOS 17+; no third-party runtime dependencies. Domain/content/validation/mastery live in FirstStateCore. The existing bundle identifier, progress path, and course/objective IDs remain intact.

Schemas 1–3 migrate to schema 4 with a default workspace. Optional added fields also accept earlier schema-4 workspace snapshots. Writes remain atomic with explicit errors. Existing in-app academic progress is preserved.

Focus projects from persisted deadlines, with a monotonic anchor during a controller lifetime. Pauses do not count toward elapsed work; returning after a long absence settles only one interval. Focus minutes do not demonstrate lesson mastery or create question accuracy.

The app controls its own nonessential interaction animation during quiet Focus. Device-wide notification rules remain in the user's iOS Focus configuration. The app does not assert that other apps were muted or that system Focus status is known.

Modern scroll geometry drives header transitions on iOS 18+. An older geometry-preference fallback remains for iOS 17; the installed runtime used for verification is iOS 26.5.

## Educational and source boundaries

AP paths publish selected-topic coverage rather than full AP courses, units, exams, credit, or predicted scores. Their explanations, four-question practices, written tasks, and rubrics are original.

Four standards entries identify three partial mappings and one related-topic mapping, with sources, rationale, and review status. These do not establish comprehensive Delaware alignment or state endorsement. Educator review is outstanding.

School records retain their recorded October 19 verification dates. The directory gateway was rechecked October 24, but every individual school was not reaudited in this pass. Coverage is partial, including specialist grade bands and the complete private-school list.

Sound research is specific to participant groups and laboratory tasks; no universally optimal noise or validated app learning effect is claimed. Audio environments are synthesized rather than field recordings. The research view identifies the sources and limits.

## Deeper-study verification

- `swift test`: 48 tests in eight suites passed (`/tmp/lens-core-release-check.log`). Coverage includes all 39 five-unit/thirty-activity mappings, source/local content availability, local diagram references, old schema-4 decoding, one-time XP, studied/mastery separation, reading/recall ID stability, level thresholds, and the personal-finance selection.
- Twelve UI regression journeys passed on iPhone 14 / iOS 26.5 in `/tmp/Lens-DeepStudy-iPhone14-Final.xcresult`. Six targeted journeys passed in `/tmp/Lens-DeepStudy-Polish.xcresult`, including fixes to navigation stability, reader horizontal overflow/scroll restoration, photo import/removal/persistence, and earned level arrival. The source/diagrams were visually inspected, including the restored reading position.
- A real one-minute Focus interval spent in the background passed: return showed interval completion and stopped audio. The independent background round trip also passed playback pause/resume and timer pause/relaunch. These are bounded Simulator checks, not a long-running hardware audit.
- The dark reader and gentle reset passed. A fifteenth distinct journey for finance reading/profile layout passed with iOS's actual `accessibility-extra-large` text setting in `/tmp/Lens-DeepStudy-SystemLarge.xcresult`, and passed again after profile reflow in `/tmp/Lens-DeepStudy-Large-Reflow.xcresult`. The setting was restored afterward.
- Lock Screen countdown was visibly rendered on the ordinary iPhone 14 Simulator; Dynamic Island is not required. OS MediaRemote logs accepted the app's Brown noise title, Playing state, and supported commands. The runtime exposed empty system media-control module content, so actual remote-command delivery/presentation is **not** reported as verified. Keep physical-device media controls and long-running playback as release gates.
- The unsigned generic iOS-device build passes with the iOS 17 deployment target (`/tmp/lens-device-release-check.log`). No physical iPhone was reachable: recorded device connections were disconnected/unavailable. Compilation does not establish a successful signed device install.
- Final normal-size photo import/persistence/removal and background/timer round trips passed again in `/tmp/Lens-DeepStudy-Handoff.xcresult` after accessibility reflow; the unsigned device build passed again in `/tmp/lens-device-handoff.log`. [Actual screen gallery](Design/Previews/DeepStudy/README.md).
- Today → unit reading → contextual Focus is the sixteenth distinct tested journey. It passed alongside original lesson/notes/practice persistence and the reading/recall/relaunch flow in `/tmp/Lens-DeepStudy-Connected.xcresult`. The primary Today continuation now leads into the expanded material, not only the old foundation module.
- Final Simulator and unsigned device builds passed (`/tmp/lens-shipping-simulator.log`, `/tmp/lens-shipping-device.log`). Ordinary progress was checked before the final reinstall: 35 practice XP and one completed session, schema 4. Simulator test records and photos use separate storage. Changes remain uncommitted; no public deployment was performed.
- Final onboarding-placeholder contrast correction also compiled for Simulator/device (`/tmp/lens-contrast-build.log`, `/tmp/lens-contrast-device.log`). The normal app was reinstalled and launched without test flags on iPhone 17 Pro and iPhone 14 Simulators. The existing 17 Pro learner's 35 XP / one session were rechecked after reinstall; the new iPhone 14 ordinary store remains separate from test fixtures.
- See [implementation and release boundaries](Design/DEEP_STUDY_AND_IPHONE.md), including noncommercial OpenStax licensing and outstanding educator/device review.

## Earlier collection verification

- `swift test`: 40 tests in seven suites passed, including complete course-image mappings, provenance fields, immediate local JPEG decoding, maximum dimensions, bounded asset size, and related-subject reuse. Latest output: `/tmp/lens-collection-core-final.log`.
- Six UI journeys passed on iPhone 17 Pro in `/tmp/Lens-Collection-Final.xcresult`: actual appearance/keyboard review; the new collection/inspection/save/relaunch/credit-search flow; compact header/profile/school/awards; lesson/note/practice/review persistence; planner/Focus/landscape Zen recovery; sound playback and college-note persistence.
- Two appearance/collection journeys passed on iPhone 17e in `/tmp/Lens-Collection-Small.xcresult`. Actual dark and accessibility-sized presentations, the task editor with keyboard, full image records, and saved-course persistence were exercised.
- Three final-polish journeys passed on iPhone 17 Pro in `/tmp/Lens-Collection-Polish.xcresult`, including a seventh distinct UI journey for chemistry/computing search, keyboard submission, level filtering, source inspection, and returning to the preserved query/filter. The library search prompt now uses an explicit readable color rather than the low-contrast native placeholder.
- The final collection and header/profile/school journeys passed again after the focal-point framing correction in `/tmp/Lens-Collection-Crop-Final.xcresult`. The final normal learner launch retains 35 XP and one completed practice session; its screenshot is included in the [current comparison gallery](Design/Previews/Collection/README.md).
- Actual dark/larger-text/keyboard review passed once more on the final crop implementation in `/tmp/Lens-Collection-Appearance-Final.xcresult`; the gallery's appearance screenshots were refreshed from that run.
- Source assets were visually inspected in contact sheets and rendered in native Library, Today, course detail, image-record, and Profile screens. An oversized image hit region that intercepted the image-caption button was fixed and the full inspection workflow passed afterward.
- The image cache is capped at 24 MiB / 16 decoded entries. Local decoding and visual scrolling checks are not a physical-device frame-rate, memory-pressure, or energy benchmark.
- No progress schema, bundle identifier, course IDs, or academic scoring rules changed in the collection pass. UI tests continue to use an isolated progress file.

### Earlier workspace checkpoint

- swift test: 37 tests passed in six suites, covering original scoring and mastery, content, rewards, migration/persistence, Focus deadlines/pauses, AP material, directory references, standards links, planner ordering, review behavior, and older workspace compatibility.
- Five UI journeys passed on iPhone 17 Pro Simulator in /tmp/FirstState-Workspace-Final.xcresult: appearance review; profile/school/awards; lesson/notes/review persistence; planner/Focus/landscape Zen recovery; synthesized sound playback and college-note persistence.
- After visual review exposed an invisible toolbar item, header rendering was replaced with native navigation titles driven by actual scroll geometry. The targeted header/profile/school test passed in /tmp/FirstState-Header-Proof-2.xcresult, including a hittability assertion and a visibly rendered compact title.
- The final lesson/notes/review journey passed again in /tmp/FirstState-Lesson-Final.xcresult after adding the source-reasoning activity.
- Two appearance/navigation journeys passed on the smaller iPhone 17e Simulator and passed again in /tmp/FirstState-Small-Final.xcresult after tightening screenshot synchronization. Dark appearance, accessibility-sized text, the keyboard/task editor, and school-selection dismissal were actually exercised.
- Main text color pairs were calculated using the WCAG relative-luminance method. Amber text was darkened after its original subject surface pairing measured below 4.5:1.
- Native icon generation produces an opaque 1024 × 1024 PNG. Background audio is represented as an Info.plist array.
- UI automation uses its own temporary progress file and does not reset ordinary learner data.
- git diff --check passes. Changes remain uncommitted on main.
- The ordinary app was reinstalled and launched on iPhone 17 Pro without test arguments. The existing learner's 35 XP remained intact. Before/after, compact-header, and landscape-Zen screenshots are retained in Design/Previews.

## Remaining checks and limitations

Physical-device energy/thermal behavior, long-running background audio, interruptions/routes, notification delivery, comprehensive VoiceOver traversal, and educator content review remain unverified. Reduce Motion branches were inspected in source; an actual OS Reduce Motion toggle was not automated in this pass. Simulator evidence does not establish release readiness.

Expanded reading completion is self-marked; interactive reading checks are graded source-comprehension exercises, not demonstrated foundation mastery. The existing streak counts completed practice sessions and is labeled a practice streak. OpenStax adaptations are noncommercial/share-alike; permission or replacement and a release licensing review are required before commercial distribution.

The community is local with native sharing, not a synchronized social network. School affiliation is self-selected. The standards crosswalk and course content are limited to published coverage. Media availability remains controlled by YouTube.

Current design research, sourcing decisions, and workflow checklist: [Design/IMAGE_COLLECTION_REDESIGN.md](Design/IMAGE_COLLECTION_REDESIGN.md). Individual image credits and reproduction: [Design/COURSE_IMAGE_CREDITS.md](Design/COURSE_IMAGE_CREDITS.md). The earlier implementation remains documented in [Design/WORKSPACE_REDESIGN.md](Design/WORKSPACE_REDESIGN.md).
