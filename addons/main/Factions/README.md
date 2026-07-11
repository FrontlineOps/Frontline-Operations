# FLO Faction Data

*Reference for curated and custom faction definitions.*

Faction files are custom runtime data loaded during initialization Phase 2. They assign the legacy globals consumed by the Store, base setup, civilian systems, and the normalized `FLO_FactionCatalog`; executable behavior belongs under `Functions/Factions`. Additional factions are discovered from loaded `CfgFactionClasses` data at runtime.

## Layout

| Path | Purpose |
| --- | --- |
| [`Custom`](Custom) | Editable fallback definitions for BLUFOR, OPFOR, and civilians. |
| [`../Functions/Factions`](../Functions/Factions) | Discovery, validation, normalization, and catalog-building logic. |

[`FLO_fnc_factionGetCustomDefinition`](../Functions/Factions/fn_factionGetCustomDefinition.sqf) is the source of truth for custom selection names and file paths. Do not duplicate them in UI or initialization code.

## Editing Rules

- Define every field in the side schema, using `[]` or `""` for unsupported capabilities. This prevents stale values from a previously loaded faction.
- Use spawnable `CfgVehicles` classnames. Infantry source arrays may also contain complete `CfgGroups` config entries.
- Store pools use `[classname, price]` pairs. Commander catalog builders remove prices when creating spawn pools.
- Duplicate array entries are allowed when they intentionally weight random selection; do not deduplicate them mechanically.
- Load every mod that provides a classname used by a custom definition.
- Do not put functions, `execVM`, scheduled loops, or initialization control flow in faction data files.

## BLUFOR Schema

BLUFOR files define:

- Roles: `F_Officer`, every `F_Assault_*`, `F_Recon_*`, and `F_Diver_*` role used by the definition.
- Base assets: `FLO_FactionRadar`, `FLO_FactionFobType`, `FLO_FactionFobTerminalType`, `FLO_FactionCopType`, and `FLO_FactionCopTerminalType`.
- Store and vehicle pools: `F_Bike_List`, `F_Car_List`, `F_MRAP_List`, all `F_Truck_*` lists, `F_APC_List`, `F_Tank_List`, `F_Artillery_List`, all `F_Heli_*` lists, `F_Plane_List`, `F_Boat_List`, `F_UAV_List`, `F_UGV_List`, `F_Container_List`, `F_Turret_List`, and `F_SAM_List`.
- Squad templates: `F_ASSLT_ENG`, `F_ASSLT_TEAM`, `F_ASSLT_SQD`, `F_SNP_TEAM`, `F_RCN_TEAM`, `F_RCN_SQD`, `F_DVR_TEAM`, and `F_OFFICER_TEAM`.

Phase 2 derives the WEST commander catalog from those fields. Separate `West_*` pools are not required in curated or custom files.

## OPFOR Schema

OPFOR files define all of these arrays:

`East_Ground_Infantry`, `East_Ground_SpecOps`, `East_Ground_Motorized`, `East_Ground_Mechanized`, `East_Ground_Armor`, `East_Ground_Transport`, `East_Ground_Artillery`, `East_Ground_Drone`, `East_Air_Transport`, `East_Air_Heli`, `East_Air_Jet`, `East_Air_Drone`, `East_Mobile_AA`, `East_Static_AA`, `East_Radar`, `East_Boat`, and `East_FireObserver`.

## Civilian Schema

Civilian files define `CiviliansPerLocationMin`, `CiviliansPerLocationMax`, `CivBuildingClasses`, `CivVehArray`, `CivMenArray`, `GuerMenArray`, and `GuerVehArray`.

## Validation

```powershell
.\.tools\hemtt\hemtt.exe check
.\.tools\hemtt\hemtt.exe build
```

HEMTT validates syntax and packaging, not whether custom or auto-discovered mod classnames exist. Test custom definitions with their complete runtime modset before treating them as verified.
