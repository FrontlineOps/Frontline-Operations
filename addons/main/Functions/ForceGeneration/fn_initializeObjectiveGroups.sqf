/*
 * Function: FLO_fnc_initializeObjectiveGroups
 * Author: Frontline Operations Development Group
 * Description:
 * Creates side-owned virtual groups for objectives based on subtype templates.
 *
 * Arguments:
 * 0: Side <SIDE> - side to initialize (east or west)
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * [east] call FLO_fnc_initializeObjectiveGroups;
 */
params [["_side", east]];

if !(_side in [east, west]) exitWith { false };
if (isNil "FLO_Objectives") exitWith { false };

private _seedT0 = diag_tickTime;
private _sideKey = [_side] call FLO_fnc_sideKey;
private _spawnPlan = [_side] call FLO_fnc_buildObjectiveTemplateSpawnPlan;

["VIRTUALIZATION", 3, format["Initializing objective groups for %1", _sideKey]] call FLO_fnc_log;

private _allCreatedGroups = [];
private _plannedObjectives = keys _spawnPlan;
private _plannedTemplateCount = 0;
private _plannedGroupCount = 0;
private _staticAAVirtualCount = 0;

// Process each indexed objective
{
    private _objId = _x;
    private _objData = FLO_Objectives get _objId;
    private _subtype = _objData get "subtype";
    ["VIRTUALIZATION", 3, format["Processing %1 objective: %2 (Subtype: %3)", _sideKey, _objId, _subtype]] call FLO_fnc_log;

    private _groupsToCreate = _spawnPlan get _objId;
    private _objectiveGroups = [];
    _plannedTemplateCount = _plannedTemplateCount + count _groupsToCreate;

    {
        _x params ["_groupType", "_count"];
        _plannedGroupCount = _plannedGroupCount + _count;
        private _createdGroups = [_objId, _groupType, _count, _side] call FLO_fnc_distributeVirtualGroups;
        _objectiveGroups append _createdGroups;
    } forEach _groupsToCreate;

    _allCreatedGroups append _objectiveGroups;

    {
        private _groupId = _x;
        private _groupData = [_groupId] call FLO_fnc_virtualizationGetGroup;

        [_groupId] call FLO_fnc_virtualizationAssignAutoPatrol;

        if ((_groupData get "groupType") == "static_aa") then {
            [_groupId, createHashMapFromArray [["alwaysActive", false]]] call FLO_fnc_virtualizationPatchGroup;
            _staticAAVirtualCount = _staticAAVirtualCount + 1;
        };
    } forEach _objectiveGroups;

    ["VIRTUALIZATION", 3, format["Created %1 %2 virtual groups at objective %3", count _objectiveGroups, _sideKey, _objId]] call FLO_fnc_log;
} forEach _plannedObjectives;

// Spawn civilians once after first side pass.
if (isNil "FLO_CiviliansInitialized" || {!FLO_CiviliansInitialized}) then {
    [] call FLO_fnc_spawnCivilians;
    FLO_CiviliansInitialized = true;
    publicVariable "FLO_CiviliansInitialized";
};

["VIRTUALIZATION", 3, format["Finished initializing %1 objective groups - %2 groups created", _sideKey, count _allCreatedGroups]] call FLO_fnc_log;
diag_log format [
    "[FLO][PERF] Objective group seeding side=%1 objectives=%2 templates=%3 plannedGroups=%4 created=%5 staticAAVirtual=%6 total=%7 ms",
    _sideKey,
    count _plannedObjectives,
    _plannedTemplateCount,
    _plannedGroupCount,
    count _allCreatedGroups,
    _staticAAVirtualCount,
    (diag_tickTime - _seedT0) * 1000
];

true
