# DelaStudy · code walkthrough presenter notes

The silent video is 2:48. The phone recording is unchanged. The Mac-style
code windows use source excerpts directly from this project.
The newer handheld edition uses the same timing, with an illustrated hand and
iPhone 14 Pro-style frame around the Simulator footage. It is not physical-device
footage or evidence of new Dynamic Island functionality.
The webcam-ready edition keeps the code lower on the right, leaving the space
above it empty for your webcams; the speaking times are unchanged.
You can divide the parts below between M'hamed and two teammates, or swap roles.
Read the quoted lines, not the headings or source references.

## 0:00–0:10 · M'hamed

> Hi, I'm M'hamed. This is DelaStudy. We'll walk through the app and explain some of the code behind it.

## 0:10–0:25 · Teammate 1 · finding a course

> The Library filters one course collection instead of needing separate pages for every subject. This code combines the subject, course level, saved courses, and search text to decide what appears.

Code: [CourseCatalogView.swift](/Users/machi/cac2026/cac2026/FirstStateLens/CourseCatalogView.swift:16), lines 16–23. The highlighted `filter` is the entry point; each condition narrows the results.

## 0:25–0:35 · M'hamed · course layout

> Each course has five selected units. The course page shows the sequence and gives me a direct way to start the next lesson.

## 0:35–0:53 · Teammate 2 · saved lesson position

> Lessons explain one idea at a time. When I move forward or backward, this function checks the step and saves the new position first. If saving fails, it stops before changing the visible lesson.

Code: [BiteLessonView.swift](/Users/machi/cac2026/cac2026/FirstStateLens/BiteLessonView.swift:108), lines 108–114. The second `guard` prevents a visible move when persistence fails.

## 0:53–1:18 · M'hamed · checking an answer

> Practice includes multiple choice, fill-in-the-blank, and matching. This function uses the current question stage to choose the right answer check. A wrong answer records another attempt, then the feedback state changes to show the result. The first guard prevents checking the same answer twice while feedback is already showing.

Code: [ReadingCheckView.swift](/Users/machi/cac2026/cac2026/FirstStateLens/ReadingCheckView.swift:176), lines 176–184. `progress.cleared` selects the question type; `feedbackTick` helps trigger the feedback interaction.

## 1:18–1:36 · Teammate 1 · resource dropdowns

> Resources are separate from the lesson. Each category filters its own items. Tapping a category toggles the expanded state, and SwiftUI animates the change. The animation is disabled when Reduce Motion or quiet Focus is active.

Code: [CourseResourcesView.swift](/Users/machi/cac2026/cac2026/FirstStateLens/CourseResourcesView.swift:12), lines 12–18. Setting `expanded` to `nil` closes the category; setting it to `kind` opens that one.

## 1:36–1:48 · Teammate 2 · sources and limits

> The civics material references Delaware Public Archives. A separate Algebra module shows a published partial standards mapping. Those limits matter: this is practice, not a claim of state approval.

No code overlay here, so the source credits and mapping stay in view.

## 1:48–1:58 · M'hamed · saving a task

> The planner saves a specific next step. This shared function copies the current snapshot, applies a workspace change, and passes it to the save routine.

Code: [AppModel.swift](/Users/machi/cac2026/cac2026/FirstStateLens/AppModel.swift:345), lines 345–350. `commit` performs the save and reports success or failure; this is local persistence, not cloud sync.

## 1:58–2:18 · Teammate 2 · timer behavior

> Focus includes a timer, optional sound, and a quieter Zen view. The remaining time comes from a deadline, rather than subtracting one every time the screen updates. Pausing stores the remaining time and clears that deadline, so the pause state is explicit.

Code: [Workspace.swift](/Users/machi/cac2026/cac2026/Sources/FirstStateCore/Workspace.swift:170), lines 170–182. The deadline model does not require continuous background screen updates. This recording is not physical-device background verification.

## 2:18–2:30 · Teammate 1 · achievement progress

> The profile shows earned progress. Each achievement compares its current count with a target. This condition unlocks it, and the fraction gives the interface a progress value that stops at one.

Code: [LearnerMetrics.swift](/Users/machi/cac2026/cac2026/Sources/FirstStateCore/LearnerMetrics.swift:11), lines 11–20. These are computed values, not a prefilled unlock flag.

## 2:30–2:40 · M'hamed · college planning

> College planning has a saved checklist. Tapping an item adds or removes its identifier, then commits the updated snapshot. It's reversible, not just a decorative checkmark.

Code: [AppModel.swift](/Users/machi/cac2026/cac2026/FirstStateLens/AppModel.swift:195), lines 195–200.

## 2:40–2:48 · M'hamed · close

> That's DelaStudy: short lessons, useful practice, saved progress, and tools that make the next study session easier to start.

## Recording together

Play the video from the beginning, hide the player's controls, and record the
screen with your microphone. Pause playback if you want a longer code explanation;
that will make your final recording longer than 2:48. The original nontechnical
narration remains available separately, but these notes match the code edition.
The code windows are presentation overlays, not an in-app feature or a recording
of an interactive Mac editor.
