/*
 * Function: FLO_fnc_virtualizationRestoreRegistry
 * Description:
 *   Restores all groups under their exact saved IDs before applying any state
 *   containing cross-group references.
 */

params [
    ["_savedGroups", createHashMap, [createHashMap]],
    ["_missionSaveVersion", 0, [0]]
];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
if ((keys _groups) isNotEqualTo []) then {
    throw "Virtual-force restore requires an empty registry";
};

private _migratedGroups = createHashMap;
{
    private _groupId = _x;
    private _savedData = [_groupId, _y, _missionSaveVersion] call FLO_fnc_virtualizationMigrateSavedGroup;
    _migratedGroups set [_groupId, _savedData];

    private _groupData = [
        _savedData get "position",
        _savedData get "groupType",
        configNull,
        _savedData get "homeObjective",
        _savedData get "unitCount",
        _savedData get "side",
        _savedData get "spawnClass",
        _groupId
    ] call FLO_fnc_virtualizationBuildGroupData;

    [_groupId, _groupData, false] call FLO_fnc_virtualizationAddGroup;
} forEach _savedGroups;

{
    [_x, _y] call FLO_fnc_virtualizationRestoreSavedGroup;
} forEach _migratedGroups;

// Reject malformed cross-record state before derived-state reconciliation.
call FLO_fnc_virtualizationValidateRegistry;
call FLO_fnc_virtualizationRebuildDerivedState;
call FLO_fnc_virtualizationValidateRegistry;

count _migratedGroups
