/*
 * Function: FLO_fnc_factionGetCompositionDefaults
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns default numeric force composition values for the selected faction.
 *
 * Arguments:
 *   0: Side label <STRING> - "BLUFOR" or "OPFOR"
 *   1: Faction selection label <STRING>
 * Return Value:
 *   HASHMAP with transportReserveGroundCount, transportReserveAirCount,
 *   objectiveGroups, objectiveGroupTypeCaps, and groupCounts.
 */

params [
    ["_sideLabel", "", [""]],
    ["_selection", "", [""]]
];

private _objectiveGroups = [] call FLO_fnc_factionCompositionDefaultObjectiveGroups;
private _normalizedSide = toUpper _sideLabel;
if !(_normalizedSide in ["BLUFOR", "OPFOR"]) then {
    throw format ["Unknown force composition side '%1' for %2", _sideLabel, _selection];
};

private _caps = [true, 3, 20] call FLO_fnc_factionCompositionDefaultCaps;
private _counts = [1, 3, 10] call FLO_fnc_factionCompositionDefaultCounts;
[20, 10, _objectiveGroups, _caps, _counts] call FLO_fnc_factionCreateCompositionDefaultHandle
