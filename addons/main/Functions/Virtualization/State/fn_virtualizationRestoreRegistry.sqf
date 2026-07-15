/*
 * Function: FLO_fnc_virtualizationRestoreRegistry
 * Description:
 *   Restores all groups under their exact saved IDs before applying any state
 *   containing cross-group references.
 */

params [["_savedGroups", createHashMap, [createHashMap]]];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
if ((keys _groups) isNotEqualTo []) then {
    throw "Virtual-force restore requires an empty registry";
};

private _validatedGroups = createHashMap;
{
    private _groupId = _x;
    private _savedData = [_y] call FLO_fnc_virtualizationCloneValue;
    try {
        [_savedData, _groupId] call FLO_fnc_virtualizationValidateSavedGroup;
        private _archetype = [_savedData get "groupType"] call FLO_fnc_virtualizationGetArchetype;
        if ((_archetype get "movementDomain") == "LAND") then {
            private _routeValidation = [
                _groupId,
                _savedData get "position",
                _savedData get "waypoints",
                _savedData get "currentWaypointIndex",
                _savedData get "autoPatrol",
                _savedData get "patrolConfig"
            ] call FLO_fnc_virtualizationValidateLandRoute;
            if !(_routeValidation select 0) then {
                throw format ["Unsafe saved LAND route: %1", _routeValidation select 1];
            };
        };
    } catch {
        ["VIRTUALIZATION", 2, format [
            "Rejected current virtual-group record group=%1 reason=%2",
            _groupId,
            _exception
        ]] call FLO_fnc_log;
        throw format ["Virtual-force restore rejected group %1: %2", _groupId, _exception];
    };
    _validatedGroups set [_groupId, _savedData];
} forEach _savedGroups;

private _builtGroups = createHashMap;
{
    private _groupId = _x;
    private _savedData = _y;
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

    _builtGroups set [_groupId, _groupData];
} forEach _validatedGroups;

{
    [_x, _y, false] call FLO_fnc_virtualizationAddGroup;
} forEach _builtGroups;

{
    [_x, _y] call FLO_fnc_virtualizationRestoreSavedGroup;
} forEach _validatedGroups;

// Reject malformed cross-record state before derived-state reconciliation.
call FLO_fnc_virtualizationValidateRegistry;
call FLO_fnc_virtualizationRebuildDerivedState;
call FLO_fnc_virtualizationValidateRegistry;

count _validatedGroups
