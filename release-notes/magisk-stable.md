# Pixel 10 Thermal & Memory Control 2.0.4

## Hotfix

• Fixes fresh-cache Dynamic Thermal materialization on newly seen device/build tuples.
• Corrects the source and patch manifest TSV headers so they contain real tab delimiters instead of literal `\t` text.
• Prevents the manifest reader from treating the header as a Thermal filename and aborting before validation.
• Keeps the 2.0.3 canonical runtime-evidence fix, August multiline `HotThreshold` support, exact Outdoor delta validation, Polling guards and fail-closed recovery unchanged.

Install 2.0.4 over the existing module and reboot. No wipe or config reset is required.
