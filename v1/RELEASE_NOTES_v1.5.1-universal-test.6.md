# v1.5.1-universal-test.6

Prerelease polish for Pixel 10 Thermal & Memory Control.

## What changed

- Keeps test5 dynamic value-coupled manager Ampel.
- Renames the root Action menu item from Back to Exit.
- Adds an Advanced menu for guarded pTune status/override handling.
- Keeps pTune override out of normal Settings.
- Blocks risky override paths for disabled or known-bad pTune states.
- Reduces repeated status blocks after Action selections.
- Keeps Debug ZIP progress visible and returns to Action.
- Adds profile matrix verify helper for all packaged profiles.
- Shortens installer debug autosave UI output.
- Stable `update.json` remains on `1.5-universal.1`.

## Verify target

- Manager card: `P:green mod | T:green outdoor-ext | Z:green 100p | Action: settings/debug`
- Action menu: Status, Settings, Debug ZIP, Advanced, Exit.
- Settings and Advanced menus expose Back.
