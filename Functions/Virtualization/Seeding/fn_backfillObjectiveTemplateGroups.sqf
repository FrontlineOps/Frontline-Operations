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
if (count _subtypes == 0) exitWith { _result };
if (count _groupTypes == 0) exitWith { _result };
if (isNil "FLO_Objectives") exitWith { _result };
if (isNil "FLO_FactionCatalog") exitWith { _result };
if (isNil "FLO_virtualGroups") exitWith { _result };

private _normalizedSubtypes = [];
{
    if (_x isEqualType "") then {
        _normalizedSubtypes pushBackUnique (toLower _x);
    };
} forEach _subtypes;
if (count _normalizedSubtypes == 0) exitWith { _result };

private _requestedGroupTypes = createHashMap;
{
    if (_x isEqualType "") then {
        _requestedGroupTypes set [_x, true];
    };
} forEach _groupTypes;
if (count (keys _requestedGroupTypes) == 0) exitWith { _result };

private _sideCtx = [_side] call FLO_fnc_gtnSideContext;
private _sideKey = _sideCtx get "sideKey";
private _catalog = FLO_FactionCatalog get _sideKey;
private _objectiveTemplates = createHashMapFromArray (_catalog get "objectiveGroups");

private _eligibleObjectives = [];
private _eligibleObjectiveSet = createHashMap;
private _desiredByObjective = createHashMap;

{
    private _objectiveId = _x;
    private _objectiveData = FLO_Objectives get _objectiveId;
    if ((_objectiveData get "owner") != _side) then { continue };

    private _subtype = toLower (_objectiveData get "subtype");
    if !(_subtype in _normalizedSubtypes) then { continue };
    if !(_subtype in _objectiveTemplates) then { continue };

    private _desiredGroups = createHashMap;
    {
        _x params ["_groupType", "_count"];
        if !(_groupType in _requestedGroupTypes) then { continue };
        _desiredGroups set [_groupType, _count];
    } forEach (_objectiveTemplates get _subtype);

    if (count (keys _desiredGroups) == 0) then { continue };

    _eligibleObjectives pushBack _objectiveId;
    _eligibleObjectiveSet set [_objectiveId, true];
    _desiredByObjective set [_objectiveId, _desiredGroups];
} forEach (keys FLO_Objectives);

if (count _eligibleObjectives == 0) exitWith { _result };

private _currentCountsByObjective = createHashMap;
private _groups = FLO_virtualGroups get "_groups";

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
    private _desiredGroups = _desiredByObjective get _objectiveId;
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
            private _groupData = (FLO_virtualGroups get "_groups") get _x;
            [_x, _groupData] call FLO_fnc_virtualizationAssignAutoPatrol;

            if ((_groupData get "groupType") == "static_aa") then {
                _groupData set ["alwaysActive", true];
                [_x, _groupData] call FLO_fnc_virtualizationTryActivateGroup;
            };
        } forEach _newGroupIds;

        _createdGroups append _newGroupIds;
        _objectiveCreated append _newGroupIds;
        _details pushBack [_objectiveId, _groupType, _currentCount, _desiredCount, count _newGroupIds];
    } forEach (keys _desiredGroups);

    if (count _objectiveCreated > 0) then {
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

if (count _createdGroups > 0) then {
    ["VIRTUALIZATION", 2, format [
        "Objective template backfill for %1 created %2 groups across %3 objectives",
        _sideKey,
        count _createdGroups,
        count _eligibleObjectives
    ]] call FLO_fnc_log;
};

_result
