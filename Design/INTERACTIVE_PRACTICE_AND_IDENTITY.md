# Interactive practice and private identity

October 25, 2026.

## Direction

Students should see their next useful study action before branding or status decoration. Keep the photographic course collection and open reading surfaces. Remove the home wordmark capsule and numbered section labels. The profile entry is a single 40-point portrait with a progress ring inside a 44-point touch target; iOS 26's shared toolbar background is explicitly hidden. The default portrait is original code-native artwork, not initials. Uploaded photos still take precedence.

Manrope supplies the app's type roles, with Dynamic Type scaling. The font is bundled, not downloaded at runtime. Its SIL OFL notice ships in `FirstStateLens/Fonts/OFL.txt`. Native system controls keep their platform behavior; mathematical reading content keeps its established reader typography.

## Private profile, not a cloud service

The October 25 multi-account update supersedes the original single-profile storage below. Credentials now live in an atomic Keychain vault containing independently salted verifiers and stable UUIDs. Academic snapshots live under `Accounts/<UUID>/progress-v1.json`; new accounts do not inherit another user's data. Legacy credential migration marks exactly the original owner as eligible to copy the old study file. Subsequent logins prefer the account's own file. Sign-out saves/pauses the current workspace, removes in-memory state, stops sound and system timer presentation, and fences deferred reader/Focus callbacks by account ID. Profile reset is account-scoped. Recovery authenticates the device owner and changes only the named user's verifier without changing their UUID or records. Local file separation is not a claim of separate OS sandboxes or per-account data encryption.

New and existing installations without credentials ask for a username and password before entering. Existing study progress is retained. A local identity supports sign-in after relaunch and sign-out from Profile. No server, email verification, global username availability, cross-device account, or synchronization is implied.

A 32-byte random salt and PBKDF2-HMAC-SHA256 verifier (210,000 iterations, 32-byte output) are stored with the username in a device-only, when-unlocked Keychain record. Raw passwords are never written to progress JSON or logs. Derivation runs outside the main actor. In-process repeated failures trigger a short cooldown; this is not server-enforced rate limiting. Optional forgotten-password recovery asks iOS to authenticate the device owner before replacing the credential. Study progress remains ordinary local app data: the profile gate does not claim to separately encrypt the progress database.

UI tests use a separate Keychain service, just as they use a separate progress file. Reset flags affect only that test service. Resetting study progress keeps the ordinary identity.

## Practice rounds

The 585 course practice activities retain their previous `-recall` IDs so old completions and one-time XP are not discarded. The UI now calls them practice rounds. Each has three graded interactions: multiple choice, typed blank, and three-way matching. Matching supports actual text drag-and-drop and tap-term/tap-blank operation for accessibility and precise selection. Filled blanks can be cleared or reassigned. Old written responses stay in storage rather than being deleted.

The offline question bank covers all 417 distinct readings. `scripts/build_reading_checks.py` selects source-marked terms or prose excerpts deterministically; it does not use a generative model or fetch network content. A small set of original concept checks replaces unsuitable source task instructions. These are source-comprehension checks, not a replacement for full conceptual assessments. Automatic blank selection still needs educator review before release. Adapted text retains the source reading's attribution and license; the existing noncommercial/share-alike release boundary still applies.

Wrong checks show the relevant source evidence and permit another attempt. Correct checks advance only after persistence succeeds. Completed question position and wrong-check count survive relaunch. A completed round earns 10 XP once, using the existing award ID set. It does not change foundation mastery or accuracy. The existing foundation MCQs remain separately available, with the same answer-feedback visual language.

Motion consists of progress-segment fills, a short question transition, a drawn answer ring/check, and contextual feedback expansion. Reduce Motion disables the spatial/spring treatment; quiet Focus suppresses it as well.

## References

- [Apple toolbar shared-background visibility](https://developer.apple.com/documentation/swiftui/customizabletoolbarcontent/sharedbackgroundvisibility(_:)) informed removal of the system capsule, not a replacement for native navigation.
- [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain-services) provides credential storage.
- [Manrope source and license](https://github.com/google/fonts/tree/main/ofl/manrope) supplies the bundled font.

## Verification

Final results are recorded in `STATUS.md`. Physical-device password recovery, full VoiceOver traversal, and educator review remain separate gates. Simulator results do not establish release readiness.
