# Short lessons, separate depth

This change keeps the warm-paper optical workspace, Manrope, cobalt actions, and
existing course identity. It changes the reading task rather than redesigning the
entire app.

## Learning structure

Students need a manageable next idea, not a textbook chapter before every check.
Each of the 417 source-backed readings now has three edited teaching steps. The
steps use plain language, define the selected vocabulary, and include short
examples where appropriate. They total 45–72 whitespace-delimited words per
reading (about 59 on average), followed by MCQ, fill-in-the-blank, and matching.
This is deliberately a selection of key ideas, not equivalent coverage of a full
chapter, full AP course, or year-long class. Readability is an editorial target,
not a measured reading-grade certification or evidence of learning effectiveness.

The 396 distinct edited topics live in `Design/BiteLessons/*.txt`. Topics shared
by books/courses reuse an explanation. `scripts/build_bite_lessons.py` checks the
three-step structure, word bounds, distinct answers, and complete catalog
coverage, then compiles `bite-lessons.json`. It performs no network requests or
runtime generation. Explanations are not created by cutting off the first few
sentences of an article. The original source manifest still binds each lesson to
its exact chapter, publisher, and license. Educator review remains outstanding.

The explanation and its new questions use the same edited sentences. A current
practice round therefore cannot ask about an excerpt absent from the short
lesson. This is introductory concept/comprehension practice, not the original
source-checked foundation assessment or a new claim of demonstrated mastery.

## Interaction and preservation

- One explanation at a time; three progress marks and a safe-area action dock.
  Back and Continue are available without waiting for an effect. Larger text
  scrolls instead of being shrunk or clipped.
- Moving between steps saves the reading's position before changing the UI.
  Reopening/relaunching resumes that step. Going backward changes no XP.
- The final step completes the existing reading activity and enters its existing
  practice activity. All 1,170 activity IDs, completion records, historical XP,
  accounts, notes, photos, and old full-reader scroll positions remain intact.
  XP is still awarded once; no bonus is manufactured by the redesign.
- A version tag distinguishes new practice from older saved rounds. Older rounds
  keep their original questions and cleared count; a compact review disclosure
  gives their original evidence. Explicitly starting practice again uses the
  current version without awarding repeat XP.
- Transitions use a 16-point directional move plus opacity, with fades/static
  changes under Reduce Motion/quiet Focus. No timed gate or decorative loop.

## Course resources

Lessons / Resources is a native segmented switch on each course. Resources is not
a unit, an activity, a completion requirement, or an XP destination. Its four
vertical dropdowns are Videos, Textbooks, Full readings, and Curriculum &
standards. One category expands at a time with a short damped spring. Labels,
counts, expanded/collapsed values, chevron direction, and 44-point minimum hit
areas communicate state without relying on color. Reduce Motion removes the
spatial animation.

Resource records derive only from that course's existing catalog and foundation
sources. Exact-URL duplicates are removed; Gutenberg chapter fragments are
removed for whole-book entries. No additional video availability, school
partnership, accreditation, or state endorsement is invented. An empty category
says it is empty rather than filling itself with unrelated media.

Textbook/framework links use the native in-app browser. Full readings retain the
script-free offline HTML, diagrams, mathematics, credits, and original-source
link. Videos open their own resource screen with the shared privacy-enhanced
YouTube player, bounded failure detection, retry, and external-link recovery.
The existing sound-pause preference applies on that screen, not while entering
a text lesson. Network access is optional for the lesson and offline reading;
external resources and video availability depend on their publishers/network.

The separate short foundation lessons retain their interactive examples,
personal notes, optional AP writing, and original assessments. Their videos and
external readings are now reached through Course resources instead of appearing
inside the instructional sequence. Attribution remains available in the lesson.

## Verification boundaries

Core coverage, migration/round trips, saved steps, resource membership, HTTPS
URLs, and deduplication are automated. The UI journeys cover short-step return,
relaunch, practice, resource selection, external browser, offline chapter, and
embedded-video entry. Native iPhone 14 layout, dark appearance, larger text, and
Reduce Motion are reviewed separately. Current results are in `STATUS.md`.

This is not an educator audit of every summary, a whole-catalog live-link audit,
an exhaustive VoiceOver traversal, or a physical-device media/background test.
The existing OpenStax noncommercial/share-alike and physical-release gates remain.
