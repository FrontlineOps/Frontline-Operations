/*
 * Function: FLO_fnc_buildObjectiveTemplateSpawnPlan
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the side-owned objective seeding plan from the faction objective
 *   templates and applies optional side-wide group-type caps before any groups
 *   are created.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Objective subtypes <ARRAY> - Optional filter
 *   2: Group types <ARRAY> - Optional filter
 *
 * Return Value:
 *   HASHMAP - objectiveId -> [[groupType, count], ...]
 *
 * Example:
 *   [west, ["city"], ["artillery"]] call FLO_fnc_buildObjectiveTemplateSpawnPlan;
 */

params [
    ["_side", east, [east]],
    ["_subtypes", [], [[]]],
    ["_groupTypes", [], [[]]]
];

private _plan = createHashMap;

if !(_side in [east, west]) exitWith { _plan };
if (isNil "FLO_Objectives") exitWith { _plan };
if (isNil "FLO_FactionCatalog") exitWith { _plan };

private _sideCtx = [_side] call FLO_fnc_gtnSideContext;
private _sideKey = _sideCtx get "sideKey";
private _catalog = FLO_FactionCatalog get _sideKey;
private _objectiveTemplates = createHashMapFromArray (_catalog get "objectiveGroups");
private _rawCaps = _catalog get "objectiveGroupTypeCaps";
private _caps = createHashMap;

{
    _x params ["_groupType", "_cap"];
    _caps set [_groupType, _cap max 0];
} forEach _rawCaps;

private _subtypeFilter = createHashMap;
{
    if (_x isEqualType "") then {
        _subtypeFilter set [toLower _x, true];
    };
} forEach _subtypes;
private _useSubtypeFilter = count (keys _subtypeFilter) > 0;

private _groupTypeFilter = createHashMap;
{
    if (_x isEqualType "") then {
        _groupTypeFilter set [_x, true];
    };
} forEach _groupTypes;
private _useGroupTypeFilter = count (keys _groupTypeFilter) > 0;

private _desiredByObjective = createHashMap;

{
    private _objectiveId = _x;
    private _objectiveData = FLO_Objectives get _objectiveId;
    if ((_objectiveData get "owner") != _side) then { continue };

    private _subtype = toLower (_objectiveData get "subtype");
    if (_useSubtypeFilter && {!(_subtype in _subtypeFilter)}) then { continue };
    if !(_subtype in _objectiveTemplates) then { continue };

    private _desiredGroups = createHashMap;
    {
        _x params ["_groupType", "_count"];
        if (_useGroupTypeFilter && {!(_groupType in _groupTypeFilter)}) then { continue };
        _desiredGroups set [_groupType, _count];
    } forEach (_objectiveTemplates get _subtype);

    if (count (keys _desiredGroups) == 0) then { continue };
    _desiredByObjective set [_objectiveId, _desiredGroups];
} forEach (keys FLO_Objectives);

{
    private _groupType = _x;
    if (_useGroupTypeFilter && {!(_groupType in _groupTypeFilter)}) then { continue };

    private _remaining = _caps get _groupType;
    private _rankedObjectives = [];

    {
        private _objectiveId = _x;
        private _desiredGroups = _desiredByObjective get _objectiveId;
        private _desiredCount = _desiredGroups getOrDefault [_groupType, 0];
        if (_desiredCount <= 0) then { continue };

        private _objectiveData = FLO_Objectives get _objectiveId;
        _rankedObjectives pushBack [
            _objectiveId,
            _desiredCount,
            _objectiveData get "priority",
            _objectiveData get "radius"
        ];
    } forEach (keys _desiredByObjective);

    _rankedObjectives = [_rankedObjectives, [], {
        [
            -(_x select 2),
            -(_x select 3),
            _x select 0
        ]
    }, "ASCEND"] call BIS_fnc_sortBy;

    {
        private _objectiveId = _x select 0;
        private _desiredGroups = _desiredByObjective get _objectiveId;
        _desiredGroups set [_groupType, 0];
    } forEach _rankedObjectives;

    {
        _x params ["_objectiveId", "_desiredCount"];
        private _desiredGroups = _desiredByObjective get _objectiveId;
        private _allocated = _desiredCount min _remaining;
        _desiredGroups set [_groupType, _allocated];
        _remaining = _remaining - _allocated;
    } forEach _rankedObjectives;
} forEach (keys _caps);

{
    private _objectiveId = _x;
    private _desiredGroups = _desiredByObjective get _objectiveId;
    private _groupsToSpawn = [];

    {
        private _groupType = _x;
        private _count = _desiredGroups get _groupType;
        if (_count <= 0) then { continue };
        _groupsToSpawn pushBack [_groupType, _count];
    } forEach (keys _desiredGroups);

    if (_groupsToSpawn isNotEqualTo []) then {
        _plan set [_objectiveId, _groupsToSpawn];
    };
} forEach (keys _desiredByObjective);

_plan
