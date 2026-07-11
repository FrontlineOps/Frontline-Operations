/*
 * Function: FLO_fnc_gtnMarkCommanderStateDirty
 * Author: Frontline Operations Development Group
 * Description:
 *   Marks commander-maintained state dirty in response to internal CBA events.
 *   This is used to avoid waiting on cadence-only refresh paths when objective,
 *   logistics, or support state changes already know exactly which side was hit.
 *
 * Arguments:
 *   0: GTN commander <HASHMAPOBJECT>
 *   1: Dirty reason <STRING>
 *   2: Optional payload <ARRAY>
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_commander", nil],
    ["_reason", "", [""]],
    ["_payload", [], [[]]]
];

if (isNil "_commander") exitWith { false };

private _dirtyReason = toUpper _reason;

_commander set ["_intelDirty", true];
_commander set ["_lastIntelDirtyAt", diag_tickTime];
_commander set ["_lastIntelDirtyReason", _dirtyReason];

switch (_dirtyReason) do {
    case "OBJECTIVE_FLIPPED": {
        _commander set ["_availabilityCacheDirty", true];
        _commander set ["_reserveBandsCache", createHashMap];
        _commander set ["_attackSourceObjectivesCache", createHashMap];
        _commander set ["_attackFrontlineObjectives", createHashMap];
        _commander set ["_attackPressureProfiles", createHashMap];
        _commander set ["_minefieldDirty", true];
        _commander set ["_lastGarrisonSignature", ""];
        _commander set ["_lastFriendlyObjectiveOwnershipSignature", ""];
        _commander set ["_lastGarrisonRunAt", -1];
    };

    case "OBJECTIVE_INTEGRATED": {
        _commander set ["_availabilityCacheDirty", true];
        _commander set ["_reserveBandsCache", createHashMap];
        _commander set ["_attackSourceObjectivesCache", createHashMap];
        _commander set ["_attackFrontlineObjectives", createHashMap];
        _commander set ["_attackPressureProfiles", createHashMap];
        _commander set ["_minefieldDirty", true];
        _commander set ["_lastGarrisonSignature", ""];
        _commander set ["_lastGarrisonRunAt", -1];
    };

    case "SUPPLY_CHAIN_CHANGED": {
        _commander set ["_attackPressureProfiles", createHashMap];
    };

    case "ARTILLERY_STATE_CHANGED": {
    };

    default {
    };
};

true
