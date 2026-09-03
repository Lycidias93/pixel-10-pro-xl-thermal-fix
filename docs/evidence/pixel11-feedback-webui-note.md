# Pixel 11 WebUI feedback remediation

Exploratory vNext follow-up after tester feedback.

- Mobile keyboard: the consumer now pins shared WebUI Core commit `e7aa23ebb36be9b9075c66693d045a19413af8b1`, which adds a bounded `visualViewport` focus helper so focused confirmation/text controls are kept visible above the Android software keyboard.
- Logging: WebUI typed actions now expose `Logging · Silent` and `Logging · Verbose`. They write the same canonical `DEBUG_MODE`, legacy-compatible `debug_mode`, and `LAST_DEBUG_MODE` values used by the installer menu. This does not disable mandatory Bootguard/health evidence.
- Page cluster: the WebUI's explicit `page-cluster=0` choice now persists as desired state and is reapplied only after post-boot verification confirms active ZRAM; Stock clears the desired zero state.

These changes require exact-candidate device verification before integration because the WebUI pin and page-cluster boot behavior changed after the previous candidate.
