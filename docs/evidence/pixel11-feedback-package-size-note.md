# Pixel 11 feedback package-size audit

The reported duplicate `zram100p` content is confirmed in the pre-fix repository tree: `system/vendor/etc/fstab.zram.100p` and `tools/zram/fstab.zram.100p` were byte-identical 74-byte files. The generated `system/vendor/etc` copy has been removed from source tracking; the tools copy remains the install/pre-mount source template.

That 74-byte duplicate cannot explain the increase from an early ~256 KB dynamic-patcher prototype to the current multi-megabyte candidate. The current line also packages a native standalone WebUI server and other runtime tooling that did not exist in the earliest patcher-only prototype.

No exact component attribution is made here until the feedback candidate has been built and its ZIP entries are measured. The CI artifact must be inspected by entry size before any further size-trimming decision.
