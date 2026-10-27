# Deeper study and native iPhone integration

October 24, 2026. Implemented on the existing main worktree; no account service, public deployment, or commit.

## Product direction

Students need enough authentic material to study, retrieve it from memory, and return to unfinished work. The fieldbook uses numbered units, open reading surfaces, and a separate assessment record. A personal photograph and a restrained XP ring make the learning record recognizable without inventing achievement.

- Each of the 39 existing courses has five selected units. Each unit has three readings and three corresponding written recall labs: 195 units / 1,170 course activities.
- These are 585 reading placements and 585 recall placements, not 1,170 distinct lectures. Related high-school, college, and AP paths reuse appropriate sources. There are 417 distinct readings: 357 complete OpenStax sections, 15 historical literary chapters, and 45 original Geometry/Java/personal-finance mini-lessons with worked examples and answer checks.
- Original assessments, IDs, saved attempts, notes, and mastery remain separate. Reading/lab completion is self-reported study, not a grade, credit, or demonstrated academic mastery. AP units are selected preparation, not authorized courses or complete exam coverage.
- Navigation snapshots the selected activity. Completing a reading cannot mutate the active navigation destination to the next item. Written drafts, completion, first-earned XP, and reading positions persist independently.
- Today's main continuation enters unit study directly; the original assessed foundation remains a separate action. A reading's timer control opens Focus with that reading's title rather than linking an unrelated foundation objective.
- Each valid activity earns 10 XP once. Unmarking allows restudy without farming or revoking XP. Each 100 XP advances a level; actual earned changes animate the ring and a dismissible level arrival. Reduce Motion removes those transitions. Two new awards distinguish a full studied unit and a thirty-activity path from foundation mastery.

## Content construction and license boundary

`scripts/build_study_curriculum.py` downloads first-party OpenStax HTML at build time. The chapter-level selection plan is explicit. The importer retains text, native MathML, worked examples, figure captions/credits, and local illustrations. It unwraps image buttons before removing scripts and interactive web controls. The app reader disables content JavaScript. Sources open separately; offline reading does not require a network request.

The catalog records source URL, title, book, content version, word count, recall prompts, and license. Attribution and free textbook links appear in every adapted reading footer. Current OpenStax licenses were read from each book's source metadata, not assumed from older licensing.

**The bundled OpenStax adaptations are noncommercial/share-alike content. Commercial distribution requires permission or replacement and a fresh license review.** This local educational build is not a clearance for monetization. Preserve the reading attribution and license notices when redistributing permitted adaptations.

Literary chapters are by Douglass, Hawthorne, Melville, Alcott, and Wharton, with public-domain-in-the-USA status and links to the complete Gutenberg editions/terms. Historical-language warnings precede those texts. Distribution elsewhere needs jurisdiction-appropriate copyright review. Original Geometry/Java/personal-finance mini-lessons are distinct from linked references; Oracle/CFPB prose is not copied. Java coverage is selected long-established language fundamentals, not a complete current AP framework implementation. The high-school finance selection covers spending, saving, credit records, everyday borrowing, and college costs; corporate-finance readings were replaced during the editorial audit. Financial examples are explicitly hypothetical, not current offers or individualized advice.

Acquisition uses Python with BeautifulSoup/lxml only as development tooling. No Python or third-party dependency ships in the app. Rebuild:

```sh
python3 scripts/build_study_curriculum.py
```

Use a virtual environment containing `beautifulsoup4` and `lxml`. Download cache: `/tmp/first-state-curriculum-cache`. `--extras-only` refreshes original/literary selections against an already built OpenStax catalog. Do not use it to claim a fresh OpenStax verification.

## Profile photographs

The system Photos picker grants access only to the chosen asset. A transformed thumbnail is capped at 768 pixels and re-encoded as JPEG without source EXIF/GPS. The original photo is untouched. Only a UUID filename enters progress JSON; the private copy is in Application Support. Save failure keeps the old photo. Replacement/removal touches only validated app-owned UUID files. Photo editing is separate from the cancelable name/goal form so Cancel does not conceal an immediate photo change.

The profile keeps a compact horizontal identity at regular sizes. Accessibility sizes put photo/edit controls on their own row and give identity, XP, and learning metrics full-width vertical space. This was verified with the Simulator's actual larger-text setting, not just an injected preview environment.

## Focus and audio

- Existing editable work/break durations, explicit pause/resume, optional alerts, and deadline-based recovery remain. Time away never fabricates a chain of completed work intervals.
- Brown, white, pink, rain, shoreline, and grove textures remain original synthesis, not third-party recordings. Silence remains the default. Playback starts only by user action or a user-started Focus session with a selected sound.
- Audio uses the playback session and the legitimate `audio` background mode. MediaPlayer provides Now Playing metadata and play/pause/stop handlers. Paused players are retained; disconnects and interruptions pause instead of silently restarting. Video entry pauses the sound. Starting Focus with an already-playing texture does not interrupt/regenerate it.
- A sleep deadline stops selected audio at interval end while the app can execute. No silent playback, endless background task, or timer background mode is used. Physical-device long-running playback, exact sleep stopping, route changes, interruptions, and remote-control delivery remain device verification gates.
- The WidgetKit extension displays an ActivityKit countdown on the Lock Screen, including the ordinary iPhone 14. Dynamic Island is optional presentation, not a requirement. Updates follow start/pause/resume/phase/end and relaunch. The system renders the countdown independently of app ticks. Tapping opens Focus; timer actions are intentionally performed in the app. When suspended, the app cannot promise automatic multi-phase transitions. An expired countdown may remain until the learner returns or dismisses it.
- System Focus is user-configured in Settings/Control Center. The app does not claim it can silently disable other apps' notifications.
- One-minute reset is a gentle optional 4-second-in/6-second-out visual pacer without holds. It stops when leaving the foreground and is not scored. It is not a clinically validated protocol or a claim of better grades.

## Evidence and validation boundary

The research screen separates noise preferences from published evidence: Nigg et al. (2024), Rijmen/Wiersema (2024), Albulescu et al. (2022), Roediger/Karpicke (2006), and Yilmaz Balban et al. (2023). No universal brown-noise benefit, optimum 25/5 schedule, or validation of this app is claimed. The respiration trial did not test this one-minute pacer.

Minimum deployment remains iOS 17. iPhone 14 Simulator testing uses the installed iOS 26.5 runtime; it is not a physical iPhone 14/iOS 17 test. Educator review of this expanded selection, comprehensive VoiceOver/Reduce Motion checks, media licensing review for release, and real-device energy/background checks remain separate gates. Current test evidence is maintained in `STATUS.md`.
