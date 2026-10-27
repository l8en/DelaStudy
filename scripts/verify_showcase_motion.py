"""Compare the actual sound-glyph pixels in native Simulator screenshots."""
import json
import re
import sys
from pathlib import Path
from PIL import Image, ImageChops

root = Path(sys.argv[1])
report = {}
for mode in ("normal", "reduced"):
    folder = root / f"sound-{mode}-attachments"
    manifest = json.loads((folder / "manifest.json").read_text())
    attachments = [a for test in manifest for a in test["attachments"]]
    rect = re.search(r"SOUND_GLYPH_RECT\|([\d.]+)\|([\d.]+)\|([\d.]+)\|([\d.]+)", (root / f"sound-{mode}.log").read_text())
    x, y, width, height = map(float, rect.groups())
    box = tuple(round(v * 3) for v in (x + 2, y + 2, x + width - 2, y + height - 2))
    values = {}
    for state in ("playing", "paused"):
        images = []
        for suffix in ("A", "B"):
            entry = next(a for a in attachments if a["suggestedHumanReadableName"].startswith(f"Sound-{state}-{suffix}_"))
            images.append(Image.open(folder / entry["exportedFileName"]).convert("RGB").crop(box))
        difference = ImageChops.difference(*images)
        values[state] = sum(max(pixel) > 12 for pixel in difference.getdata())
    report[mode] = {"glyphCropPixels": box, "changedPixelsPlaying": values["playing"], "changedPixelsPaused": values["paused"]}
assert report["normal"]["changedPixelsPlaying"] > 100, report
assert report["normal"]["changedPixelsPaused"] == 0, report
assert report["reduced"]["changedPixelsPlaying"] == 0, report
assert report["reduced"]["changedPixelsPaused"] == 0, report
report["scope"] = "Two native screenshot samples per playback state, normal and system Reduce Motion enabled. Playback-state indicator, not an audio spectrum or physical-device measurement."
(root / "motion-verification.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
