# First State Lens — observed collection

## Baseline and design thesis

October 24, 2026. The existing app has working study, planning, review, and Focus workflows. Preserve their IDs, persistence, and local-first boundaries. The current visual issues are oversized repeated heading blocks, boxed controls, a dark resume poster, synthetic subject graphics repeated across unrelated courses, and slogans in place of destination names.

The audience is high-school and early-college students choosing what to study and returning to unfinished work. The interface should feel precise, curious, and capable.

Three decisions:

1. **An observed collection:** real photographic and archival objects, individually framed, identify courses. Titles and level labels sit on solid reading surfaces, never across busy images. In a compact two-column catalog, photographs have a shared landscape aperture while the surrounding content stays open rather than boxed.
2. **One study spine:** Today pairs a modest course photograph with the next lesson and a single resume action; course detail continues the same image and immediately exposes the syllabus. Course numbers, module counts, and thin rules organize the collection without fake activity.
3. **Evidence on demand:** an image-inspection sheet connects each cover to its real title, creator, origin, relevance, and license. A searchable credits collection stays available offline. Sources are part of the product, not explanatory paragraphs beneath every tile.

Signature interactions: save a course directly in the collection with visible and accessible feedback; inspect its photograph without losing syllabus/navigation context. Existing compact scroll titles and uninterrupted Focus-to-Zen continuity remain.

## Research and adaptation

- [Apple Books](https://www.apple.com/apple-books/), checked October 24: its official page shows covers separated from reading controls and describes curated collections alongside continued reading. Adaptation: images identify courses; resume, syllabus, and course filters remain task-specific. We are not reproducing book-cover proportions, store rankings, or Apple artwork.
- [Are.na](https://www.are.na/about), checked October 24: capture, arrange, search, and connect are explicit actions around a collection of sources. Adaptation: inspect a cover's provenance, retain related course context, and make credits searchable. No copied channels interface or invented network.
- Existing Linear/Things/Structured research remains useful for compact navigation, editing in a sheet, and scan-friendly task rows. It does not justify repeating one card on every screen.

Apple's official cover-browsing and reading-control screenshots were downloaded and visually inspected as references, not shipped assets. Their marketing imagery includes older devices and is not evidence of the latest OS layout. The adaptation uses compact landscape photographs rather than Apple's large portrait cover carousel; reading controls remain adjacent to their task rather than permanently covering the text.

## Sourcing rules

Prefer documented photographs, historical records, and physical instruments from traceable creators. Wikimedia file-description records are inspected individually; hosting is not permission. Preserve attribution, license, revision/source information, and crop notes. No generated imagery or detector-based authenticity claims. Scientific imaging, historical illustration, and schematic artwork must be distinguished from photography.

Originals are reproducible from recorded download URLs. Shipping images are bounded-resolution JPEG derivatives with no generative changes. A missing verified image must remain an explicit fallback, not synthesized filler.

## Workflow checklist

- [x] Capture original Today, Library, and course detail.
- [x] Acquire and inspect representative history, biology, mathematics, and computing assets.
- [x] Implement and inspect the defining three screens together.
- [x] Finish all course mappings and attribution records.
- [x] Review remaining screens and reduce unnecessary surface/copy repetition.
- [x] Verify assets, offline operation, saved state, appearance, navigation, and regressions.
- [x] Capture final comparable screenshots and record limitations.

## Implementation record

The collection has 35 individually selected source assets for all 39 courses. Four intentional reuses connect high-school/college and AP modules in the same subject: the founding document, a forest-inventory photograph, a psychological timing instrument, and Delaware Legislative Hall. Selected assets and contextual limits are documented in [the credits register](COURSE_IMAGE_CREDITS.md), with machine-readable acquisition/crop metadata bundled in `Sources/FirstStateCore/Resources/CourseMedia/catalog.json`.

Shipping JPEGs total 7.83 MiB and are at most 960 pixels on their longest edge. All were inspected in three contact sheets; observations corrected initial descriptions of microscope color and printing tools. The original printing-display photograph shows ink balls, not the entire press. The collection contains real photographs plus explicitly labeled archival/technical media; no generative service or authenticity detector was used.

Course covers and Profile's chosen subject image use the collection. The procedural `SubjectDiagram` decoration was removed, including onboarding. Actual instructional graphs and the interactive algebra/source labs remain. Library and Today now use open image/text compositions rather than repeated background cards; secondary destinations use direct titles and grouped task-oriented links. Course details and lesson sources open the corresponding image record without changing the current course context.

A targeted workflow exposed a genuine hit-testing problem: a cropped image's oversized drawing region intercepted the caption button below it. Bounding its hit shape and giving the caption a full rectangular target fixed it; the test then passed through inspection, saving, relaunch, filtering, creator search, and a second image record.

Final framing review also caught a layout-level crop bug: an oversized ZStack child was recentered by its parent before the focal offset was applied. Rendering in a fixed-size overlay keeps the actual top/center focal points, including the Constitution's heading. Collection and header/profile/school tests passed again after this correction in `/tmp/Lens-Collection-Crop-Final.xcresult`.

Full-image inspection shows the uncropped derivative. Rights statements and original record/license links remain visible on demand, not beneath every course tile. Source pages are external; browsing covers and reading credits do not require a network connection. The 24 MiB decoded-image cache is bounded to 16 entries; actual frame-rate, energy, and long-session memory profiling on hardware remain separate checks.
