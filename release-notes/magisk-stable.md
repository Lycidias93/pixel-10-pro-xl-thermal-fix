# Pixel 10 Thermal & Memory Control 2.0.3

## Hotfix

• Fixes a post-reboot false `dynamic_materialization_invalid` state on validated installs.
• Runtime status and Bootguard now read the canonical persistent validation evidence directly instead of depending on legacy module symlink aliases.
• Keeps the 2.0.2 August multiline `HotThreshold` fix, Polling validation, Outdoor delta checks and fail-closed protection unchanged.

Install 2.0.3 over the existing module and reboot. No wipe or config reset is required.
