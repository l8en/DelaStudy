"""Side-panel-only edition of the approved 135-second DelaStudy walkthrough."""
import copy
import json
from pathlib import Path

folder = Path("Demo/Showcase")
original = json.loads((folder / "waffles-edit-manifest.json").read_text())
manifest = copy.deepcopy(original)
manifest["basePresentation"] = str((folder / "DelaStudy-Walkthrough-2m15.mp4").resolve())
manifest["codePopups"] = [
    dict(sourcePath="FirstStateLens/BiteLessonView.swift", firstLine=109, lastLine=115,
         start=41.4, end=50.8, highlightLines=[112, 114]),
    dict(sourcePath="FirstStateLens/RootView.swift", firstLine=61, lastLine=64,
         start=116.4, end=126.8, highlightLines=[61, 62, 64]),
]


def node(key, label, x, y, width=220, height=58, detail=None, shape=None, active=None):
    value = dict(id=key, label=label, x=x, y=y, width=width, height=height)
    if detail: value["detail"] = detail
    if shape: value["shape"] = shape
    if active: value.update(activeFrom=active[0], activeUntil=active[1])
    return value


def edge(source, target, points=None, arrow=True):
    value = dict(from_=source, to=target, arrow=arrow)
    value["from"] = value.pop("from_")
    if points: value["points"] = points
    return value


def diagram(key, title, impact, start, end, nodes, edges, height=340):
    return dict(id=key, title=title, impact=impact, start=start, end=end,
                width=900, height=height, nodes=nodes, edges=edges)


manifest["diagramPopups"] = [
    diagram("personal_plan", "Your choices become a saved plan",
            "Your next visit starts with your choices", 6.4, 27.8,
            [node("grade", "Grade + goal", 0, 58, active=(6.6, 11)),
             node("subjects", "Subjects + route", 0, 140, active=(11, 16)),
             node("school", "School + rhythm", 0, 222, active=(16, 22)),
             node("join", "", 276, 166, 10, 10, shape="junction"),
             node("plan", "Saved plan", 360, 133, 240, 76, detail="On this iPhone", active=(22, 24)),
             node("today", "Today", 690, 142, 206, 58, active=(24, 27.8))],
            [edge("grade", "join", [[220,87],[281,87],[281,171]], False),
             edge("subjects", "join", [[220,169],[281,169],[281,171]], False),
             edge("school", "join", [[220,251],[281,251],[281,171]], False),
             edge("join", "plan", [[281,171],[360,171]]), edge("plan", "today")]),
    diagram("course_discovery", "Find the right course path",
            "Choose a level, then search a course", 28.3, 35.8,
            [node("high", "High school", 0, 66, 240, 66, active=(33,35.8)),
             node("ap", "AP preparation", 325, 66, 240, 66, active=(29,31)),
             node("college", "Intro college", 650, 66, 240, 66, active=(31,33)),
             node("join", "", 440, 167, 10, 10, shape="junction"),
             node("search", "Course search", 310, 218, 270, 62, active=(34,35.8))],
            [edge("high", "join", [[120,132],[120,172],[445,172]], False),
             edge("ap", "join", [[445,132],[445,172]], False),
             edge("college", "join", [[770,132],[770,172],[445,172]], False),
             edge("join", "search", [[445,172],[445,218]])]),
    diagram("course_structure", "Five units. A visible course path.",
            "5 units × 6 activities = 30 activities", 36.3, 40.8,
            [node(f"unit{i}", f"Unit {i}", (i-1)*174, 110, 150, 80,
                  detail="6 activities", active=(36.5,40.8) if i == 1 else None) for i in range(1,6)],
            [edge(f"unit{i}", f"unit{i+1}") for i in range(1,5)], height=300),
    diagram("practice_loop", "Use the idea. Get feedback. Save the work.",
            "A completed activity awards its XP only once", 51.4, 73.8,
            [node("mcq", "Multiple choice", 0, 60, 205, 50, active=(51.6,55)),
             node("blank", "Fill the blank", 0, 136, 205, 50, active=(55,59)),
             node("match", "Matching", 0, 212, 205, 50, active=(59,69)),
             node("join", "", 251, 161, 10, 10, shape="junction"),
             node("feedback", "Feedback", 330, 130, 220, 72, detail="Check the idea", active=(67,69)),
             node("save", "Save activity", 660, 130, 220, 72, detail="XP awarded once", active=(69,73.8))],
            [edge("mcq", "join", [[205,85],[256,85],[256,166]], False),
             edge("blank", "join", [[205,161],[256,161],[256,166]], False),
             edge("match", "join", [[205,237],[256,237],[256,166]], False),
             edge("join", "feedback", [[256,166],[330,166]]), edge("feedback", "save")]),
    diagram("resource_tree", "Extra depth has its own place",
            "Go deeper without interrupting a short lesson", 74.3, 82.8,
            [node("resources", "Resources", 0, 136, 220, 62),
             node("join", "", 326, 163, 8, 8, shape="junction"),
             node("books", "Textbooks", 430, 58, 330, 60, active=(74.5,77)),
             node("readings", "Full readings", 430, 137, 330, 60, active=(77,80)),
             node("videos", "Videos", 430, 216, 330, 60, active=(80,82.8))],
            [edge("resources", "join", [[220,167],[330,167]], False),
             edge("join", "books", [[330,167],[330,88],[430,88]]),
             edge("join", "readings", [[330,167],[430,167]]),
             edge("join", "videos", [[330,167],[330,246],[430,246]])]),
    diagram("college_steps", "College preparation, made concrete",
            "Small steps toward a college plan", 83.3, 89.8,
            [node("fields", "Explore fields", 0, 110, 260, 80, active=(83.5,89.8)),
             node("costs", "Compare routes", 310, 110, 260, 80),
             node("counselor", "Ask a counselor", 620, 110, 260, 80)],
            [edge("fields", "costs"), edge("costs", "counselor")], height=300),
    diagram("task_to_focus", "Turn an intention into a session",
            "Carry the same task into focused study", 90.3, 95.8,
            [node("goal", "Study goal", 0, 110, 260, 80, detail="Review angles"),
             node("task", "Saved task", 310, 110, 260, 80, active=(91,95.8)),
             node("focus", "Focus session", 620, 110, 260, 80)],
            [edge("goal", "task"), edge("task", "focus")], height=300),
    diagram("sound_states", "Playback you can see",
            "Reduce Motion keeps the indicator static", 96.4, 105.8,
            [node("play", "Play", 0, 66, 220, 58, active=(96.6,100.6)),
             node("moving", "Moving waves", 410, 66, 330, 58, active=(96.6,100.6)),
             node("pause", "Pause", 0, 202, 220, 58, active=(100.6,102.6)),
             node("still", "Still waves", 410, 202, 330, 58, active=(100.6,102.6))],
            [edge("play", "moving"), edge("pause", "still")]),
    diagram("zen_layout", "Zen keeps the timer central",
            "Keep the timer. Hide upcoming tasks.", 106.3, 112.8,
            [node("timer", "Pomodoro", 0, 95, 160, 150, shape="circle", active=(106.5,112.8)),
             node("current", "Current task", 390, 70, 300, 70),
             node("upcoming", "Upcoming tasks", 390, 206, 300, 70, detail="Show or hide", active=(109,112.8))],
            [edge("timer", "current", [[160,170],[270,170],[270,105],[390,105]]),
             edge("timer", "upcoming", [[160,170],[270,170],[270,241],[390,241]])]),
    diagram("earned_progress", "Progress comes from completed work",
            "Replaying a completed activity does not duplicate XP", 127.4, 134.8,
            [node("work", "Saved activities", 0, 110, 260, 80),
             node("xp", "Earned XP", 310, 110, 260, 80, detail="20 XP in this demo", active=(127.6,131)),
             node("level", "Level progress", 620, 110, 260, 80, active=(131,134.8))],
            [edge("work", "xp"), edge("xp", "level")], height=300),
]

assert manifest["shots"] == original["shots"]
assert len(manifest["codePopups"]) == 2
assert sum(s["duration"] for s in manifest["shots"]) == 135
(folder / "explained-edit-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

script = json.loads((folder / "waffles-narration.json").read_text())
script["video"] = "DelaStudy-Explained-2m15.mp4"
script["pageStarts"] = [
    dict(index=0, title="DelaStudy", subtitle="M’hamed  |  0:00–0:41  |  Account, setup & courses"),
    dict(index=5, title="Learn, then use it", subtitle="Ibby  |  0:41–1:36  |  Lessons, practice & planning"),
    dict(index=10, title="Focus and follow through", subtitle="Sai  |  1:36–2:15  |  Sound, notification & progress"),
]
script["instruction"] = "Read only the main narration text. Speaker names, timestamps and ON SCREEN cues are not spoken. Start each line at its timestamp; the wording already explains the diagrams and both code excerpts. No improvisation is needed."
script["author"] = "M’hamed, Ibby and Sai"
reads = [
    "I’m M’hamed. This is DelaStudy, and we’re creating Waffles123’s account.",
    "We choose our grade and a study goal. Next come our subjects and a course direction. Our school and study preferences shape a saved starting plan on this iPhone.",
    "Today brings that plan into one place.",
    "The library separates high school, AP preparation, and introductory college paths. Here, we search for Geometry.",
    "Each course has five units and at least thirty activities.",
    "I’m Ibby. Lessons use three short steps. The code saves our position before advancing, so we can return without losing our place.",
    "Multiple choice checks our understanding of vertical angles. Next, we fill in one hundred eighty degrees. For matching, we drag the first term, then tap the others into place. Feedback follows our answers. Completion saves the activity and awards its XP once.",
    "Resources separate textbooks, full readings, and videos into expandable categories. Extra material stays outside the lesson.",
    "College planning breaks preparation into steps: explore fields, compare routes, and ask a counselor.",
    "We save a specific study task, ready for a Focus session.",
    "I’m Sai. Sounds are optional. Playing animates the colored waves; pausing stops them. There’s also a static option for Reduce Motion.",
    "Zen puts the timer first. We can hide upcoming tasks when we want fewer distractions.",
    "Session-end notifications are optional too. One completion alert appears on the iPhone Home Screen. A tap runs these account and session checks. Only the matching timer opens.",
    "The profile reflects work completed here. That’s DelaStudy: learning, planning, and focused study, connected through saved progress.",
]
for i, (scene, read) in enumerate(zip(script["scenes"], reads)):
    scene["read"] = read
    scene["speaker"] = "M’hamed" if i < 5 else "Ibby" if i < 10 else "Sai"
    scene.pop("segments", None)
script["scenes"][1]["segments"] = [
    dict(start=6, end=11, read="We choose our grade and a study goal."),
    dict(start=11, end=16, read="Next come our subjects and a course direction."),
    dict(start=16, end=24, read="Our school and study preferences shape a saved starting plan on this iPhone."),
]
script["scenes"][6]["segments"] = [
    dict(start=51, end=55, read="Multiple choice checks our understanding of vertical angles."),
    dict(start=55, end=59, read="Next, we fill in one hundred eighty degrees."),
    dict(start=59, end=69, read="For matching, we drag the first term, then tap the others into place. Feedback follows our answers."),
    dict(start=69, end=74, read="Completion saves the activity and awards its XP once."),
]
script["scenes"][12]["segments"] = [
    dict(start=113, end=116, read="Session-end notifications are optional too."),
    dict(start=116, end=121, read="One completion alert appears on the iPhone Home Screen."),
    dict(start=121, end=127, read="A tap runs these account and session checks. Only the matching timer opens."),
]
screen_cues = [
    "Waffles123’s username and masked password; Create account opens setup.",
    "Onboarding; choices merge into a saved local plan.",
    "Today opens; the diagram’s final node highlights.",
    "Browse course levels and search Geometry; three paths converge into search.",
    "Geometry outline; the diagram shows five units with six activities each.",
    "Three lesson steps; code 1 saves the position before changing the step.",
    "MCQ → blank → matching → save; the diagram follows each question type.",
    "Resources dropdowns; textbooks, full readings and videos form a tree.",
    "College checklist; Explore fields of study is checked.",
    "Save Review angle relationships; goal → saved task → Focus session.",
    "Brown noise plays, pauses and resumes; the diagram contrasts both states.",
    "Pomodoro countdown; upcoming tasks can be hidden.",
    "Optional alert setting → Home Screen banner → tap; code 2 validates the account and session.",
    "Waffles123’s 20 XP and Stats; saved activities → XP → level progress.",
]
for scene, cue in zip(script["scenes"], screen_cues):
    scene["screen"] = cue
(folder / "explained-narration.json").write_text(json.dumps(script, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(dict(duration=135, codeExcerpts=2, diagrams=len(manifest["diagramPopups"]), spokenWords=sum(len(s["read"].split()) for s in script["scenes"]))))
