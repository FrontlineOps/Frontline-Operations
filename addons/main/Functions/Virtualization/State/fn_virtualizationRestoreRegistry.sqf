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
    } catch {
        ["VIRTUALIZATION", 1, format ["Rejected saved virtual group=%1 reason=%2", _groupId, _exception]] call FLO_fnc_log;
        throw format ["Virtual-force restore rejected group %1: %2", _groupId, _exception];
    };
    _validatedGroups set [_groupId, _savedData];
} forEach _savedGroups;

// Establish ownership before deciding which records own LAND movement.
try {
    [_validatedGroups] call FLO_fnc_virtualizationNormalizeSavedTransport;
} catch {
    ["VIRTUALIZATION", 1, format ["Rejected saved transport graph: %1", _exception]] call FLO_fnc_log;
    throw _exception;
};
{
    private _groupId = _x;
    private _savedData = _y;
    try {
        [_savedData, _groupId] call FLO_fnc_virtualizationNormalizeSavedLandRoute;
    } catch {
        ["VIRTUALIZATION", 1, format [
            "Rejected current virtual-group record group=%1 reason=%2",
            _groupId,
            _exception
        ]] call FLO_fnc_log;
        throw format ["Virtual-force restore rejected group %1: %2", _groupId, _exception];
    };
} forEach _validatedGroups;

private _builtGroups = createHashMap;
{
    private _groupId = _x;
    private _savedData = _y;
    private _assetStrength = ([_savedData get "groupType"] call FLO_fnc_virtualizationGetArchetype) get "assetStrength";
    // A saved asset selection is authoritative, including transport-only catalogs.
    // Personnel compositions may retain pre-casualty slots in supported saves.
    private _selectedComposition = if (_assetStrength) then { _savedData get "comp" } else { [] };
    private _groupData = [
        _savedData get "position",
        _savedData get "groupType",
        configNull,
        _savedData get "homeObjective",
        _savedData get "unitCount",
        _savedData get "side",
        _savedData get "spawnClass",
        _groupId,
        _selectedComposition,
        _savedData get "transportRole"
    ] call FLO_fnc_virtualizationBuildGroupData;

    // Hydrate and validate privately; rejection must not publish a partial army.
    [_groupData, _savedData] call FLO_fnc_virtualizationRestoreSavedGroup;
    _builtGroups set [_groupId, _groupData];
} forEach _validatedGroups;

[_builtGroups] call FLO_fnc_virtualizationValidateTransportGraph;
{
    [_x, _y, false] call FLO_fnc_virtualizationAddGroup;
} forEach _builtGroups;

// Reject malformed cross-record state before derived-state reconciliation.
call FLO_fnc_virtualizationValidateRegistry;
call FLO_fnc_virtualizationRebuildDerivedState;
call FLO_fnc_virtualizationValidateRegistry;

["VIRTUALIZATION", 3, format ["Restored virtual-force registry groups=%1", count _validatedGroups]] call FLO_fnc_log;
count _validatedGroups
