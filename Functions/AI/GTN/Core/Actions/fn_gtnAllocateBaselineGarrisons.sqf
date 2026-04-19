/*
 * Function: FLO_fnc_gtnAllocateBaselineGarrisons
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Maintains a standing garrison floor on owned objectives before the commander
 *   commits surplus groups to offensive tracks.
 *
 * Arguments:
 *   0: GTN Commander <HASHMAP>
 *
 * Return Value:
 *   Metrics <HASHMAP>
 */

params [["_cmdr", nil]];

private _metrics = createHashMapFromArray [
    ["existingGarrisons", 0],
    ["releasedGroups", 0],
    ["candidateObjectives", 0],
    ["eligibleGroups", 0],
    ["assignedGroups", 0],
    ["openedObjectives", 0],
    ["reinforcedObjectives", 0],
    ["reserveBandBuilds", 0],
    ["assignmentPasses", 0]
];

if (isNil "_cmdr") exitWith { _metrics };

private _ws = _cmdr get "_worldState";
private _objectives = _ws call ["_getObjectives", []];
if ((count _objectives) == 0) exitWith { _metrics };

private _groups = FLO_virtualGroups get "_groups";
private _ownSide = _cmdr get "_ownSide";
private _enemySide = _cmdr get "_enemySide";
private _reserveGraphDepth = ((_cmdr get "_config") get "defenseReserveGraphDepth");
private _fallbackBand = _reserveGraphDepth + 1;
private _assignmentLimit = ((_cmdr get "_config") get "garrisonAssignmentsPerCycle") max 0;
private _assignableGroupTypes = ["infantry", "motorized", "mechanized", "armor"];
private _assignmentCache = _cmdr get "_objectiveAssignmentCache";

private _garrisonGroupsByObjective = createHashMap;
private _garrisonPositionsByObjective = createHashMap;
private _releaseIds = [];

{
    private _ids = +_y;
    _garrisonGroupsByObjective set [_x, _ids];
    _metrics set ["existingGarrisons", (_metrics get "existingGarrisons") + count _ids];
} forEach (_assignmentCache get "garrisonGroupsByObjective");

{
    _garrisonPositionsByObjective set [_x, +_y];
} forEach (_assignmentCache get "garrisonPositionsByObjective");

{
    private _objectiveId = _x;
    private _garrisonIds = _garrisonGroupsByObjective get _objectiveId;
    private _objective = _objectives get _objectiveId;
    if (isNil "_objective") then {
        { _releaseIds pushBackUnique _x; } forEach _garrisonIds;
        continue;
    };
    if ((_objective get "owner") != _ownSide) then {
        { _releaseIds pushBackUnique _x; } forEach _garrisonIds;
        continue;
    };
    private _cap = _cmdr call ["_getGarrisonCapForObjective", [_objectiveId]];

    if (_cap <= 0) then {
        { _releaseIds pushBackUnique _x; } forEach _garrisonIds;
        continue;
    };

    if ((count _garrisonIds) <= _cap) then { continue };

    private _ranked = [];
    {
        private _gData = _groups get _x;
        _ranked pushBack [
            if (_gData get "inCombat") then { 0 } else { 1 },
            (_gData get "position") distance2D (_objective get "position"),
            _x
        ];
    } forEach _garrisonIds;
    _ranked sort true;

    private _keptIds = [];
    private _keptPositions = [];
    for "_i" from 0 to (_cap - 1) do {
        private _keptId = (_ranked select _i) select 2;
        _keptIds pushBack _keptId;

        private _keptGroup = _groups get _keptId;
        private _keptPos = _keptGroup get "garrisonPosition";
        if !(_keptPos isEqualType [] && {count _keptPos >= 2}) then {
            _keptPos = _keptGroup get "position";
        };
        _keptPositions pushBack _keptPos;
    };
    _garrisonGroupsByObjective set [_objectiveId, _keptIds];
    _garrisonPositionsByObjective set [_objectiveId, _keptPositions];

    for "_i" from _cap to ((count _ranked) - 1) do {
        _releaseIds pushBackUnique ((_ranked select _i) select 2);
    };
} forEach (keys _garrisonGroupsByObjective);

if ((count _releaseIds) > 0) then {
    {
        private _gData = _groups get _x;
        if (isNil "_gData") then { continue };
        [_gData] call FLO_fnc_virtualizationClearMissionLock;
    } forEach _releaseIds;

    _cmdr call ["_releaseGroups", [_releaseIds, ""]];
    _metrics set ["releasedGroups", count _releaseIds];
};

if (_assignmentLimit <= 0 || {!(_cmdr call ["_hasStrategicOrderBudget", []])}) exitWith { _metrics };

if (_cmdr get "_availabilityCacheDirty") then {
    _cmdr call ["_rebuildAvailabilityCache", []];
};

private _available = [];
{
    _x params ["_groupId", "_gData"];
    if !((_gData get "groupType") in _assignableGroupTypes) then { continue };
    _available pushBack [_groupId, _gData, _gData get "homeObjective", _gData get "position"];
} forEach (_cmdr get "_availabilityCandidates");

_metrics set ["eligibleGroups", count _available];
if ((count _available) == 0) exitWith { _metrics };

private _candidateObjectives = [];
{
    private _objectiveId = _x;
    private _objective = _y;
    if ((_objective get "owner") != _ownSide) then { continue };

    private _cap = _cmdr call ["_getGarrisonCapForObjective", [_objectiveId]];
    if (_cap <= 0) then { continue };

    private _assigned = if (_objectiveId in _garrisonGroupsByObjective) then {
        count (_garrisonGroupsByObjective get _objectiveId)
    } else {
        0
    };
    private _deficit = (_cap - _assigned) max 0;
    if (_deficit <= 0) then { continue };

    private _enemyLinkedCount = 0;
    {
        private _linkedObjective = _objectives get _x;
        if (isNil "_linkedObjective") then { continue };
        if ((_linkedObjective get "owner") == _enemySide) then {
            _enemyLinkedCount = _enemyLinkedCount + 1;
        };
    } forEach (_objective get "linkedObjectives");

    private _underAttack = _objective get "underAttack";
    private _contested = _objective get "contested";
    private _pressureBand = 2;
    if (_underAttack || _contested) then {
        _pressureBand = 0;
    } else {
        if (_enemyLinkedCount > 0) then {
            _pressureBand = 1;
        };
    };

    private _pressure = (_enemyLinkedCount * 2)
        + (if (_underAttack) then { 4 } else { 0 })
        + (if (_contested) then { 2 } else { 0 });

    _candidateObjectives pushBack (createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["objectivePos", _objective get "position"],
        ["pressureBand", _pressureBand],
        ["pressure", _pressure],
        ["priority", _objective get "priority"],
        ["activeGarrisons", _assigned],
        ["deficit", _deficit]
    ]);
} forEach _objectives;

_metrics set ["candidateObjectives", count _candidateObjectives];
if ((count _candidateObjectives) == 0) exitWith { _metrics };

private _rankedCandidates = [];
{
    _rankedCandidates pushBack [
        _x get "pressureBand",
        -(_x get "pressure"),
        -(_x get "priority"),
        _x
    ];
} forEach _candidateObjectives;
_rankedCandidates sort true;
_candidateObjectives = _rankedCandidates apply { _x select 3 };

private _assignedByObjective = createHashMap;
private _continueAllocation = true;

while {_continueAllocation && {(count _available) > 0}} do {
    _continueAllocation = false;
    private _stopAllocation = false;
    _metrics set ["assignmentPasses", (_metrics get "assignmentPasses") + 1];

    {
        if (_stopAllocation) then { continue };
        if ((_metrics get "assignedGroups") >= _assignmentLimit) then {
            _stopAllocation = true;
            continue;
        };
        if !(_cmdr call ["_hasStrategicOrderBudget", []]) then {
            _stopAllocation = true;
            continue;
        };

        private _deficit = _x get "deficit";
        if (_deficit <= 0) then { continue };

        private _objectiveId = _x get "objectiveId";
        private _objectivePos = _x get "objectivePos";
        private _reserveBands = if ("reserveBands" in _x) then {
            _x get "reserveBands"
        } else {
            private _bands = [_cmdr, [_objectiveId], _reserveGraphDepth] call FLO_fnc_gtnGetCachedReserveBands;
            _x set ["reserveBands", _bands];
            _metrics set ["reserveBandBuilds", (_metrics get "reserveBandBuilds") + 1];
            _bands
        };

        private _bestGroupId = "";
        private _bestIndex = -1;
        private _bestBand = 10;
        private _bestDist = 1e12;

        for "_i" from 0 to ((count _available) - 1) do {
            (_available select _i) params ["_groupId", "_gData", "_homeObjective", "_groupPos"];
            private _band = _fallbackBand;
            if (_homeObjective in _reserveBands) then {
                _band = _reserveBands get _homeObjective;
            };

            private _distToObjective = _groupPos distance2D _objectivePos;
            if (_band < _bestBand || {_band == _bestBand && {_distToObjective < _bestDist}}) then {
                _bestGroupId = _groupId;
                _bestIndex = _i;
                _bestBand = _band;
                _bestDist = _distToObjective;
            };
        };

        if (_bestGroupId == "") then { continue };

        private _claimedPositions = if (_objectiveId in _garrisonPositionsByObjective) then {
            _garrisonPositionsByObjective get _objectiveId
        } else {
            []
        };
        private _garrisonPos = [_cmdr, _objectiveId, _claimedPositions] call FLO_fnc_gtnPickObjectiveGarrisonPosition;

        if (_cmdr call ["_orderGroupGarrison", [_bestGroupId, _garrisonPos, _objectiveId, true]]) then {
            _available deleteAt _bestIndex;
            _x set ["deficit", _deficit - 1];
            _metrics set ["assignedGroups", (_metrics get "assignedGroups") + 1];
            _continueAllocation = true;
            _claimedPositions pushBack _garrisonPos;
            _garrisonPositionsByObjective set [_objectiveId, _claimedPositions];

            private _assignedHere = if (_objectiveId in _assignedByObjective) then {
                _assignedByObjective get _objectiveId
            } else {
                0
            };

            if (_assignedHere == 0) then {
                if ((_x get "activeGarrisons") > 0) then {
                    _metrics set ["reinforcedObjectives", (_metrics get "reinforcedObjectives") + 1];
                } else {
                    _metrics set ["openedObjectives", (_metrics get "openedObjectives") + 1];
                };
            };

            _assignedByObjective set [_objectiveId, _assignedHere + 1];
        } else {
            _available deleteAt _bestIndex;
        };
    } forEach _candidateObjectives;

    if (_stopAllocation) then {
        _continueAllocation = false;
    };
};

["GTN", 3, format [
    "Baseline garrison allocation: released=%1 assigned=%2 opened=%3 reinforced=%4 candidates=%5 eligible=%6 reserveBands=%7 passes=%8",
    _metrics get "releasedGroups",
    _metrics get "assignedGroups",
    _metrics get "openedObjectives",
    _metrics get "reinforcedObjectives",
    _metrics get "candidateObjectives",
    _metrics get "eligibleGroups",
    _metrics get "reserveBandBuilds",
    _metrics get "assignmentPasses"
]] call FLO_fnc_log;

_metrics
