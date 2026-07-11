# Magisk update channel path switch

Status: vNext test3
Version: 1.5.2-universal-test.3

## Goal

Allow switching the Magisk update metadata path between stable and test/pre-release from the module action menu.

## Non-goal

The switch does not download ZIP files and does not install updates.

## Channels

Stable:

```text
update.json
```

Pre-release/test:

```text
update-prerelease.json
```

The action menu changes only the active module `module.prop` line:

```text
updateJson=<selected online json>
```

## Menu path

```text
Action > Advanced > Update Ch
```

Options:

```text
Use Stable
Use Test
Back
```

## Safety

- stable `update.json` remains unchanged
- pre-release metadata is separate
- no automatic download
- no automatic install
- no silent switch
- no runtime claim changes
