# Lens desk · native screen review

These are rendered iOS Simulator screens, not mockups. Normal-size, dark, and large-text tests use an isolated Avery account on iPhone 14 / iOS 26.5. Ordinary learner data was not used as a screenshot fixture.

## Comparison

| Before | After |
| --- | --- |
| [Today before](Today-before.png) | [Lens desk](Today.png) |
| [Account entry before](Entry-before.png) | [Account entry with original optical core](Entry-after.png) |

The Today comparison uses the same zero-XP U.S. History starting state and device dimensions. Account entry uses the normal iPhone 17 Pro Simulator at the same empty-account state. The first viewport now exposes four real material-intake actions. Existing course continuation remains below them.

## Workflows

- [Dark appearance](Today-dark.png).
- [Accessibility-sized text](Today-large.png); intake reflows to one column.
- [School search with the keyboard](School-search.png); results remain visible above it.
- [Academic profile](Profile.png); the banner logo tile is gone, and the profile retains its circular learner photo/XP ring.
- [Student-authored recall](Recall.png); answers are revealed and self-rated, not scored as course mastery.
- [Restored material and review count](Material-restored.png).
- [Recoverable empty collection](Materials-empty.png).
- [Native iOS Reduce Motion](Reduced-motion.png); verified with the actual setting, then restored.
- [Inline YouTube player](Video.png) and [unavailable-video recovery](Video-unavailable.png).

The implementation and per-reference-page decisions are in [Lens desk reference register](../../LENS_DESK_REFERENCE.md). Current test results and release limitations are in [STATUS.md](../../../STATUS.md). YouTube availability, physical-device energy/audio behavior, and a full VoiceOver audit remain separate gates.
