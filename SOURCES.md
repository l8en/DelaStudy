# Source register

## Short lessons and course resources · October 26, 2026

`Design/BiteLessons/*.txt` contains 396 edited topic explanations compiled into
three-step lessons for all 417 catalog readings by `scripts/build_bite_lessons.py`.
Each teaching sentence also supplies its corresponding comprehension prompt.
These selected ideas are adaptations/summaries, not verbatim replacement
chapters or a complete curriculum. The existing reading manifest supplies exact
source, publisher, original title, and per-reading license; credits remain
available from each short lesson and the full source document. Existing
noncommercial/share-alike restrictions are not removed by paraphrasing.
The original excerpt bank remains bundled for older saved practice rounds.
No official exam items, state endorsement, or measured reading-grade/learning
effectiveness claim is introduced. Educator review of the new explanations is
still required. [Authoring and preservation decisions](Design/BITE_LESSONS_AND_RESOURCES.md).

The separate Resources tab derives links from each course's recorded readings,
foundation videos, curriculum reference and AP framework. Textbook landing URLs
are derived from the original OpenStax book slugs; the [Biology 2e](https://openstax.org/details/books/biology-2e)
and [University Physics Volume 1](https://openstax.org/details/books/university-physics-volume-1)
landing pages were spot-checked, not the entire catalog. Personal-finance
wording retains the CFPB source boundaries; [credit reports versus scores](https://www.consumerfinance.gov/ask-cfpb/what-is-the-difference-between-a-credit-report-and-a-credit-score-en-2069/)
and the [youth education activity directory](https://www.consumerfinance.gov/consumer-tools/educator-tool/youth-financial-education/teach/activities/)
were additionally consulted. This is general educational material, not individual
financial, medical, or legal advice. Existing videos are embedded or linked,
never copied or represented as permanently available.

## Lens desk and personal materials · October 25, 2026

All seven pages of the user's local `ui-3.pdf` were rendered and inspected as layout/interaction references. No mascot, school crest, wordmark, screenshot, or other proprietary reference artwork is bundled. The original procedural optical core is projected and shaded SwiftUI geometry; it is not an AI-generated photograph or licensed 3D model. [Reference adaptation register](Design/LENS_DESK_REFERENCE.md).

Personal materials are supplied by the student and are separate from the source-checked course catalog. [Apple PDFKit](https://developer.apple.com/documentation/pdfkit) extracts selectable document text; [Apple Vision](https://developer.apple.com/documentation/vision/recognizing-text-in-images) recognizes photo text on the device. Extraction needs student review and does not establish factual accuracy. Original files/photos are not retained by this feature; the edited extracted text is saved with the local account. Student-authored recall cards are self-rated, not auto-generated assessments or evidence of mastery. YouTube links reuse the existing privacy-enhanced inline player and direct fallback; no transcript, download, or permanent availability is promised.

Year, study route, and school are self-reported preferences. Honors/SAT/ACT routes mean supplementary foundation support, not complete honors curricula, official test courses, school offerings, or endorsement. School search uses the existing partial directory and name/town/county filters, not device location, verified distances, or classmate counts.

## Interactive practice and typography — October 25, 2026

`Resources/Curriculum/reading-checks.json` retains links to the source reading through stable reading IDs. Most items are deterministically selected source-excerpt blanks, not newly invented factual explanations. A small set of original concept checks replaces unsuitable task-page prose. Adapted excerpts retain the corresponding reading's publisher and license, including the existing noncommercial/share-alike boundary. They are comprehension practice, not official exams or educator-reviewed mastery assessments. Reproduce with `scripts/build_reading_checks.py` and Beautiful Soup.

[Manrope](https://github.com/google/fonts/tree/main/ofl/manrope) is bundled locally under SIL Open Font License 1.1; copyright and license ship in `FirstStateLens/Fonts/OFL.txt`. The default learner portrait is code-native original artwork. [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain-services) supplies local credential storage; no remote identity provider has been introduced.

## Course image collection — October 24, 2026

All 39 published courses have a local image mapping, using 35 individually selected source assets. Photographs and micrographs are distinguished from archival documents, historical print/map reproductions, and satellite imaging. No generated image service was used. The in-app image inspector and searchable Image Credits list retain authors, per-file licenses, changes, contextual limits, and original source links. Course photography does not replace actual instructional diagrams.

The [complete attribution register](Design/COURSE_IMAGE_CREDITS.md), [editorial selections](Design/course-image-selections.json), and [bundled provenance manifest](Sources/FirstStateCore/Resources/CourseMedia/catalog.json) document each asset. Rights statements were read from individual file-description metadata, with additional original-record inspection during curation; Wikimedia hosting was not treated as a blanket license. Derivatives retain the applicable per-image terms. See [Wikimedia reuse guidance](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia/en) and [NASA media guidance](https://www.nasa.gov/nasa-brand-center/images-and-media/) for source-specific context. This register does not claim institutional endorsement or detector-proven authenticity.

## Educational sources

Foundation source register checked October 17, 2026. The workspace redesign adds the references below; individual school and framework records retain their recorded verification dates.

| Source | Publisher | URL | Used for | Reuse / limitation |
|---|---|---|---|---|
| Delaware Social Studies: Civics Standards K–12 (2018) | Delaware Department of Education | https://education.delaware.gov/wp-content/uploads/2024/06/DE-K-12-Civics-Standards-2018.docx | Civics anchors, especially 9–12 citizenship and participation expectations | Public agency standards. Used as alignment context; questions are not represented as official assessment items. |
| Educator Resources | Delaware Public Archives | https://archives.delaware.gov/educator-resources/ | Confirms Archives' teacher-created, standards-based resources and middle/high-school source lessons | Public agency page. Descriptions paraphrased. |
| Adoption of the Constitution worksheet | Delaware Public Archives | https://archivesfiles.delaware.gov/lesson-plans/2025/adoption-of-constitution.pdf | Petition transcription, date, audience, purpose, and HAPPY source-analysis framing | Government archival/educational material. Short excerpts are attributed; app practice questions are original. The transcription contains period spelling and apparent transcription irregularities, so excerpts are minimal. |
| Delaware and the Constitution lesson | Delaware Public Archives | https://archivesfiles.delaware.gov/lesson-plans/2025/the-constitution-and-delaware.pdf | Ratification sequence, December 7, 1787 outcome, Delaware historical context | Government educational material. Facts are paraphrased and attributed. |
| Delaware Constitution of 1897, as amended through July 1, 2025 | Delaware Code Online | https://delcode.delaware.gov/constitution/index.html | Confirms Delaware has a state constitution and provides present constitutional context | Primary legal source; no legal advice or current-policy inference is made. |
| Algebra 1 Scope and Sequence | Illustrative Mathematics | https://cms-assets.illustrativemathematics.org/xaczotl0hz2ng7y4arg7g6ikj7rh | High-school Algebra I sequence, linear equations, and linear relationships | Adapted sequencing and original notes under the source's CC BY-NC notice; the app does not reproduce the full curriculum. |
| Biology for AP Courses | OpenStax, Rice University | https://openstax.org/books/biology-ap-courses/pages/preface | Biology foundation topics: cells and membrane transport | Open textbook; source reading is linked and attributed. This foundation path is separate from the independent AP preparation module. |
| College Algebra 2e | OpenStax, Rice University | https://openstax.org/books/college-algebra-2e/pages/preface | College-level functions, domains, ranges, and quadratics | Open textbook; source reading is linked and attributed. App notes and tests are original. |
| Biology 2e | OpenStax, Rice University | https://openstax.org/books/biology-2e/pages/preface | College-level gene expression and cell-cycle regulation | Open textbook; source reading is linked and attributed. App notes and tests are original. |
| OpenStax subject catalog | OpenStax, Rice University | https://openstax.org/subjects | Foundation modules in calculus, statistics, chemistry, physics, environmental biology, economics, psychology, sociology, government, history, and writing | Open textbooks are linked per course. App summaries, notes, choices, and explanations are original; one module does not represent a full textbook. |
| High School Mathematics | Illustrative Mathematics | https://illustrativemathematics.org/math-curriculum/9-12-math/ | Geometry and Algebra II course alignment | Openly licensed curriculum sequence; app lessons and assessment items are original. |
| Your Money, Your Goals | Consumer Financial Protection Bureau | https://www.consumerfinance.gov/consumer-tools/educator-tools/your-money-your-goals/ | Personal-finance foundation path | Public U.S. government educational resource; app wording and practice are original. |
| YouTube Embedded Players and Player Parameters | Google for Developers | https://developers.google.com/youtube/player_parameters | Inline player behavior, privacy-enhanced embed URL, captions, and plays-inline playback | Videos remain hosted by their publishers on YouTube. The app embeds rather than copies them and provides a direct fallback link. |

## Expanded offline unit studies · October 24, 2026

- `Sources/FirstStateCore/Resources/Curriculum/catalog.json` records 417 distinct readings, 39 course mappings, five units per course, exact source URLs, versions, and per-reading licensing. Full OpenStax section adaptations retain attribution, free textbook links, and figure credits in each footer. MathML and local image files remain in the script-free reader. The selection plan and rebuild tool are in `scripts/build_study_curriculum.py`.
- Current OpenStax book metadata identifies **CC BY-NC-SA 4.0**, not the older assumed CC BY license. [OpenStax licensing guidance](https://help.openstax.org/s/article/Openstax-textbook-licensing-and-customization) explains attribution and commercial permissions. This local educational build does not clear commercial distribution; permission/replacement and licensing review are required before monetization.
- Literary selections use complete selected chapters from [Douglass](https://www.gutenberg.org/ebooks/23), [Hawthorne](https://www.gutenberg.org/ebooks/33), [Melville](https://www.gutenberg.org/ebooks/2701), [Alcott](https://www.gutenberg.org/ebooks/514), and [Wharton](https://www.gutenberg.org/ebooks/541). Primary texts are public domain in the USA; the app retains ebook/terms links and historical-language notices. Coverage is selected, not a comprehensive American literature survey.
- `Design/original-study-lessons.json` and `Design/personal-finance-study-lessons.json` contain 45 original Geometry, Java, and personal-finance mini-lessons, worked examples, recall tasks, and self-checks. Java references [Dev.java language fundamentals](https://dev.java/learn/language-basics/); no Oracle prose is bundled. Finance references the CFPB's [Your Money, Your Goals toolkit](https://www.consumerfinance.gov/consumer-tools/educator-tool/your-money-your-goals/toolkit/), credit-report, credit-card, and student-loan topic pages, checked October 24. These are original educational examples, not CFPB approval, copied CFPB prose, current offers, or personalized advice.
- [Roediger & Karpicke, 2006](https://pubmed.ncbi.nlm.nih.gov/16507066/) supports opportunities for retrieval rather than merely rereading. This does not validate these particular labs. [Yilmaz Balban et al., 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC9873947/) studied different five-minute respiration protocols, not this app’s one-minute 4/6 pacer or improved school performance.
- Native integration follows [Apple ActivityKit](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities) and [MediaPlayer remote command](https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter) documentation. The timer does not enable system Focus or promise continued app execution after force quit.

## Workspace, AP preparation, and school sources

- [AP Central course frameworks](https://apcentral.collegeboard.org/courses): each of the ten independent preparation modules links its specific Course and Exam Description and edition in `APPreparation.swift`. Original worked explanations, questions, and rubric activities cover selected topics; they are not authorized AP courses or full exams. Imported framework metadata was checked October 19; the Biology course landing page was checked again October 24.
- [Delaware standards and assessments](https://education.delaware.gov/?page_id=15145): current source gateway checked October 24. The four authored crosswalk entries in `StandardsRegistry.swift` link specific CCSS/NGSS documents and Delaware adoption references. Three entries describe partial coverage; the science entry is a related topic only. No educator review or comprehensive alignment is claimed.
- [Explore Delaware Schools](https://explore.education.delaware.gov/discover-districts-and-schools/): the directory gateway was checked October 24. The bundled 84-record directory retains October 19 record dates and explicitly partial coverage, including 73 public and 11 selected private records. Each entry links its source. This pass does not claim a fresh audit of every individual school or current school-specific AP offerings.
- [Nigg and colleagues, 2024](https://pubmed.ncbi.nlm.nih.gov/38428577/), [Rijmen and Wiersema, 2024](https://pubmed.ncbi.nlm.nih.gov/39034029/), and [Albulescu and colleagues, 2022](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0272460): linked from the separate sound-research view. Evidence is limited by population, task, and intervention; there is no claim of a universally best noise, an optimal 25/5 schedule, or validation of this app. Sound textures are original synthesis rather than copied recordings.
- [Apple Focus guidance](https://support.apple.com/guide/iphone/set-up-a-focus-iphd6288a67f/ios) and [Focus status API](https://developer.apple.com/documentation/intents/infocusstatus): system Focus is configured by the user. The app does not claim device-wide notification control or verified system Focus status.
- Product-interface research and adaptation decisions are recorded in [Design/WORKSPACE_REDESIGN.md](Design/WORKSPACE_REDESIGN.md), with first-party Linear, Things, Structured, and Brilliant references. Those references support interface observations, not educational outcome claims.

## Authorship and limits

All answer choices, explanations, objective descriptions, course framing, and mastery rules in the app are original to this project. The short phrases shown from the 1787 petition are identified as archival excerpts. Course labels describe the intended instructional level; they do not imply school or college credit. The app is not affiliated with or endorsed by the source publishers or video channels.
