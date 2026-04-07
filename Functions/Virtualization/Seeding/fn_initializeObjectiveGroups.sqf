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

private _sideCtx = [_side] call FLO_fnc_gtnSideContext;
private _sideKey = _sideCtx get "sideKey";
private _spawnPlan = [_side] call FLO_fnc_buildObjectiveTemplateSpawnPlan;

["VIRTUALIZATION", 3, format["Initializing objective groups for %1", _sideKey]] call FLO_fnc_log;

private _allCreatedGroups = [];
private _plannedObjectives = keys _spawnPlan;

// Process each indexed objective
{
    private _objId = _x;
    private _objData = FLO_Objectives get _objId;
    private _subtype = _objData get "subtype";
    ["VIRTUALIZATION", 3, format["Processing %1 objective: %2 (Subtype: %3)", _sideKey, _objId, _subtype]] call FLO_fnc_log;

    private _groupsToCreate = _spawnPlan get _objId;
    private _objectiveGroups = [];

    {
        _x params ["_groupType", "_count"];
        private _createdGroups = [_objId, _groupType, _count, _side] call FLO_fnc_distributeVirtualGroups;
        _objectiveGroups append _createdGroups;
    } forEach _groupsToCreate;

    _allCreatedGroups append _objectiveGroups;

    {
        private _groupId = _x;
        private _groupData = (FLO_virtualGroups get "_groups") get _groupId;

        [_groupId, _groupData] call FLO_fnc_virtualizationAssignAutoPatrol;

        if ((_groupData get "groupType") == "static_aa") then {
            _groupData set ["alwaysActive", true];
            if ([_groupId, _groupData] call FLO_fnc_virtualizationTryActivateGroup) then {
                ["VIRTUALIZATION", 3, format["Static AA %1 activated immediately (always-on)", _groupId]] call FLO_fnc_log;
            } else {
                ["VIRTUALIZATION", 3, format["Static AA %1 flagged always-on but deferred by activation cap", _groupId]] call FLO_fnc_log;
            };
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

true
