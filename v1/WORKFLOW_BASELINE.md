# Workflow Baseline

Marker: `WORKFLOW_BASELINE_CONSUMER_V1_20260705`

## Rolle

Dieses Repo ist an die zentrale Workflow-Toolbox angebunden.

## Zentrale Quelle

- Repo: `Lycidias93/termux-toolbox`
- Default-Pfad lokal: `$HOME/src/termux-toolbox`
- Override: `$WORKFLOW_TOOLBOX_ROOT`

## Lokale Pflichtdateien

- `tools/chatctx`
- `tools/cgflow`
- `.workflow-baseline`
- `WORKFLOW_BASELINE.md`

## Regel

Die lokalen Tools sind Wrapper. Sie delegieren an die zentrale Toolbox und stoppen sauber, wenn diese fehlt.

## Risiko

Gering, weil keine Host-, DNS-, HA-, VIP-, Default-Route- oder Secret-Änderungen enthalten sind.
