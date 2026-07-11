# Profile directory index

## Important clarification

profiles/mustang is a legacy Android 16 compatibility path.

It is not the Android 17 Pixel 10 Pro XL profile path.

Android 17 profiles must use explicit device, Android version, build family, and build id in the directory name.

## Current naming rule

Use this form for Android 17 profile directories:

profiles/device-android17-buildfamily-buildid
profiles/device-android17-buildfamily-buildid-outdoor-safe
profiles/device-android17-buildfamily-buildid-outdoor-plus
profiles/device-android17-buildfamily-buildid-outdoor-extended

Examples:

profiles/mustang-android17-cp31-cp31260618005
profiles/mustang-android17-cp31-cp31260618005-outdoor-safe
profiles/mustang-android17-cp31-cp31260618005-outdoor-plus
profiles/mustang-android17-cp31-cp31260618005-outdoor-extended

## Legacy compatibility paths

profiles/mustang is kept for resolver compatibility with the verified Android 16 mustang profile.

Do not add new Android 17 work under profiles/mustang.

## Current Android 17 G5 devices

- frankel: Pixel 10
- blazer: Pixel 10 Pro
- mustang: Pixel 10 Pro XL
- rango: Pixel 10 Pro Fold

## Current QPR1 Beta 6 basis

CP31.260618.005 is the current Android 17 QPR1 Beta 6 factory basis for frankel, blazer, mustang, and rango.

Use the explicit cp31260618005 profile names for this basis.
