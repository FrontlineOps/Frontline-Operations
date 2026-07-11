/*
 * Function: FLO_fnc_factionSanitizeCompositionForCatalog
 * Author: Frontline Operations Development Group
 * Description:
 *   Removes force-composition requests for optional group types that the final
 *   side catalog cannot spawn.
 *
 * Arguments:
 *   0: Faction catalog <HASHMAP>
 *   1: Side label <STRING>
 *
 * Return Value:
 *   ARRAY of disabled group types
 */

params [
    ["_catalog", createHashMap, [createHashMap]],
    ["_sideLabel", "", [""]]
];

private _availability = createHashMapFromArray [
    ["motorized", (_catalog get "groundMotorized") isNotEqualTo []],
    ["mechanized", (_catalog get "groundMechanized") isNotEqualTo []],
    ["armor", (_catalog get "groundArmor") isNotEqualTo []],
    ["artillery", (_catalog get "groundArtillery") isNotEqualTo []],
    ["mobile_aa", (_catalog get "mobileAA") isNotEqualTo []],
    ["static_aa", (_catalog get "staticAA") isNotEqualTo []],
    ["helicopter", (_catalog get "airHeli") isNotEqualTo []],
    ["jet", (_catalog get "airJet") isNotEqualTo []],
    ["air", (count (_catalog get "airHeli") + count (_catalog get "airJet")) > 0]
];

private _disabledTypes = [];
{
    if !(_y) then {
        _disabledTypes pushBack _x;
    };
} forEach _availability;

if (_disabledTypes isEqualTo []) exitWith { [] };

private _removedObjectiveRequests = [];
private _sanitizedObjectiveGroups = [];
{
    _x params ["_objectiveType", "_groups"];
    private _keptGroups = [];
    {
        _x params ["_groupType", "_count"];
        if (_groupType in _disabledTypes) then {
            if (_count > 0) then {
                _removedObjectiveRequests pushBack [_objectiveType, _groupType, _count];
            };
        } else {
            _keptGroups pushBack _x;
        };
    } forEach _groups;

    _sanitizedObjectiveGroups pushBack [_objectiveType, _keptGroups];
} forEach (_catalog get "objectiveGroups");

private _sanitizedCaps = [];
{
    _x params ["_groupType", "_value"];
    _sanitizedCaps pushBack [_groupType, [_value, 0] select (_groupType in _disabledTypes)];
} forEach (_catalog get "objectiveGroupTypeCaps");

private _sanitizedCounts = [];
{
    _x params ["_groupType", "_value"];
    _sanitizedCounts pushBack [_groupType, [_value, 0] select (_groupType in _disabledTypes)];
} forEach (_catalog get "groupCounts");

_catalog set ["objectiveGroups", _sanitizedObjectiveGroups];
_catalog set ["objectiveGroupTypeCaps", _sanitizedCaps];
_catalog set ["groupCounts", _sanitizedCounts];

["FACTIONS", 2, format [
    "%1 force composition skipped unavailable group types before virtualization: disabled=%2 removedObjectiveRequests=%3",
    _sideLabel,
    _disabledTypes,
    _removedObjectiveRequests
]] call FLO_fnc_log;

_disabledTypes
