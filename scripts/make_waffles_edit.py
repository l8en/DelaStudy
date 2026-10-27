"""Derive the exact 135-second edit from real UI-test capture timestamps."""
import json
import re
import subprocess
import sys
from pathlib import Path

capture_dir = Path(sys.argv[1])
renderer = sys.argv[2]
video = capture_dir / "capture.mov"
metadata = json.loads(subprocess.check_output([renderer, "inspect", str(video)]))
epoch = metadata["creationEpoch"]
markers = {}
for kind, name, seconds in re.findall(r"SHOWCASE_(START|END)\|([^|\n]+)\|([\d.]+)", (capture_dir / "capture.log").read_text()):
    markers.setdefault(name, {})[kind] = float(seconds) - epoch

# A targeted retake preserves the completed onboarding/lesson footage and the
# very same local student's earned work. No synthesized notification is used.
alternate = capture_dir / "notification.mov"
alternate_metadata = json.loads(subprocess.check_output([renderer, "inspect", str(alternate)]))
for kind, name, seconds in re.findall(r"SHOWCASE_(START|END)\|([^|\n]+)\|([\d.]+)", (capture_dir / "notification.log").read_text()):
    if name in ("notification", "profile", "permission_verified"):
        if name not in markers or "source" not in markers[name]:
            markers[name] = {"source": str(alternate)}
        markers[name][kind] = float(seconds) - alternate_metadata["creationEpoch"]
markers["permission"] = markers["permission_verified"]

order = [("account", 6), ("setup_year", 3), ("setup_goal", 2),
         ("setup_subjects", 3), ("setup_route", 2), ("setup_school", 3),
         ("setup_rhythm", 3), ("setup_ready", 2), ("today", 4),
         ("library", 8), ("outline", 5), ("lesson", 10), ("practice", 23),
         ("resources", 9), ("college", 7), ("plan", 6), ("sounds", 10),
         ("zen", 7), ("permission", 3), ("notification", 11), ("profile", 8)]
shots = []
cursor = 0
for name, duration in order:
    bounds = markers[name]
    assert bounds["END"] > bounds["START"] >= 0, (name, bounds)
    shot = {"id": name, "duration": duration,
                  "sourceStart": round(bounds["START"] + 0.08, 3),
                  "sourceEnd": round(bounds["END"] - 0.08, 3)}
    if "source" in bounds: shot["source"] = bounds["source"]
    shots.append(shot)
    cursor += duration
assert cursor == 135

def popup(path, first, last, start, end, highlights):
    return dict(sourcePath=path, firstLine=first, lastLine=last, start=start,
                end=end, highlightLines=highlights)

manifest = dict(appName="DelaStudy", source=str(video),
                font=str(Path("FirstStateLens/Fonts/Manrope.ttf").resolve()),
                presentation="code-windows", devicePresentation="iphone-14-pro",
                codeWindowPlacement="lower-right", shots=shots,
                codePopups=[
                    popup("FirstStateLens/AppModel.swift", 82, 89, 7, 23.7, [84, 88]),
                    popup("FirstStateLens/CourseCatalogView.swift", 16, 23, 28.5, 35.8, [18, 21]),
                    popup("FirstStateLens/BiteLessonView.swift", 109, 115, 41.4, 50.8, [112, 114]),
                    popup("FirstStateLens/ReadingCheckView.swift", 176, 184, 51.5, 73.8, [178, 183]),
                    popup("FirstStateLens/CourseResourcesView.swift", 12, 18, 74.4, 82.8, [16, 17]),
                    popup("FirstStateLens/AppModel.swift", 345, 350, 90.3, 95.8, [349]),
                    popup("FirstStateLens/SoundLibraryView.swift", 66, 72, 96.4, 105.8, [66, 71]),
                    popup("Sources/FirstStateCore/Workspace.swift", 170, 174, 106.3, 112.8, [173]),
                    popup("FirstStateLens/RootView.swift", 56, 65, 116.3, 126.8, [61, 62, 64]),
                    popup("Sources/FirstStateCore/LearnerMetrics.swift", 23, 27, 127.4, 134.8, [27])])
output = Path("Demo/Showcase/waffles-edit-manifest.json")
output.write_text(json.dumps(manifest, indent=2) + "\n")
(capture_dir / "markers.json").write_text(json.dumps(markers, indent=2) + "\n")
print(json.dumps({"manifest": str(output), "duration": cursor, "shots": len(shots), "source": metadata}, indent=2))
