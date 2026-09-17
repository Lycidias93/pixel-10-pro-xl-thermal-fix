# Pixel Thermal & Memory Control 2.1.0-alpha.5

## What changed

• KsuWebUI can now open the module WebUI directly inside its embedded WebView without the previous 404 Not Found / disconnected screen.
• Magisk Action and KsuWebUI now work in parallel. Magisk Action opens the standalone browser WebUI while KsuWebUI keeps the interface inside its own WebView.
• The WebUI exposes guarded runtime controls for Polling, Thermal profiles, ZRAM, Emerald Hill, LMKD and ZRAM page-cluster.
• Fixes the intermittent `server_not_ready` WebUI startup failure.
• Fixes the installer volume-key timeout hang.
• Improves Thermal validation on non-English system locales.
• Improves mobile WebUI action cards, tabs, status labels and Inventory views.

## Notes

This is a public vNext prerelease. Stable users can remain on the stable channel.
Experimental LMKD 1%, Emerald Hill max lock and ZRAM page-cluster 0 remain opt-in and require explicit confirmation.

Install the update through the normal module update flow and reboot so the new module runtime becomes active.
