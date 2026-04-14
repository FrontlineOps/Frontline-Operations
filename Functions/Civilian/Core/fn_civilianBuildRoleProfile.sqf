/*
 * Function: FLO_fnc_civilianBuildRoleProfile
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the civilian ambient profile used by spawn, activation, and intel
 *   logic. Roles bias how a civilian moves and what kind of information they
 *   are likely to know.
 *
 * Arguments:
 * 0: Objective ID <STRING>
 * 1: Location type <STRING>
 * 2: Group type <STRING>
 * 3: Anchor position <ARRAY>
 *
 * Return Value:
 * HASHMAP - Role profile
 */

params [
    ["_objectiveId", "", [""]],
    ["_locationType", "NameVillage", [""]],
    ["_groupType", "civilian", [""]],
    ["_anchorPos", [0, 0, 0], [[]], [3]]
];

private _profile = createHashMapFromArray [
    ["role", "resident"],
    ["trustBias", 1],
    ["knowledgeBias", 1],
    ["routineState", "anchored"],
    ["anchorPos", +_anchorPos]
];

private _weightedRoles = switch (true) do {
    case (_groupType in ["civilianVehicle", "civ_car"]): {
        [["driver", 1]]
    };
    case (_groupType == "civ_building"): {
        switch (_locationType) do {
            case "NameCityCapital": { [["resident", 6], ["watcher", 3], ["vendor", 2]] };
            case "NameCity": { [["resident", 7], ["watcher", 3], ["worker", 2]] };
            default { [["resident", 8], ["watcher", 2]] };
        };
    };
    default {
        switch (_locationType) do {
            case "NameCityCapital": { [["wanderer", 4], ["vendor", 4], ["worker", 3], ["resident", 2], ["watcher", 1]] };
            case "NameCity": { [["worker", 4], ["wanderer", 3], ["resident", 3], ["vendor", 2], ["watcher", 1]] };
            default { [["resident", 4], ["worker", 2], ["watcher", 2], ["wanderer", 1], ["vendor", 1]] };
        };
    };
};

private _totalWeight = 0;
{ _totalWeight = _totalWeight + (_x select 1); } forEach _weightedRoles;

private _selectedRole = "resident";
private _pick = random (_totalWeight max 1);
private _runningWeight = 0;
{
    _runningWeight = _runningWeight + (_x select 1);
    if (_pick <= _runningWeight) exitWith {
        _selectedRole = _x select 0;
    };
} forEach _weightedRoles;

private _roleShape = switch (_selectedRole) do {
    case "vendor": { [1.1, 0.9, "stall"] };
    case "worker": { [0.95, 0.95, "commute"] };
    case "wanderer": { [0.9, 0.8, "loop"] };
    case "watcher": { [0.8, 1.15, "observe"] };
    case "driver": { [0.85, 1.1, "mobile"] };
    default { [1.0, 0.85, "anchored"] };
};

_profile set ["role", _selectedRole];
_profile set ["trustBias", _roleShape select 0];
_profile set ["knowledgeBias", _roleShape select 1];
_profile set ["routineState", _roleShape select 2];

_profile
