/*
 * Function: FLO_fnc_backfillObjectiveTemplateGroups
 * Author: Frontline Operations Development Group
 * Description:
 *   Backfills missing objective-seeded groups for one side by comparing the
 *   live virtual-group registry against the current faction objective template
 *   for the requested objective subtypes and group types.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Objective subtypes <ARRAY> - e.g. ["city"]
 *   2: Group types <ARRAY> - e.g. ["helicopter", "jet", "armor"]
 *
 * Return Value:
 *   HASHMAP - Backfill summary
 *
 * Example:
 *   [west, ["city"], ["helicopter", "jet", "armor"]] call FLO_fnc_backfillObjectiveTemplateGroups;
 */

params [
    ["_side", east, [east]],
    ["_subtypes", ["city"], [[]]],
    ["_groupTypes", [], [[]]]
];

private _result = createHashMapFromArray [
    ["processedObjectives", 0],
    ["createdGroups", []],
    ["createdCount", 0],
    ["details", []]
];

if !(_side in [east, west]) exitWith { _result };
if (_subtypes isEqualTo []) exitWith { _result };
if (_groupTypes isEqualTo []) exitWith { _result };
if (isNil "FLO_Objectives") exitWith { _result };
if (isNil "FLO_FactionCatalog") exitWith { _result };
if (isNil "FLO_VirtualForceRegistry") exitWith { _result };

private _normalizedSubtypes = [];
{
    if (_x isEqualType "") then {
        _normalizedSubtypes pushBackUnique (toLower _x);
    };
} forEach _subtypes;
if (_normalizedSubtypes isEqualTo []) exitWith { _result };

private _requestedGroupTypes = createHashMap;
{
    if (_x isEqualType "") then {
        _requestedGroupTypes set [_x, true];
    };
} forEach _groupTypes;
if ((keys _requestedGroupTypes) isEqualTo []) exitWith { _result };

private _sideKey = [_side] call FLO_fnc_sideKey;
private _spawnPlan = [_side, _normalizedSubtypes, keys _requestedGroupTypes] call FLO_fnc_buildObjectiveTemplateSpawnPlan;
private _eligibleObjectives = keys _spawnPlan;
private _eligibleObjectiveSet = createHashMap;

if (_eligibleObjectives isEqualTo []) exitWith { _result };

{
    _eligibleObjectiveSet set [_x, true];
} forEach _eligibleObjectives;

private _currentCountsByObjective = createHashMap;
private _groups = call FLO_fnc_virtualizationGetGroupMap;

{
    private _groupId = _x;
    private _groupData = _y;

    if ((_groupData get "side") != _side) then { continue };

    private _homeObjective = _groupData get "homeObjective";
    if !(_homeObjective in _eligibleObjectiveSet) then { continue };

    private _groupType = _groupData get "groupType";
    if !(_groupType in _requestedGroupTypes) then { continue };

    if ((_groupData get "organicPackageRole") == "dismount") then { continue };

    private _counts = _currentCountsByObjective get _homeObjective;
    if (isNil "_counts") then {
        _counts = createHashMap;
        _currentCountsByObjective set [_homeObjective, _counts];
    };

    _counts set [_groupType, (_counts getOrDefault [_groupType, 0]) + 1];
} forEach _groups;

private _createdGroups = [];
private _details = [];

{
    private _objectiveId = _x;
    private _desiredGroupsArray = _spawnPlan get _objectiveId;
    private _desiredGroups = createHashMap;
    {
        _x params ["_groupType", "_count"];
        _desiredGroups set [_groupType, _count];
    } forEach _desiredGroupsArray;
    private _counts = _currentCountsByObjective getOrDefault [_objectiveId, createHashMap];
    private _objectiveCreated = [];

    {
        private _groupType = _x;
        private _desiredCount = _desiredGroups get _groupType;
        private _currentCount = _counts getOrDefault [_groupType, 0];
        private _deficit = _desiredCount - _currentCount;

        if (_deficit <= 0) then {
            _details pushBack [_objectiveId, _groupType, _currentCount, _desiredCount, 0];
            continue;
        };

        private _newGroupIds = [_objectiveId, _groupType, _deficit, _side] call FLO_fnc_distributeVirtualGroups;
        {
            private _groupData = [_x] call FLO_fnc_virtualizationGetGroup;
            [_x] call FLO_fnc_virtualizationAssignAutoPatrol;

            if ((_groupData get "groupType") == "static_aa") then {
                [_x, createHashMapFromArray [["alwaysActive", true]]] call FLO_fnc_virtualizationPatchGroup;
                [_x] call FLO_fnc_virtualizationForceActivateGroup;
            };
        } forEach _newGroupIds;

        _createdGroups append _newGroupIds;
        _objectiveCreated append _newGroupIds;
        _details pushBack [_objectiveId, _groupType, _currentCount, _desiredCount, count _newGroupIds];
    } forEach (keys _desiredGroups);

    if (_objectiveCreated isNotEqualTo []) then {
        ["VIRTUALIZATION", 2, format [
            "Backfilled %1 objective %2 with %3 groups",
            _sideKey,
            _objectiveId,
            count _objectiveCreated
        ]] call FLO_fnc_log;
    };
} forEach _eligibleObjectives;

_result set ["processedObjectives", count _eligibleObjectives];
_result set ["createdGroups", _createdGroups];
_result set ["createdCount", count _createdGroups];
_result set ["details", _details];

if (_createdGroups isNotEqualTo []) then {
    ["VIRTUALIZATION", 2, format [
        "Objective template backfill for %1 created %2 groups across %3 objectives",
        _sideKey,
        count _createdGroups,
        count _eligibleObjectives
    ]] call FLO_fnc_log;
};

_result
