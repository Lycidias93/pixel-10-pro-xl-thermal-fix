# profiles/mustang

## Status

This directory is a legacy Android 16 compatibility profile.

It is intentionally kept because the runtime resolver still maps Android 16 mustang to profile=mustang.

Do not use this directory for Android 17 CP2A or CP31 work.

## Android 17 mustang profiles

Use explicit Android 17 profile directories instead, for example:

- profiles/mustang-android17-stable-cp2a-260605012
- profiles/mustang-android17-cp31-cp31260618005
- profiles/mustang-android17-cp31-cp31260618005-outdoor-safe
- profiles/mustang-android17-cp31-cp31260618005-outdoor-plus
- profiles/mustang-android17-cp31-cp31260618005-outdoor-extended

## Reason

The plain profiles/mustang name is ambiguous when viewed on GitHub.
This README makes the compatibility status explicit without renaming the directory and breaking the resolver.
