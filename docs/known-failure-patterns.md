# Known failure patterns


<!-- UNIVERSAL_RELEASE_AUTOMATION_KNOWN_FAILURES_20260602_START -->
## Universal release automation known failures

Scope: Pixel 10 Thermal Polling Fix universal-first release workflow.

Do not repeat these false-stop patterns:

1. Dynamic install-state source generation
   - Symptom: publish preflight expects literal `module_version=1.4.1-universal.1` in `customize.sh`.
   - Correct handling: accept dynamic generation from `module.prop` if live post-reboot verify shows `install-state.txt` with final `module_version=1.4.1-universal.1` and no `rc1` label.

2. v-prefixed release documentation filenames
   - Symptom: automation looks for `docs/verify-1.4.1-universal.1.md`.
   - Correct handling: accept repo naming `docs/verify-v1.4.1-universal.1.md` and `docs/release-scope-v1.4.1-universal.1.json`.

3. JSON semantic marker versus Markdown sentence
   - Symptom: JSON release-scope does not contain literal sentence `No polling values changed by this release`.
   - Correct handling: validate semantic fields such as `polling_values_changed_by_this_release=false/no` in JSON; keep exact sentence checks for Markdown files.

4. Sortify archive relocation
   - Symptom: final ZIP missing from `/storage/emulated/0/Download` shortly before publish.
   - Correct handling: resolver must check `/storage/emulated/0/Sortify/Archives` and `/sdcard/Sortify/Archives`, restore the ZIP to Download, and regenerate/copy `.sha256`.

5. Universal source-tree layout
   - Symptom: `git add system/vendor/etc` fails after universal profile migration.
   - Correct handling: active source payload under `system/vendor/etc` must be absent; use `profiles/mustang/...` and `profiles/blazer/...`.

6. Public-support marker exactness
   - Symptom: repeated aborts for equivalent wording such as `Mustang verified`, `Blazer beta/pending`, or external inspiration boundaries.
   - Correct handling: normalize markers once in docs, then gate Markdown exactly and JSON semantically.

Invariant:
- No thermal/profile JSON value changes.
- No bind-mount runtime model.
- No live text patching.
- `update.json` switches only after release asset exists.
- GitHub connector is read-only; public writes run locally via `git`/`gh` on Pixel.
<!-- UNIVERSAL_RELEASE_AUTOMATION_KNOWN_FAILURES_20260602_END -->
