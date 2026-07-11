# WebUI vNext external reference audit: Encore Tweaks

Status: captured for post-stable WebUI planning.

## Source classification

- External project: `Rem01Gaming/encore`
- Reviewed purpose: WebUI, config and status architecture inspiration
- Operational status: inspiration only
- Not a source of truth for Pixel thermal behavior
- No direct code import approved
- License observed: Apache-2.0; any future code reuse requires attribution and license review

## Relevant ideas for Pixel Thermal WebUI vNext

### Keep

1. WebUI launcher pattern
   - Support WebUI-X / KSUWebUI style launch from `action.sh`.
   - Keep the current Magisk Action menu as recovery-friendly fallback.
   - Do not make WebUI a boot or runtime requirement.

2. Status dashboard pattern
   - Read from existing module state files instead of probing aggressively from UI.
   - Candidate sources:
     - `module.prop`
     - `config.env`
     - `install-state.txt`
     - `guard/manager-status.env`
     - `guard/manager-status.txt`
     - `guard/last_good.env`
     - `guard/fail_count`
     - `update.json`
     - `update-prerelease.json`

3. Clear state separation
   - Remembered user choices
   - Runtime status
   - Bootguard state
   - Update channel
   - Debug/export state

4. Structured config model
   - Consider a read-only or mirrored JSON view for WebUI.
   - Keep shell/env files authoritative until a migration is explicitly designed.
   - Do not silently replace `config.env` behavior.

5. Soft-disable concept
   - Add a WebUI-visible soft-disable only if it stays distinct from Magisk markers.
   - Must not mask Bootguard `disable`, `remove` or `skip_mount`.
   - Runtime evidence must show disabled state honestly.

6. Manager compatibility UX
   - Detect Magisk / KernelSU / APatch context for display and launch behavior.
   - Avoid changing install or mount behavior based only on UI convenience.

## Explicitly rejected for this project

Do not import or copy Encore performance-tweak behavior into Pixel Thermal:

- CPU governor forcing
- CPU/GPU frequency locking
- DRAM/devfreq tuning
- sysctl network/scheduler/VM tweaks
- kernel panic / oops / warn panic suppression
- thermal zone policy writes
- game detection / daemon-driven performance profiles
- mandatory daemon architecture
- global cleanup scripts outside module scope unless separately audited

These are outside the Pixel Thermal module scope and could conflict with:

- Bootguard v2
- pTune conflict guard
- Pixel thermal overlay behavior
- ZRAM runtime evidence
- stable release safety

## vNext planning interpretation

Use Encore only as a WebUI and UX reference. The target architecture should remain Pixel-specific, conservative, boot-safe and evidence-driven.

Recommended WebUI vNext sections:

- Overview: P/T/Z status and safe-to-reboot
- Remembered settings
- Runtime evidence
- Bootguard status
- Last good boot
- Update channel stable/test
- Debug ZIP export
- Boot crash export
- Soft-disable controls, if implemented
- External compatibility notes

## Guardrails for future implementation

- WebUI must be optional.
- Action menu must remain usable without WebUI.
- No boot-critical JavaScript path.
- No network fetch from WebUI for core status.
- No secrets in UI logs or exports.
- No broad performance/sysctl writes.
- No silent stable/test switching.
- No claims for frankel/blazer/rango runtime until device evidence exists.

## Decision

`encore` is useful as a WebUI/config/status reference for post-stable WebUI vNext.

It is not suitable as a source for runtime performance logic, thermal logic, ZRAM logic, Bootguard logic or stable-release policy.
