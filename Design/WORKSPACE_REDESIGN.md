# First State Lens — study workspace redesign

This records the earlier October 24 workspace pass. The subsequent [image collection redesign](IMAGE_COLLECTION_REDESIGN.md) replaces procedural course graphics and refines the composition while retaining these workflows.

## Direction

Keep First State Lens. Its Delaware origin and perspective concept already belong to the product. The new identity uses two offset frames around a shared point: finding a useful relationship, then focusing on it. The icon is original vector artwork rendered by `scripts/render-brand-icon.swift` into an opaque 1024-pixel asset.

Three recurring decisions: offset frames as the mark, subject diagrams as course identities, and navy panels with a lime action surface for the current study. Supporting screens use compact rows, open reading, and a two-column library rather than repeating one large panel layout. Interface typography uses the native sans-serif; large monospaced numerals are reserved for session timing.

The principal interactions are the page heading's transition into a compact navigation title and the shared Focus session moving into a landscape Zen display without changing its timing state.

## Reference research — reviewed October 24, 2026

| Reference | Observed pattern | Adaptation | Identity retained here |
| --- | --- | --- | --- |
| [Linear UI redesign, 2024](https://linear.app/changelog/2024-03-20-new-linear-ui) and [mobile redesign, 2025](https://linear.app/changelog/2025-10-16-mobile-app-redesign) | Deliberate density, hierarchy, contrast, and navigation organized around workflows | Five primary activities; compact metadata; consistent navigation actions | Our course diagrams, color roles, and student workflows |
| [Things feature examples](https://culturedcode.com/things/features/) | Clear task rows; additional detail appears during editing | Lightweight agenda rows with a separate task editor for course, lesson, date, and estimate | Our study-to-task-to-session connection; no copied task UI assets |
| [Structured](https://structured.app/) | Tasks visibly relate to a daily schedule | Due work sorts before an unscheduled inbox; completion has its own view | A compact agenda rather than reproducing Structured's timeline |
| [Brilliant's learning overview](https://brilliant.org/help/using-brilliant/how-do-i-get-started-on-brilliant/) | Problems and visual explanation form the learning interaction | An interactive linear-function lab and original AP explanations with rubric self-review | Our original materials, crosswalk, and academic identity |

These are first-party design/product references, not evidence that our redesign improves grades. The Things features page includes older interface examples; it is used for interaction structure, not as a claim about its latest appearance.

## Implemented workflows

- Today → resume a lesson → save/edit a private note → practice → explanation → review latest incorrect or bookmarked questions.
- Plan → create/edit a task → optional course/lesson/date/estimate → Focus → pause/resume → landscape Zen → hide tasks → leave Zen without stopping the session.
- Notes → search saved writing → edit or delete with confirmation → reopen the original lesson. Drafts survive closing the editor.
- Library → search/filter by subject and level → save a course → inspect scope, syllabus, sources, and standards → study.
- Profile → change name, goal and banner → select interests → inspect awards → feature earned achievements → review a learning summary before native sharing.
- Explore → private school selection → verified-source links and personal goals; college planning notes and checklist; local discussion responses and shareable activities.

## Engineering decisions

The earlier iteration's domain content, school records, session engine, and synthesized audio were adapted into `main`; its visual implementation and naming were not imported as the new identity. Historical school verification dates remain visible. The 84-record school directory is explicitly partial. The 10 AP preparation paths each publish a selected-topic module rather than pretending to cover an entire course. Four standards entries distinguish partial or related coverage; there is no statewide endorsement claim.

Schema 1–3 progress migrates to schema 4 with an empty workspace. Optional workspace additions also accept earlier schema-4 snapshots. Existing course/objective IDs, bundle identifier, and storage path are retained. Session deadlines persist; monotonic time is used while the controller is active. Timer minutes never mark coursework mastered.

Audio textures are original synthesis. Silence is the default. The sound research page separates evidence for specific groups and tasks from product choices. The app cannot silence other apps; its Focus setup explains the user's iOS Focus configuration. In-app quiet mode removes nonessential answer/completion animation.

## Verification record

Verification is recorded in `STATUS.md`. UI automation uses a separate temporary progress file (`--ui-testing`) and never resets ordinary learner data. Screenshots and native result bundles are exported during the implementation review. Simulator results do not establish physical-device energy use, long-session audio behavior, or comprehensive VoiceOver usability.

See [the before/after review](Previews/README.md). A failed visual header review was corrected using actual scroll geometry and native navigation titles; presence-only accessibility assertions were strengthened with hittability. Appearance review uses actual dark and large-text overrides in Debug builds. The current source includes a second interactive lesson activity that distinguishes primary-source evidence from later historical context.
