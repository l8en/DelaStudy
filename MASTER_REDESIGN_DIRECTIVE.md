MASTER PRODUCT AND BRAND REDESIGN DIRECTIVE

You are taking creative and technical ownership of our existing iOS study app.

Your responsibility is to develop its name, brand, visual identity, interface, interactions, and overall product experience into something distinctive enough to represent an ambitious startup launching in 2027.

Work in the existing SwiftUI codebase. Inspect the actual implementation before making decisions. Then design, implement, test, and visually review the result.

The current interface needs substantial reconsideration. Its oversized typography, repeated rounded panels, floating title pills, generic icons, and sparse arrangements do not yet form a convincing identity.

Treat this as a full product design assignment with engineering responsibility.

Do not finish with a mood board, a proposal, or renamed colors. Deliver a working app whose screens feel deliberately composed and recognizably related.


1. UNDERSTAND THE PRODUCT BEFORE REDESIGNING IT

The app helps high-school and early-college students explore academic subjects, complete lessons, practice their understanding, earn achievements, and prepare for college.

It currently includes course paths, lesson notes, sourced readings, tests, embedded videos, local progress, a learner profile, rewards, community activities, and a college preparation area.

Inspect the repository to establish the actual current state. Treat previously reported course counts and feature descriptions as context that requires verification.

Identify:
- What works well enough to preserve.
- What is incomplete.
- What appears interactive but does not work.
- What content exists behind each course.
- Where the interface repeats itself unnecessarily.
- Where navigation creates friction.
- Which information students actually need at each moment.

Use those findings to make concrete decisions.

The target student should be able to understand the product quickly, find something worth studying, complete meaningful work, and see that work reflected in their profile.

Every design decision should support one of those outcomes.


2. CREATE THE NAME AND BRAND

You are responsible for the product name.

“First State Lens” is the conceptual origin. You may retain it, shorten it, reinterpret it, or choose a stronger name derived from its meaning.

Investigate both parts:

FIRST STATE
Delaware, an initial point, beginnings, independence, taking initiative, choosing a direction, and the first moment of understanding.

LENS
Perspective, focus, observation, investigation, clarity, interpretation, and seeing relationships that were previously invisible.

Find an original connection between these ideas and the experience of learning.

The brand should have a credible relationship to its Delaware origin while remaining suitable for students elsewhere. A student should understand the product without needing a history lesson about the name.

Develop at least seven meaningfully different name candidates internally. Explore different linguistic approaches rather than producing seven variations of one invented word.

Evaluate the candidates against:
- Ease of pronunciation.
- Memorability after hearing it once.
- Visual potential as a wordmark.
- Connection to the product.
- Suitability for high-school and college students.
- Ability to grow beyond a Delaware-specific audience.
- Obvious conflicts with existing products.
- Whether it sounds natural in conversation.

Use these sentence tests:
“I’m studying chemistry on ___.”
“Send me your ___ profile.”
“Our study group uses ___.”
“I finished that course on ___.”

Avoid predictable combinations built from Edu, Study, Learn, Smart, AI, Hub, Academy, Verse, and similar startup naming fragments.

Avoid unusual spelling that exists only to make an ordinary word appear proprietary.

Use current sources to check obvious naming conflicts. Do not claim legal trademark clearance or domain availability without appropriate evidence.

Select the strongest name yourself. Give a concise explanation and proceed with implementation.

Carry the name through:
- App display name.
- Onboarding.
- Navigation where relevant.
- Profile and sharing language.
- Settings and about content.
- App icon.
- Documentation that describes the product.

Preserve bundle identifiers and saved-data compatibility unless there is a concrete technical reason to change them.


3. DEVELOP AN ORIGINAL BRAND CONCEPT

Create a central visual idea that can generate a complete interface.

Explore the relationship between perspective and discovery. Potential ingredients include intersecting frames, changing viewpoints, alignment, meaningful crops, layered information, and forms that become clearer through movement.

Choose one concept and develop it with discipline.

Research subtle Delaware references if useful:
- Geographic forms.
- Historical printing or document composition.
- The idea of an initial point.
- Connections between place, direction, and discovery.

Abstract those references into the identity.

Avoid literal state seals, patriotic decoration, tourist imagery, classroom clip art, and a government-portal appearance.

A generic camera lens, magnifying glass, graduation cap, open book, or lightbulb is insufficient as the main brand symbol.

Develop an original mark with:
- A recognizable silhouette.
- A clear relationship to the chosen concept.
- Good performance in one color.
- Legibility at small sizes.
- A convincing static form.
- Potential for one restrained motion behavior.

Do not rely on a gradient to make the symbol interesting.

Design a wordmark whose spacing, proportion, and letter treatment feel intentional. It may use an existing licensed typeface, custom adjustments, or a carefully drawn mark. Avoid altering letters so much that the name becomes hard to read.


4. ESTABLISH THE DESIGN SYSTEM BEFORE SPREADING IT

Define a coherent system for:
- Colors.
- Typography.
- Spacing.
- Layout.
- Shapes.
- Borders.
- Elevation.
- Icons.
- Illustration.
- Motion.
- Interaction states.

Use semantic tokens so the system can evolve consistently.

Do not give every component the same corner radius and shadow.

Choose a small number of surface treatments and explain their purposes through use. A course cover, lesson reading area, discussion row, and achievement object should have different structures because students interact with them differently.

Build reusable components around actual repeated needs. Avoid a universal card component that forces every screen into the same layout.

Check the app at normal iPhone size throughout implementation. Do not design only against enlarged screenshots.


5. COLOR DIRECTION

Choose a deliberate palette based on the final brand concept.

Explore a strong relationship between a paper-like neutral, a deep ink color, and one distinctive accent. You may choose a different direction if it produces a stronger identity.

Give each color a role:
- Page background.
- Reading surface.
- Primary text.
- Secondary text.
- Selection.
- Main action.
- Success.
- Error.
- Subject identification.

Use accent color selectively so it retains meaning.

Subject colors must work together without making the catalog resemble an unrelated collection of pastel tiles.

Check text and icon contrast in every state, including:
- Selected filters.
- Disabled buttons.
- Locked lessons.
- Progress indicators.
- Colored course covers.
- Material surfaces.
- Dark appearance.

Create dark mode deliberately. Make decisions about surface separation, accent brightness, border visibility, and the treatment of illustrated assets.

Never use pale grey copy as a substitute for deciding whether the copy should exist.


6. TYPOGRAPHY AND DENSITY

The standard interface should feel mature and well edited.

Use a purposeful type hierarchy:
- A distinctive treatment for selected major titles.
- A readable interface face for navigation and coursework.
- A restrained secondary treatment for metadata where useful.

Avoid making every heading oversized, heavy, and rounded.

Avoid excessive letter spacing on long labels.

Choose line heights and widths that make lessons comfortable to read.

Keep useful content visible above the fold. Related information should sit close enough to read as a group.

Use whitespace to establish hierarchy. Do not leave large empty regions merely to make the screen appear premium.

Support Dynamic Type and comfortable touch targets without forcing the default layout into an enlarged presentation.

Use standard accessibility practices throughout. The visual target is a confident student product with polished typography and useful density.


7. GIVE THE APP RECOGNIZABLE SIGNATURES

Develop three visual signatures and two interaction signatures.

A visual signature should be more specific than “bold type,” “rounded cards,” or “glass.”

Possible areas to develop:
- A distinctive course-cover composition.
- A recurring indexing device.
- An original relationship between title and progress.
- Achievement objects with a recognizable construction.
- A diagram language that connects subjects.
- A brand mark used as a functional navigation element.

An interaction signature should help students understand a transition or result.

Possible moments:
- Moving from a course overview into a lesson.
- Condensing the page header while scrolling.
- Revealing the evidence behind an achievement.
- Moving between explanation and practice.
- Showing how a completed lesson changes the course path.

Make each signature useful and repeatable.

Apply strong brand gestures selectively. Quiet reading and focused testing should remain visually calm.


8. RECONSIDER THE INFORMATION ARCHITECTURE

Inspect the current tabs and navigation.

Decide where students expect to:
- Resume learning.
- Browse courses.
- Review progress.
- Participate with others.
- Prepare for college.
- Find their Delaware school and relevant resources.
- Manage their identity.

Choose concise labels.

Keep primary destinations easy to reach. Avoid hiding important features behind decorative controls.

Every screen needs a clear main purpose and an obvious next action.

Use sheets, pushed screens, and inline expansion according to the task. Do not place every action in a modal.

Make return navigation predictable. Preserve useful context such as catalog filters and scroll position where practical.

Include empty, loading, unavailable, error, and completed states in the design.


9. REDESIGN THE HOME EXPERIENCE

Home should help the student start useful work immediately.

Its first screen should answer:
- What am I studying?
- Where did I stop?
- What should I do next?

Lead with the active course and lesson. Integrate:
- Course identity.
- Current unit or topic.
- Meaningful progress.
- A concise resume action.
- One supporting visual tied to the subject.

Avoid an enormous generic greeting followed by a giant motivational headline.

Place secondary information according to its value:
- Recent learning activity.
- A relevant review opportunity.
- A saved goal.
- A new achievement.
- A selected community challenge.
- A relevant school or college-planning resource.

Do not display every statistic at equal importance.

Create useful states for:
- A new student.
- A student with work in progress.
- A student who completed a course.
- A student returning after a break.

Use actual saved activity. Do not seed fake streaks, scores, or recent events.


10. BUILD A PROPER SCROLLING HEADER

Replace the current floating-title treatment with a coordinated page header.

At the top of the screen, the title should belong to the page composition.

As the student scrolls:
- The title changes position and scale with control.
- Relevant context settles into the navigation area.
- Secondary material recedes appropriately.
- Useful actions remain available.
- The compact state occupies less space.

Use continuous scroll progress where it improves the behavior.

Prevent:
- Duplicate titles.
- Abrupt flashes.
- Layout jumps.
- Text colliding with the status bar.
- Content becoming unreadable behind translucent controls.
- Header state oscillation.
- Excessive empty space.

Adapt the behavior to the screen. A lesson may need a compact course title and progress; the catalog may need persistent search or filter access.

Verify the expanded, transitional, and compact states visually.

Respect Reduce Motion.


11. REDESIGN THE COURSE LIBRARY

The library should feel like a curated academic collection.

Provide:
- Fast search.
- Clear subject filtering.
- High-school and college distinctions.
- Consistent progress.
- A useful default ordering.
- Clear recovery from a search with no results.

Make the initial library view composed and engaging.

Create original course-cover graphics using the subject visual system. Give titles enough room to remain legible.

Use meaningful motifs:
- Mathematical relationships for mathematics.
- Systems and structures for sciences.
- Text, chronology, and interpretation for humanities.
- Logic and computation for computer science.
- Flows and decisions for economics and finance.

Avoid assigning a random SF Symbol and background color to every course.

Keep metadata concise. Show the facts needed to choose a course.

Represent scope honestly. A foundation module must not appear to contain a complete year of instruction.

Keep at least the existing course breadth. Verify that course pages lead to real content.

Where school course catalogs are available, connect their published subjects to relevant in-app practice. Describe this as subject support unless a complete curriculum alignment has been verified.


12. REDESIGN COURSE PROGRESSION

Give every course a clear syllabus.

Show:
- Course scope.
- Units or topic groups.
- Available lessons.
- Completed work.
- Current position.
- Prerequisite relationships where they exist.
- What completion requires.

Choose a layout that fits the curriculum. Avoid forcing every subject into a winding game map.

Make locked states understandable through concise labels and visual hierarchy.

Let students inspect useful course information before starting.

Use actual progress in every indicator.

Make the transition into a lesson feel connected to the course identity.


13. DESIGN A STRONG LESSON ENVIRONMENT

Lessons deserve a focused reading experience.

Create a hierarchy for:
- Lesson title.
- Learning goal.
- Main explanation.
- Key ideas.
- Examples.
- Notes.
- Sources.
- Video.
- Practice entry.

Integrate video into the lesson instead of presenting it as an unrelated embedded rectangle.

Handle loading, unavailable playback, and opening the source clearly.

Preserve reading position when practical.

Use diagrams, equations, timelines, and comparisons when they materially improve understanding. Create these as precise, maintainable graphics.

Keep essential educational explanations. The request for less interface text does not justify stripping lessons of substance.

Distinguish student notes from authored lesson content.

Make practice easy to find without letting a large sticky button obscure the reading area.


14. MAKE PRACTICE FEEL PRECISE AND RESPONSIVE

Design the full question lifecycle:
- Reading the prompt.
- Considering options.
- Selecting an answer.
- Submitting.
- Seeing the result.
- Understanding the explanation.
- Continuing.
- Completing the session.

Use selection states that remain readable in both appearances.

Make feedback visually clear without depending entirely on red and green.

Explain why an answer is correct when the content supports it.

Prevent duplicate submissions and accidental loss of session state.

Use restrained motion to guide attention.

At completion, show:
- Work completed.
- Relevant performance.
- Progress earned.
- Any newly available lesson.
- A clear next action.

Keep celebration proportional to the accomplishment.


15. MAKE PROFILE A DISTINCTIVE ACADEMIC IDENTITY

The profile should become one of the most memorable screens.

Develop a composed academic identity with:
- Customizable visual header.
- Avatar or initials.
- Display name.
- Selected academic interests.
- Level and earned experience.
- Featured achievements.
- Learning history.
- Optional school affiliation with visibility controls.

Give students meaningful customization within a curated system.

Avoid turning the profile into a settings page with a large avatar.

Keep editing easy to discover.

Design the profile so a future shareable version could look intentional, while only implementing sharing that the current architecture supports.

Protect private notes and other personal information from accidental inclusion in shared content.

A school selection must not automatically appear on shared material. Let the student explicitly include or exclude it.


16. CREATE AN ORIGINAL ACHIEVEMENT COLLECTION

Design achievements as a coherent collection of academic objects.

Develop a construction system:
- Recognizable outer forms.
- Subject-specific centers.
- Clear visual differences between achievement types.
- Controlled material and color variation.
- Legible small-size versions.

Use original geometry and artwork.

Avoid generic trophies repeated with different colors.

Distinguish:
- Available.
- In progress.
- Earned.
- Featured.

Every earned object must correspond to real work.

On inspection, show the requirement, relevant progress, and evidence such as completed lessons or recorded activity.

Let students choose featured achievements where practical.

Design one special reveal for a meaningful unlock. Make it skippable and compatible with Reduce Motion.

School-related achievements can recognize participation in actual in-app work. They must not imply school certification, graduation credit, or an official school award.


17. GIVE COMMUNITY A REAL PURPOSE

Community should help students participate in learning.

Build around useful activities:
- Weekly study challenges.
- Subject questions.
- Student-written explanations.
- Reflections on difficult concepts.
- Shareable study prompts.
- Invitations to work on a challenge.
- School and club study activities where supported.

Give posts and prompts a readable structure with meaningful distinctions between title, subject, contribution, and action.

Avoid a generic social feed filled with fabricated engagement.

Inspect the available architecture before promising online behavior.

Implement working local contributions, editing, persistence, and native sharing where supported.

Clearly communicate when content is private to the device or shared through another service.

Never invent users, replies, likes, rankings, or live activity.

A smaller honest community feature is preferable to an elaborate nonfunctional feed.

Selecting a school must not expose a directory of its students or make the student publicly discoverable.


18. BUILD COLLEGE INTO A USEFUL WORKSPACE

Make the college area help students decide and act.

Organize:
- Academic interests.
- Possible fields of study.
- College research.
- Application milestones.
- Financial-aid resources.
- Introductory college coursework.

Create a clear next action for a student who has not started.

Let progress accumulate through actual completed tasks.

Use reliable, current sources for links and guidance.

Make external resources easy to identify and open.

Avoid unsupported admission predictions, invented deadlines, or claims that a checklist completes an application.

Give college courses a clear relationship to the broader course library.

Use a mature visual composition appropriate to planning an important transition.

For Delaware students, research current state-specific college, financial-aid, scholarship, dual-enrollment, and career resources.

Verify eligibility and dates from the organizations responsible for each opportunity. Link to official details rather than reproducing complex requirements inaccurately.


18A. MAKE DELAWARE HIGH SCHOOLS A FUNCTIONAL PART OF THE PRODUCT

Delaware schools must become a useful part of the student experience.

Build an actual school directory and a working school-aware experience. A decorative school selector or a static collection of names is insufficient.

DIRECTORY COVERAGE

Compile a verified directory of active Delaware schools serving high-school grades.

Cover New Castle, Kent, and Sussex counties.

Include:
- Public district high schools.
- Charter schools serving high-school grades.
- Vocational-technical high schools.
- Combined-grade schools that include high-school students.
- Private high schools where current official information is available.

Support homeschooled students, students outside Delaware, and students who prefer not to identify a school.

Use the Delaware Department of Education’s current school directory and Explore Delaware Schools portal as primary sources for public schools:
https://explore.education.delaware.gov/
https://explore.education.delaware.gov/discover-districts-and-schools/

Verify private schools and additional details against their official websites.

Do not invent a complete list from memory.

Record:
- Stable internal identifier.
- Official school name.
- District or governing organization where applicable.
- County.
- Municipality.
- School type.
- Grades served.
- Official website.
- Source URL.
- Date last verified.

Include official counseling, course-catalog, college-planning, and career-program links where available.

Do not populate missing fields with guesses.

Keep directory information separate from student progress so school records can be updated without damaging saved learning activity.

Make the verified core directory usable offline.

Validate duplicate records, broken references, invalid URLs, and school eligibility for inclusion.

Report coverage honestly. Do not call the directory complete until it has been reconciled against the relevant official sources.

SCHOOL SELECTION

Let students optionally choose a school during onboarding or later from their profile.

Make selection fast:
- Search by name.
- Recognize common abbreviations when verified.
- Filter by county or school type.
- Show enough location information to distinguish similar names.
- Provide a clear “Skip” option.
- Allow changing or removing the selection.

Do not request a student ID, school login, exact address, or proof of enrollment for ordinary local personalization.

School selection represents the student’s own preference. It does not verify enrollment or create a school partnership.

Keep it private by default.

THE SCHOOL EXPERIENCE

Create a useful “My School” area or integrate school context into an existing destination after reviewing navigation.

Do not add another primary tab automatically.

The school experience should provide:
- A concise school identity.
- Official website and useful resource links.
- Saved academic goals.
- Relevant subject practice.
- College and career planning resources.
- Study challenge templates.
- A way to change the selected school.

Use a compact layout. Avoid repeating school descriptions across Home, Profile, Community, and College.

Design original typographic school identities within our brand system. Do not depend on copied mascots, seals, or school logos.

Do not fabricate official colors or present our identity treatment as school-approved branding.

BENEFITS FOR STUDENTS

Make the school connection useful through working features:

1. Classroom support
Students can select subjects they are taking and connect those subjects to relevant practice in the app.

2. Personal study planning
Students can create a weekly goal, save an assessment date themselves, and select lessons to review.

3. Academic exploration
Students can discover adjacent subjects and introductory college topics relevant to their interests.

4. Learning evidence
Students can review and optionally share a concise record of completed in-app work.

5. College preparation
Students can find verified counseling resources and manage their own preparation tasks.

6. Study participation
Students can share a challenge or discussion prompt with classmates through the device’s sharing tools.

Describe these as benefits of the product’s functionality. Do not promise higher grades, admission, graduation credit, or measured outcomes without evidence.

BENEFITS FOR TEACHERS

Provide practical features that work without inventing a teacher dashboard:

- Share a lesson or a short sequence of lessons.
- Copy a discussion prompt.
- Open the source material behind a lesson.
- Assemble or share a study activity using existing content.
- Receive a student-selected summary through native sharing.

Make shared material concise and readable.

Clearly identify in-app practice results. They are not school grades or official assessments.

If secure teacher accounts and classroom management are not implemented, do not display controls that pretend they exist.

BENEFITS FOR COUNSELORS

Make the College area useful for student-counselor conversations.

Students should be able to save:
- Fields they want to explore.
- Colleges or training routes they are researching.
- Questions for a counselor.
- Tasks they have completed.
- Links they want to discuss.

Offer a student-controlled planning summary for sharing.

Include school counseling links only when verified.

Do not imply that counselors can see student information inside the app unless an actual authorized system supports that access.

BENEFITS FOR CLUBS AND STUDY GROUPS

Create usable templates for:
- A weekly subject review.
- A peer explanation activity.
- A college research session.
- A civics or local-history discussion.
- A short academic challenge.

Let students personalize and share a template.

For a local-only implementation, clearly preserve the distinction between creating an invitation and establishing a synchronized group.

Do not show fake members, school rankings, or participation totals.

SUPPORT DIFFERENT ACADEMIC ROUTES

Research verified resources for:
- Four-year college preparation.
- Community college.
- Dual enrollment.
- Career and technical education.
- Apprenticeships and other training routes.

Present these paths with equal care.

Use published school program information when tailoring links. Do not infer a student’s goals from their school type.

LOCAL RELEVANCE

Create a small number of well-researched Delaware learning activities where they add academic value.

Possible subjects include:
- Primary-source reasoning.
- State and local government.
- Environmental questions involving Delaware’s geography.
- Economic and community issues.
- Local history.

Use cited sources and original explanations.

Only publish activities with sufficient content and verification. Do not fill every school page with identical local trivia.

AFFILIATION AND PRIVACY

A directory listing does not imply:
- School participation.
- District endorsement.
- Access to school records.
- An official partnership.
- Approval of our curriculum.

Use a concise directory-level explanation or about entry where needed. Avoid adding repeated disclaimers to every screen.

Student work stays private unless the student deliberately shares it.

Never expose public school-based rosters, exact student locations, or automatically public profiles.

Do not contact schools, create institutional accounts, or send outreach without separate authorization.

IMPLEMENT REAL VALUE

At minimum, deliver:
- A verified school directory.
- Search and optional school selection.
- Persisted school preference.
- A working school resource view.
- Subject-to-practice connections.
- A saved personal school-related goal.
- A student-controlled learning or planning summary.
- A shareable study challenge or activity template.

Anything requiring a future backend must be documented as future work rather than presented as operational.

SCHOOL FEATURE VERIFICATION

Verify:
- Directory coverage against official sources.
- Search, filters, and empty results.
- School selection, switching, and removal.
- Saved preference after relaunch.
- Resource-link behavior.
- Private defaults.
- The content of shared summaries.
- Continued usability when no school is selected.

Make the school features feel integrated into the product’s identity while remaining useful to students outside Delaware.



18B. ADD SUBSTANTIVE AP PREPARATION

AP preparation must be a visible, working part of the academic product.

Build independent preparation paths using the current College Board Course and Exam Descriptions, topic structures, and skills. Verify the framework version and effective academic year before authoring or mapping content.

Prioritize:
- AP Biology.
- AP Chemistry.
- AP Environmental Science.
- AP Calculus AB.
- AP Statistics.
- AP Computer Science A.
- AP English Language and Composition.
- AP United States History.
- AP United States Government and Politics.
- AP Psychology.

Expand further when the content is ready. Keep ordinary high-school, AP preparation, and introductory college paths clearly distinguished.

Create original instructional material and practice. Do not repackage a basic course with an AP label.

Each published path needs:
- A truthful description of its current coverage.
- Framework-linked units and learning objectives.
- Substantial explanations and worked examples.
- Original practice with accurate feedback.
- Appropriate source, data, graph, argument, coding, or calculation tasks.
- Constructed-response practice with transparent rubrics where appropriate.
- Review opportunities and saved progress.
- Relevant readings and reliably embedded videos when available.
- Current framework references.

Show incomplete coverage plainly. Unavailable units cannot count as completed content or appear fully playable.

Do not present a short quiz as a full AP practice exam or convert its result into a predicted official score.

Written responses may use a rubric and student self-review if reliable automated assessment is not implemented. Do not fabricate precise grading.

Label these paths as independent AP preparation. Verify current College Board trademark and usage guidance. Do not claim authorization, endorsement, official exam status, or college credit without the corresponding evidence.

Verify school-specific AP offerings from current school catalogs or the AP Course Ledger before connecting a school to a particular AP course. Keep “available in this app” separate from “offered by your school.”

Primary starting points:
https://apcentral.collegeboard.org/courses
https://apcentral.collegeboard.org/courses/ap-course-audit


18C. MAKE DELAWARE STANDARDS ALIGNMENT AUDITABLE

Delaware alignment should become a defensible product advantage.

AP frameworks and Delaware standards are separate references. Offering AP preparation does not automatically establish state alignment.

Consult the current Delaware Department of Education standards and the standards documents it adopts or links. Verify the applicable subject, grade band, identifier, and edition.

Starting point:
https://education.delaware.gov/?page_id=15145

Build a standards registry and crosswalk connecting actual lesson and assessment content to the relevant standards.

Record:
- Standards body and framework.
- Subject and grade band.
- Exact published identifier, where one exists.
- Source document and URL.
- Edition or effective date.
- A concise description or permitted excerpt.
- Linked lesson objectives.
- Linked questions and activities.
- A rationale explaining what students do that addresses the standard.
- Coverage status.
- Review status and date.

Where a framework does not publish stable identifiers, use a documented internal reference tied to a specific source location. Do not invent official-looking codes.

For science, map the actual demands of the applicable performance expectations, practices, core ideas, and crosscutting concepts. A paragraph mentioning a topic does not establish full performance-expectation coverage.

For mathematics, literacy, and social studies, map the actual reasoning and work required. A shared topic name is insufficient.

Support these distinctions:
- Related topic.
- Partially addresses the standard.
- Addresses the identified requirement within the published module.
- Educator reviewed, only after an actual review.

Keep content coverage separate from a student's mastery estimate.

Offer a compact “Standards & skills” entry on course pages. Let students, teachers, and reviewers inspect the evidence without filling normal lessons with compliance copy.

Publish a readable coverage report. Show denominators, exclusions, and incomplete areas wherever percentages are used.

Choose public wording that matches the evidence:
- “Mapped to selected Delaware standards” for verified selected coverage.
- A more specific subject or grade-band claim when appropriate.

Do not claim that all courses follow all Delaware standards when the crosswalk covers only selected modules.

Do not imply Delaware Department of Education approval or certification.

Validate that every alignment reference resolves, every linked activity exists, and every public claim can be traced to the registry.

Make the actual work strong enough to support confident demonstrations and school conversations.


18D. CREATE A STUDY SOUND LIBRARY

Add a well-designed sound area connected to the learning experience.

Offer:
- Silence.
- White noise.
- Pink noise.
- Brown noise.
- Rain.
- Ocean or shoreline.
- A restrained natural ambience.

Implement fewer environments well before expanding. Each visible sound must play reliably.

Use licensed recordings or properly implemented audio synthesis. Keep provenance and license information.

Provide:
- Quick preview.
- Play and pause.
- A readable level control.
- Favorites.
- Saved preferences.
- Gentle start and stop fades.
- Optional sleep or session-end stop behavior.
- Clear handling of interruptions and headphone disconnection.
- Configurable behavior when lesson video or other audio starts.

Avoid loud previews, abrupt loop seams, clipping, and unexplained volume changes.

Do not autoplay sound on first launch. Let students explicitly choose silence.

The sound area must share the product's identity. Avoid building a disconnected meditation-app template.

Use small original visual treatments for sound categories. Keep the audio controls easy to understand.

If mixing is implemented, keep layer levels stable and prevent combined signals from clipping. Do not add a decorative mixer that fails to control real playback.


18E. ADD A DISCREET RESEARCH AND SOURCES ENTRY

Place a legible “Research & sources” or “About these sounds” action in a corner of the sound-library header or its About menu.

Keep it available without adding explanatory paragraphs across the sound-selection screen.

The research view should include:
- The question each source investigated.
- Participants and study context.
- Findings relevant to the feature.
- Important limitations.
- Links to the original publication.
- Publication date and last review date.
- Which product decision the evidence informed.

Separate published evidence from our implementation choices and from student preferences.

Investigate research on background sound, attention, learning tasks, and breaks. Read the actual methods and findings before making a claim.

A useful starting review is:
Nigg and colleagues, 2024:
https://pubmed.ncbi.nlm.nih.gov/38428577/

A useful primary experimental study to assess alongside broader evidence is:
Rijmen and Wiersema, 2024:
https://pubmed.ncbi.nlm.nih.gov/39034029/

Research does not establish one universally optimal noise for learning. Effects can differ across individuals, tasks, and experimental conditions.

Do not generalize results from a particular participant group to all students.

Do not transfer evidence for white or pink noise to brown noise, natural ambience, or every product preset.

Use “Research-informed” only when a specific design decision has a documented basis. Do not label the app, every sound, or its learning outcomes “scientifically proven.”

Do not claim our app was validated by a published study unless the study actually tested it.

Allow students to record a simple optional preference after sessions. Treat this as their experience, not a clinical assessment or proof that a sound improves academic performance.

Keep research detail in the dedicated view. A short, accurate explanation belongs there:
“Sound affects people differently. Explore the research and choose what works for your study session.”

Investigate break research separately. Do not claim that the conventional 25/5 Pomodoro schedule is a scientifically optimal interval for every student.


18F. BUILD CONFIGURABLE FOCUS MODE

Focus mode is the session behavior that reduces distractions and supports studying.

It should work with a lesson, a task, independent study, or AP practice.

Before starting, let students configure:
- Task or course.
- Session duration.
- Sound or silence.
- In-app interruptions.
- Break reminders.
- Completion sound and haptics.
- Automatic break behavior.
- Whether to enter Zen mode.
- Whether to keep the display awake during Zen.
- Preferred supported iOS Focus setup.

Remember preferences while making the current session's settings easy to inspect.

Suppress this app's nonessential banners, prompts, celebrations, and reminders during Focus according to the student's settings.

Let students choose whether session-end and break alerts remain enabled. Notification permission must not be required to run the timer.

Respect iOS boundaries:
- Ordinary apps cannot arbitrarily silence other apps or configure the user's allowed contacts.
- Focus-status APIs do not enable system Focus or prove a particular notification policy.
- App Focus Filters affect supported app behavior; they are not a system-wide mute switch.
- Device-wide notification rules belong to the user's iOS Focus configuration.

Provide a concise setup flow explaining how to configure an iOS Study Focus with allowed people, allowed apps, and desired exceptions.

Explore supported, user-configured Shortcuts or App Intents integration where it produces a reliable workflow. Do not use private Settings URLs or unsupported automation.

Show “system Focus unknown” or appropriate setup guidance when the app cannot verify the state. A running study timer must not create a false “all notifications blocked” badge.

Do not overwrite an existing system Focus or turn off a Focus the app did not establish through a supported user-controlled workflow.

Make timer-only, silence-only, and no-permission workflows complete and useful.


18G. IMPLEMENT A RELIABLE POMODORO TIMER

Provide a default study cycle of:
- 25 minutes of work.
- 5 minutes of short break.
- A configurable long break after a configurable number of work intervals.

Treat these as editable defaults.

Support custom durations and a longer-session preset.

Include:
- Start.
- Pause and resume.
- Finish early.
- Skip a break.
- Restart with confirmation when progress would be discarded.
- Work and break phase labels.
- Cycle count.
- Optional sound and haptics.
- Optional automatic transitions.

Use one shared session engine for normal Focus and Zen mode. Opening Zen must not create a second timer.

Persist sufficient session state to recover accurately after backgrounding or relaunch.

Do not depend on a one-second UI timer continuing to execute while iOS suspends the app. Compute remaining time from an appropriate timing model, use persisted deadlines where needed, and handle clock changes deliberately.

Prevent duplicated completion events, overlapping sessions, and duplicated local notifications.

Explain elapsed phases honestly after a long absence. Do not assume that every automatically scheduled interval represents actual study.

Record actual session duration, pauses, linked task, and completion state.

Focused minutes and academic mastery are different measures. Leaving a timer running must not mark lessons learned or inflate question performance.

Reward meaningful activity without penalizing students for pausing or ending early.

Keep the timer available from relevant course, task, and study screens without duplicating its state.


18H. DESIGN ZEN MODE AS A LANDSCAPE DESK DISPLAY

Use the supplied photo as a reference for the viewing situation:
a phone resting horizontally on a desk, showing large expressive numerals against a dark background.

Create an original branded display. Do not reproduce Apple's clock artwork, numeral design, or system interface.

Zen is an immersive presentation of the existing Focus session.

The Pomodoro countdown is the dominant element.

Build a landscape composition with:
- Large, beautifully composed remaining time.
- A restrained work or break indicator.
- Optional current task or course.
- Optional upcoming tasks.
- Subtle session progress.
- Minimal controls that appear on tap.

Upcoming tasks must be hideable with one clear action. Remember that preference.

Timer-only mode must feel complete.

When tasks are visible:
- Show only a small number.
- Keep the current task easy to distinguish.
- Use the student's saved tasks.
- Allow selection or completion without disturbing the timer.
- Do not invent deadlines or upcoming work.

Support both landscape directions and a considered portrait fallback. Respect the notch, Dynamic Island, safe areas, and readable proportions.

ENVIRONMENTS

Create at least three visually distinct, restrained environments derived from the selected brand.

Possible directions:
- A dark observatory with a slow horizon.
- A coastal dusk treatment connected subtly to Delaware.
- Warm light moving across an abstract architectural surface.

Choose and art-direct the final environments yourself.

Avoid a generic particle field or endlessly animated gradient.

The environment sits behind the session; the countdown remains the visual anchor.

Let students choose:
- Environment.
- Static or subtle motion.
- Readable numeral color.
- Sound preset or silence.
- Upcoming-task visibility.
- Current-task visibility.
- Optional wall clock.
- Night treatment.
- Keep-awake behavior.

Keep audio and visual choices independently configurable.

Do not switch audio merely because the student rotates the device.

INTERACTION

Tapping reveals compact controls. After inactivity, secondary controls can recede.

Pause, sound, task visibility, and exit must remain easy to discover.

Exiting Zen should return to the running session. Ending the session is a separate explicit action.

Use deliberate transitions into work and break phases. Avoid flashes, constant pulsing, distracting particles, and repeated celebrations.

Respect Reduce Motion and provide a static environment.

PLATFORM AND POWER

Zen runs as an in-app display. Do not claim it replaces the iOS Lock Screen, Apple StandBy, or system Always-On behavior.

Keep-awake behavior is optional and applies only where supported while the app is active. Restore normal behavior when leaving the relevant state.

Use efficient graphics and avoid continuous high-cost rendering.

Do not silently force maximum brightness or alter device-wide display preferences. If temporarily adjusting brightness through supported APIs, make the choice explicit and restore it appropriately.

Reduce persistent bright elements and offer a dim treatment suitable for a desk session.

Separate Simulator verification from physical-device evidence for rotation, audio interruptions, display behavior, energy use, and long-running sessions.


18I. INTEGRATE AND VERIFY THE NEW STUDY SYSTEM

Connect the academic and focus features into one coherent journey:

1. Choose a regular, AP-preparation, or college path.
2. Inspect its scope and relevant standards.
3. Select a lesson or personal task.
4. Configure a Focus session.
5. Choose sound or silence.
6. Optionally use the supported system Focus workflow.
7. Enter Zen and place the phone horizontally.
8. Study with the countdown prominent and tasks optionally hidden.
9. Take or skip a break.
10. Resume learning and review saved session activity.

Do not force students to use sound, a timer, Zen, or system Focus to access coursework.

Verify:
- Published AP content has actual instructional depth.
- AP and Delaware mappings resolve to current source documents.
- Coverage labels match implemented content.
- Research claims match the cited participants and findings.
- Every sound works and settings persist.
- Focus respects the selected in-app notification behavior.
- Denied notification permissions do not break studying.
- The timer survives pause, backgrounding, relaunch, and interruptions.
- Completion is recorded exactly once.
- Rotation preserves the session.
- Tasks can be hidden and restored.
- Zen exit preserves an ongoing timer.
- Static environments work with Reduce Motion.
- Keep-awake behavior ends correctly.
- No screen falsely claims that other apps were silenced.

Include the new surfaces in screenshot review and document physical-device checks that remain outstanding.


19. DEVELOP A CONSISTENT MOTION LANGUAGE

Set motion rules for:
- Press feedback.
- Navigation.
- Inline expansion.
- Progress changes.
- Header transformation.
- Achievement reveals.
- Loading.

Choose timing according to purpose.

Keep controls responsive during animation.

Avoid adding spring motion to everything.

Do not stagger every element when a screen appears. Repeated entrance animations quickly become tiring.

Use continuity to explain where information moves.

Remove unnecessary continuous animation.

Check the experience with Reduce Motion enabled.


20. EDIT EVERY PIECE OF INTERFACE COPY

Write concise, specific language.

Prefer direct actions:
“Resume lesson.”
“Review answers.”
“Add a note.”
“Compare colleges.”

Remove:
- Repeated subtitles.
- Generic motivation.
- Descriptions of obvious controls.
- Decorative helper paragraphs.
- Technical implementation details.
- Claims unsupported by product behavior.

Keep explanations where students need them to learn, understand consequences, or recover from an error.

Use a consistent voice across onboarding, empty states, rewards, errors, and sharing.

Do not advertise intelligence, personalization, or social activity that the app does not provide.


21. CREATE ORIGINAL ASSETS WITH DISCIPLINE

Decide which elements should be:
- SwiftUI shapes.
- Vector assets.
- Custom diagrams.
- Raster artwork.
- Standard system icons.

Use code or vectors for precise geometry and interface marks.

Use generated or illustrated artwork only when it adds clear value to the brand.

Maintain visual consistency across assets.

Check every asset in light and dark appearances.

Avoid adding large decorative images that make the app slower or push useful content out of view.

Keep asset licensing and attribution accurate.


ENFORCE UI/UX PRINCIPLES THROUGH IMPLEMENTATION AND REVIEW

Apply established usability principles to actual layouts and interactions. Treat them as design constraints with observable results. Do not use their names as a substitute for good judgment.

Preserve our original identity while making the product understandable, efficient, and predictable.

1. JAKOB’S LAW — FAMILIAR INTERACTION

Use familiar behavior for navigation, search, playback, editing, forms, and selection.

Express originality through composition, graphics, typography, and meaningful transitions.

Requirements:
- Back navigation behaves consistently.
- Search looks and works like search.
- Interactive elements have recognizable affordances.
- Standard gestures retain their expected behavior.
- Custom controls remain understandable without instructions.

Do not require students to learn an unfamiliar interaction just to complete an ordinary task.

2. HICK–HYMAN LAW — MANAGE CHOICES

Reduce the effort required to choose between options.

Organize large collections through meaningful categories, search, filters, and useful defaults.

Requirements:
- Each screen has a clear primary action.
- Advanced settings appear when relevant.
- Course filters support quick narrowing.
- Focus setup offers a ready-to-use default.
- Sound selection supports previews and favorites.
- Related settings stay together.

Do not hide frequently used controls merely to reduce the number of visible choices.

3. FITTS’S LAW — MAKE ACTIONS EASY TO REACH

Size and position controls according to their frequency and importance.

Requirements:
- Aim for at least 44 × 44-point touch targets for ordinary interactive controls.
- Small visual icons may use larger invisible hit areas.
- Frequently used actions sit within comfortable reach.
- Adjacent controls have enough separation to prevent mistakes.
- Destructive actions are separated from routine actions.
- Zen controls remain usable when the phone rests horizontally.

Comfortable hit targets must coexist with refined visual density.

4. GESTALT PRINCIPLES — MAKE RELATIONSHIPS VISIBLE

Use proximity, similarity, continuity, and common regions to explain relationships.

Requirements:
- Labels sit close to their values and controls.
- Related lesson information forms a coherent group.
- Course metadata follows a consistent structure.
- Unrelated sections have clear separation.
- Selection is distinguishable from grouping.
- Alignment establishes a predictable reading order.

Do not wrap every group in a card. Spacing, alignment, and typography can establish structure.

5. RECOGNITION OVER RECALL — KEEP CONTEXT AVAILABLE

Students should recognize their options without remembering information from another screen.

Requirements:
- Show the active course and current lesson where relevant.
- Keep selected filters visible.
- Provide descriptive labels for ambiguous icons.
- Preserve useful context when returning from a detail screen.
- Show Focus settings before starting a session.
- Make prerequisites and completion requirements inspectable.

Avoid onboarding explanations that users must remember to operate the interface later.

6. VISIBILITY OF SYSTEM STATUS — SHOW WHAT IS HAPPENING

Every meaningful action needs appropriate feedback.

Requirements:
- Buttons visibly respond to interaction.
- Saving, loading, submitting, playback, and timer states are distinguishable.
- Paused and running timers cannot be confused.
- Completed work appears in progress consistently.
- Unavailable media offers a clear recovery action.
- System Focus status is represented accurately, including when it is unknown.

Feedback must remain readable without constant animation.

Never display success before the operation succeeds.

7. USER CONTROL AND FREEDOM — MAKE ACTIONS REVERSIBLE

Let students leave, correct, pause, and change their minds.

Requirements:
- Editing supports cancel or appropriate undo.
- Ending a session is separate from leaving Zen.
- School selection can be changed or removed.
- Audio can be stopped immediately.
- Upcoming tasks can be hidden and restored.
- Destructive actions explain what will be removed.
- Unsaved work receives proportionate protection.

Use confirmation dialogs for meaningful consequences, not every routine action.

8. ERROR PREVENTION AND RECOVERY — DESIGN FOR MISTAKES

Prevent avoidable errors before showing error messages.

Requirements:
- Prevent duplicate answer submissions and timer completions.
- Explain invalid input near the affected field.
- Preserve student work after recoverable failures.
- Make disabled actions understandable when the reason is not obvious.
- Provide a specific next step when something fails.
- Keep technical error details out of ordinary student-facing copy.

Do not use vague messages such as “Something went wrong” without a useful recovery path.

9. CONSISTENCY — GIVE COMPONENTS STABLE MEANINGS

The same action, state, and component should behave consistently throughout the app.

Requirements:
- Shared controls use shared components where appropriate.
- Button hierarchy remains stable.
- Selection, completion, availability, and errors have consistent treatments.
- Terminology stays consistent across coursework, Focus, Profile, and College.
- Similar gestures produce similar results.

Consistency does not require identical screen layouts. Compose each screen around its purpose.

10. PROGRESSIVE DISCLOSURE — REVEAL DEPTH AT THE RIGHT TIME

Keep the core experience immediately usable while making detail accessible.

Requirements:
- Standards mappings open from a concise course entry.
- Research belongs in a dedicated sound-library view.
- Detailed statistics appear when students inspect progress.
- Advanced timer settings remain accessible without dominating setup.
- Essential playback and session controls never depend on obscure gestures.

Students must be able to discover additional functionality through visible cues.

11. RESPONSE TIME AND CONTINUITY — KEEP THE APP RESPONSIVE

Provide immediate local feedback and preserve continuity during longer operations.

Requirements:
- Do not block navigation for decorative animation.
- Allow interaction while nonessential transitions finish.
- Use progress indicators when waiting is meaningful.
- Prevent layout jumps as content loads.
- Maintain stable scroll position where practical.
- Avoid showing a spinner for work that completes immediately.
- Measure slow interactions instead of assuming they feel fast.

Use timing thresholds as practical heuristics, not universal guarantees.

12. AESTHETIC–USABILITY EFFECT — MAKE BEAUTY SUPPORT USE

Visual polish can influence perceived usability. Verify actual task performance separately.

Requirements:
- Decorative graphics never obscure content.
- Materials preserve contrast over every background.
- Motion explains transitions or acknowledges actions.
- Typography supports reading and scanning.
- Brand elements remain recognizable without overwhelming the task.

An attractive screenshot cannot compensate for confusing navigation or broken controls.

13. POSTEL’S LAW — ACCEPT REASONABLE INPUT

Handle ordinary variation in user input gracefully while preserving clear rules.

Requirements:
- Trim accidental leading and trailing whitespace.
- Support reasonable search capitalization and verified school-name aliases.
- Accept valid input formats appropriate to the field.
- Explain requirements before submission when they matter.
- Preserve the student’s intended text.

Do not silently reinterpret ambiguous dates, assessment answers, or consequential settings. Ask for clarification within the interface.

14. ACCESSIBLE PERCEPTION — COMMUNICATE IN MORE THAN ONE WAY

Make information perceivable without relying solely on color, motion, sound, or visual position.

Requirements:
- Use WCAG contrast ratios as practical targets: 4.5:1 for normal text and 3:1 for qualifying large text.
- Give meaningful controls and state indicators sufficient contrast.
- Pair color-coded results with labels or symbols.
- Support Dynamic Type without losing essential actions.
- Provide useful VoiceOver labels and reading order.
- Respect Reduce Motion.
- Keep timers usable without audio or haptics.
- Keep audio features usable without animation.

Maintain a refined default interface while supporting different access needs.

15. ETHICAL ENGAGEMENT — SUPPORT THE STUDENT’S GOAL

Use rewards and reminders to support learning.

Requirements:
- Make leaving and pausing straightforward.
- Keep notification preferences configurable.
- Avoid guilt-based streak language.
- Do not manufacture urgency.
- Do not use fake activity or social proof.
- Distinguish time spent from demonstrated understanding.
- Do not make optional sharing necessary to earn core progress.

Students should finish a session feeling informed and in control.

MANDATORY DESIGN REVIEW

For each major screen, verify:
- Its purpose is clear.
- The primary action is easy to identify.
- Essential information is visible.
- Related content is grouped coherently.
- Controls are recognizable and reachable.
- Current state is understandable.
- Errors have a recovery path.
- Leaving or reversing an action is straightforward.
- Text and controls remain readable in both appearances.
- The screen works at normal device size and with larger text.

Exercise complete tasks rather than checking isolated components.

Review at least:
- Finding and starting a course.
- Completing and reviewing a question.
- Starting, pausing, and resuming Focus.
- Entering and leaving Zen.
- Hiding and restoring upcoming tasks.
- Selecting and stopping a sound.
- Changing a school.
- Inspecting an achievement.
- Recovering from unavailable media or denied permissions.

Document concrete usability issues and fix them before polishing secondary decoration.

If these principles conflict, explain the task-specific tradeoff and choose the solution that best supports the student. Do not claim that a design “follows all UX laws” merely because it passes a checklist.


22. IMPLEMENT IN A COHERENT ORDER

Begin with repository inspection and a brief, concrete design diagnosis.

Then:
1. Select the name and central brand concept.
2. Establish design tokens and core components.
3. Redesign Home, the library, and Profile as the defining screens.
4. Review those screens together and correct inconsistencies.
5. Extend the system through courses, lessons, practice, Community, College, awards, onboarding, and settings.
6. Research and integrate the Delaware school directory and its functional benefits.
7. Complete empty and error states.
8. Verify navigation, persistence, and motion.
9. Build, launch, inspect, and refine.

Do not stop after redesigning the first three screens.

Do not ask me to approve ordinary spacing, typography, palette, or component decisions. Make informed choices and provide a coherent result.

Ask only when a missing decision would materially change product scope or require new external authority.


23. PRESERVE TECHNICAL QUALITY

Keep working educational logic and saved progress intact.

Inspect migration requirements before changing persisted models.

Avoid introducing dependencies for effects that native SwiftUI can handle well.

Keep scroll performance and view identity stable.

Handle app backgrounding, interrupted sessions, and playback transitions appropriately.

Ensure custom controls retain clear accessibility labels and usable focus order.

Run tests appropriate to the changes. Test behavior that matters rather than creating brittle assertions for arbitrary layout values.

Resolve build errors and obvious regressions before presenting the result.


24. REVIEW THE APP AS A PRODUCT

Inspect screenshots and actual interactions at normal device size.

Evaluate the screens together.

Ask:
- Is the identity recognizable without the logo?
- Does each screen have a clear purpose?
- Are the compositions varied for a reason?
- Is the main action visible?
- Are course titles easy to scan?
- Can a student understand their progress?
- Does the profile reflect actual work?
- Does the header transform smoothly?
- Are text and controls readable in both appearances?
- Does the interface remain useful with larger text?
- Do visible controls perform their stated action?
- Are empty states honest and useful?
- Does the brand remain coherent during quiet reading and active practice?
- Does selecting a Delaware school provide practical value?
- Are school details verified and affiliation represented accurately?
- Can students outside Delaware use the app equally well?

If a screen could belong to any generic productivity app after changing its title, reconsider its composition.

If a visual effect makes the task harder, simplify it.

If a component is repeated because it was convenient to build, check whether it actually belongs everywhere it appears.


25. COMPLETION REQUIREMENTS

Finish with an implemented app that includes:
- A selected original name.
- A coherent brand identity.
- Updated visible branding and app icon.
- A reusable design system.
- Original subject graphics.
- Distinctive academic achievements.
- Redesigned primary screens.
- Working scroll transformations.
- Purposeful interaction motion.
- Readable light and dark appearances.
- Preserved educational functionality and saved progress.
- A verified Delaware high-school directory with documented coverage.
- Optional private school selection.
- Working school resources and subject connections.
- Student-controlled learning or college-planning summaries.
- Useful shareable activities for classmates, teachers, or clubs.
- Substantive independent AP preparation with framework references.
- An auditable Delaware standards crosswalk and accurate coverage claims.
- A working study sound library with a discreet Research & sources view.
- Configurable Focus behavior and an honest iOS Focus setup workflow.
- A persistent, reliable Pomodoro session engine.
- Original landscape Zen environments with an emphasized timer and hideable tasks.

Build and launch the latest version in the iOS Simulator.

Exercise the main student journey and inspect the result visually. Correct clipping, awkward wrapping, poor contrast, repeated layouts, and broken interactions before finishing.

Report briefly:
- The selected name and its meaning.
- The central visual concept.
- The most significant implemented changes.
- How Delaware students and schools can benefit.
- School-directory coverage and sources.
- What you verified.
- Any remaining functional or release limitations.

Treat 2027 as our launch ambition. Make the product distinctive through considered decisions, original assets, useful interactions, and consistent execution.

Take responsibility for the final quality.
