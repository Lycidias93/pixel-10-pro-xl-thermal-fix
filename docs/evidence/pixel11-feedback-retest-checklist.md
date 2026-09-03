# Pixel 11 feedback candidate — exact-head retest checklist

This checklist applies to the final rebuilt candidate, not to an older Alpha5 or PR #192 artifact.

1. Record candidate SHA-256, bytes, PR head SHA, device codename, Android build ID, root implementation and mount backend.
2. Install the exact candidate and reboot.
3. Confirm module active with no `disable`, `skip_mount`, or `remove` flag.
4. Confirm full/trusted Bootguard verification and vNext readiness.
5. Confirm Pixel 11 Thermal polling is Stock and the complete Include-graph overlay matches validated materialization.
6. Start heat isolation with Thermal Stock, ZRAM disabled, LMKD Stock, Emerald Hill Adaptive, page-cluster Stock and Logging Silent.
7. Observe a repeatable idle/battery window under matched ambient, charging, screen and radio conditions.
8. Enable one optional feature at a time; reboot where required; repeat the same observation window.
9. Test page-cluster persistence separately: enable ZRAM, set page-cluster 0, verify current value 0, reboot, wait for verified boot, then require desired/effective 0 with post-Bootguard evidence.
10. Test both WebUI launch paths as available and verify the software keyboard no longer hides the confirmation field.
11. Switch Logging Silent -> Verbose -> Silent and verify effective status follows the selected mode.
12. Run `tools/debug/vnext-device-verify.sh baseline` and require final PASS with no failures.
13. Create a Support Snapshot from the exact candidate.

Any failed runtime/boot check blocks integration merge until diagnosed and retested on the same final head.
