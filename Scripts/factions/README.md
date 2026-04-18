# Faction Preset Dependencies

This folder contains the built-in faction presets that FLO loads during Phase 2 faction setup. A preset only works if every classname it references exists in the running modset on the server and on every client.

This README is based on the actual classnames inside the current `.sqf` files, not just the filenames or header comments. If you change a faction file, update this README in the same change.

## Scope

- This file tracks required Workshop mods per preset.
- Creator DLC is listed when the faction mod explicitly requires it.
- `None` means no extra Workshop faction mod is required. It does not guarantee that the preset avoids every official Arma 3 DLC or platform asset.
- When a filename does not match the classnames it currently references, that mismatch is called out directly below instead of being hidden.

## Quick Prefix Guide

| Prefix / pattern | Usually means |
| --- | --- |
| `ADFRC_`, `adfrc_` | `ADF Re-Cut [Beta]` |
| `BWA3_` | `BWMod` |
| `UK3CB_` | `3CB Factions` |
| `rhs`, `rhsusf`, `RHS_` | `RHS` family |
| `CUP_` | `CUP` |
| `Flex_CUP_` | Flex7103's CUP expansion mods |
| `B_USAUSMC_`, `B_BUSAUSMC_` | `Current Issue - (USMC Troops)` |

## Per-file Requirements

| File | Side | Required mods / DLC |
| --- | --- | --- |
| `blu_ADF_RC.sqf` | BLUFOR | `ADF Re-Cut [Beta]`, `CBA_A3` |
| `blu_BW_RHS.sqf` | BLUFOR | `BWMod`, `CBA_A3`, `RHSUSAF` |
| `blu_USMC_CUP_EF.sqf` | BLUFOR | `CUP Units`, `CUP Vehicles`, `CUP Weapons`, `(CUP-EF) United States Marine Corps`, `Arma 3 Creator DLC: Expeditionary Forces` |
| `blu_NATODesert.sqf` | BLUFOR | `None` |
| `ind_AAF.sqf` | BLUFOR/INDFOR | `None` |
| `blu_UAF_CUP_UAFVP.sqf` | BLUFOR | `CUP Units`, `CUP Vehicles`, `CUP Weapons`, `(CUP) Ukrainian Armed Forces`, `UAF Vehicles Pack`, `UAF Vehicles Pack [CUP Compat]` |
| `blu_USMC_CI.sqf` | BLUFOR | `Current Issue - (USMC Troops)`, `RHSUSAF` |
| `civ_Greek.sqf` | CIVILIAN | `None` |
| `opf_CSATDesert.sqf` | OPFOR | `None` |
| `opf_Grozovia_3CB.sqf` | OPFOR | `3CB Factions`, `CBA_A3`, `RHSAFRF`, `RHSGREF`, `RHSUSAF`, `RHSSAF` |
| `opf_IAF_CUP_EF.sqf` | OPFOR | `CUP Units`, `CUP Vehicles`, `CUP Weapons`, `(CUP) Iranian Armed Forces` |
| `opf_RU_CUP.sqf` | OPFOR | `CUP Units`, `CUP Vehicles`, `CUP Weapons`, `RHSAFRF` |

## Notes For Maintainers

- `3CB Factions` should be treated as requiring its official dependency chain, not just the classnames that happen to appear in this mission file.
- `UAF Vehicles Pack [CUP Compat]` requires `UAF Vehicles Pack`, `CUP Vehicles`, and `CUP Units`. This preset also needs `(CUP) Ukrainian Armed Forces` because the infantry classes come from that faction mod.
- Flex7103's presets in this folder belong to the same broader CUP expansion family, but the exact required item still depends on the classname prefix actually used in the file.
- If a preset gets renamed or repointed to a different mod family, update both the filename and this README so the docs stay trustworthy.
