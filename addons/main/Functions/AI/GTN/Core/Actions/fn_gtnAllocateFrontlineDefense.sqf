/*
 * Function: FLO_fnc_gtnAllocateFrontlineDefense
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Fill threatened friendly objectives with sticky defenders using a graph-local, round-robin allocator.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Track <HASHMAP>
 *
 * Return Value:
 * Metrics <HASHMAP>
 */

params [
    ["_cmdr", nil],
    ["_track", nil]
];

private _metrics = createHashMapFromArray [
    ["poolCount", 0],
    ["candidateObjectives", 0],
    ["assignedGroups", 0],
    ["openedObjectives", 0],
    ["reinforcedObjectives", 0],
    ["remainingPool", 0],
    ["candidateBuildMs", 0],
    ["reserveBandMs", 0],
    ["selectionMs", 0],
    ["orderMs", 0],
    ["totalMs", 0]
];

if (isNil "_cmdr" || {isNil "_track"}) exitWith { _metrics };

private _tTotal = diag_tickTime;
private _pool = +(_track get "groupPool");
_metrics set ["poolCount", count _pool];
_metrics set ["remainingPool", count _pool];
if (_pool isEqualTo []) exitWith { _metrics };
if !(_cmdr call ["_hasStrategicOrderBudget", []]) exitWith { _metrics };

private _ws = _cmdr get "_worldState";
private _ownSide = _cmdr get "_ownSide";
private _enemySide = _cmdr get "_enemySide";
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _assignmentCache = _cmdr get "_objectiveAssignmentCache";
private _objectives = _ws call ["_getObjectives", []];
private _reserveGraphDepth = ((_cmdr get "_config") get "defenseReserveGraphDepth");
private _fallbackBand = _reserveGraphDepth + 1;
private _assignmentLimit = [_cmdr, "defenseAssignmentsPerCycle"] call FLO_fnc_gtnGetTempoScaledAssignmentLimit;
private _claimedPositionsByObjective = createHashMap;
private _idleStrategicOrders = ["PATROL", "DEFEND", ""];
{
    _claimedPositionsByObjective set [_x, +_y];
} forEach (_assignmentCache get "claimedPositionsByObjective");
private _defenderCounts = _assignmentCache get "defenderCounts";

private _tCandidateBuild = diag_tickTime;
private _candidateObjectives = [];
{
    private _objectiveId = _x;
    private _objective = _y;
    if ((_objective get "owner") != _ownSide) then { continue };
    if !([_ownSide, _objectiveId] call FLO_fnc_campaignCanSupportObjective) then { continue };

    private _underAttack = _objective get "underAttack";
    private _contested = _objective get "contested";
    private _enemyCount = _objective get "enemyCount";
    private _frontlineThreat = false;
    if (!_underAttack && {!_contested} && {_enemyCount <= 0}) then { continue };

    if (!_underAttack && {!_contested}) then {
        {
            private _linkedObjective = _objectives get _x;
            if ((_linkedObjective get "owner") == _enemySide) exitWith {
                _frontlineThreat = true;
            };
        } forEach (_objective get "linkedObjectives");

        if (!_frontlineThreat && {_enemyCount <= 0}) then { continue };
    };

    private _cap = _cmdr call ["_getDefenseCapForObjective", [_objectiveId]];
    if (_cap <= 0) then { continue };

    private _activeDefenders = if (_objectiveId in _defenderCounts) then {
        _defenderCounts get _objectiveId
    } else {
        0
    };
    private _deficit = (_cap - _activeDefenders) max 0;
    if (_deficit <= 0) then { continue };

    private _pressureBand = 2;
    if (_underAttack) then {
        _pressureBand = 0;
    } else {
        if (_contested) then {
            _pressureBand = 1;
        };
    };

    private _pressure = ((_enemyCount - (_objective get "friendlyCount")) max 0) + ([0, 4] select (_underAttack));

    _candidateObjectives pushBack (createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["objectivePos", _objective get "position"],
        ["priority", _objective get "priority"],
        ["pressureBand", _pressureBand],
        ["pressure", _pressure],
        ["activeDefenders", _activeDefenders],
        ["deficit", _deficit]
    ]);
} forEach _objectives;
_metrics set ["candidateBuildMs", (diag_tickTime - _tCandidateBuild) * 1000];

_metrics set ["candidateObjectives", count _candidateObjectives];
if (_candidateObjectives isEqualTo []) exitWith { _metrics };

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

private _poolEntries = [];
{
    private _gData = _groups get _x;
    if (isNil "_gData") then { continue };
    if !([_gData, _ownSide, ["infantry", "motorized", "mechanized", "armor"], _idleStrategicOrders] call FLO_fnc_gtnGroupIsStrategicallyAssignable) then { continue };

    _poolEntries pushBack [
        _x,
        _gData get "homeObjective",
        _gData get "position"
    ];
} forEach _pool;

private _assignedByObjective = createHashMap;
private _continueAllocation = true;

while {_continueAllocation && {_poolEntries isNotEqualTo []}} do {
    _continueAllocation = false;
    private _stopAllocation = false;

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
            private _tReserve = diag_tickTime;
            private _bands = [_cmdr, [_objectiveId], _reserveGraphDepth] call FLO_fnc_gtnGetCachedReserveBands;
            _metrics set ["reserveBandMs", (_metrics get "reserveBandMs") + ((diag_tickTime - _tReserve) * 1000)];
            _x set ["reserveBands", _bands];
            _bands
        };

        private _tSelection = diag_tickTime;
        private _bestGroupId = "";
        private _bestIndex = -1;
        private _bestBand = 10;
        private _bestDist = 1e12;

        for "_i" from 0 to ((count _poolEntries) - 1) do {
            (_poolEntries select _i) params ["_groupId", "_homeObjective", "_groupPos"];
            private _distToObjective = _groupPos distance2D _objectivePos;
            private _band = _fallbackBand;
            if (_homeObjective in _reserveBands) then {
                _band = _reserveBands get _homeObjective;
            };

            if (_band < _bestBand || {_band == _bestBand && {_distToObjective < _bestDist}}) then {
                _bestGroupId = _groupId;
                _bestIndex = _i;
                _bestBand = _band;
                _bestDist = _distToObjective;
            };
        };
        _metrics set ["selectionMs", (_metrics get "selectionMs") + ((diag_tickTime - _tSelection) * 1000)];

        if (_bestGroupId == "") then { continue };

        private _claimedPositions = if (_objectiveId in _claimedPositionsByObjective) then {
            _claimedPositionsByObjective get _objectiveId
        } else {
            []
        };
        private _defendPos = [_cmdr, _objectiveId, _claimedPositions] call FLO_fnc_gtnPickObjectiveGarrisonPosition;

        private _tOrder = diag_tickTime;
        private _ordered = _cmdr call ["_orderGroupDefend", [_bestGroupId, _defendPos, _objectiveId, true, true]];
        _metrics set ["orderMs", (_metrics get "orderMs") + ((diag_tickTime - _tOrder) * 1000)];

        if (_ordered) then {
            _poolEntries deleteAt _bestIndex;
            _x set ["deficit", _deficit - 1];
            _metrics set ["assignedGroups", (_metrics get "assignedGroups") + 1];
            _continueAllocation = true;
            _claimedPositions pushBack _defendPos;
            _claimedPositionsByObjective set [_objectiveId, _claimedPositions];

            private _assignedHere = if (_objectiveId in _assignedByObjective) then {
                _assignedByObjective get _objectiveId
            } else {
                0
            };
            if (_assignedHere == 0) then {
                if ((_x get "activeDefenders") > 0) then {
                    _metrics set ["reinforcedObjectives", (_metrics get "reinforcedObjectives") + 1];
                } else {
                    _metrics set ["openedObjectives", (_metrics get "openedObjectives") + 1];
                };
            };
            _assignedByObjective set [_objectiveId, _assignedHere + 1];
        } else {
            _poolEntries deleteAt _bestIndex;
        };
    } forEach _candidateObjectives;

    if (_stopAllocation) then {
        _continueAllocation = false;
    };
};

_pool = _poolEntries apply { _x select 0 };
_track set ["groupPool", _pool];
_metrics set ["remainingPool", count _pool];
_metrics set ["totalMs", (diag_tickTime - _tTotal) * 1000];

["GTN", 3, format[
    "Track %1 frontline defense allocation: assigned=%2 opened=%3 reinforced=%4 candidates=%5 remaining=%6",
    _track get "id",
    _metrics get "assignedGroups",
    _metrics get "openedObjectives",
    _metrics get "reinforcedObjectives",
    _metrics get "candidateObjectives",
    _metrics get "remainingPool"
]] call FLO_fnc_log;

if ((_metrics get "totalMs") >= 20) then {
    diag_log format [
        "[FLO][PERF] GTN defense allocation %1 track=%2 candidates=%3 pool=%4 assigned=%5 remaining=%6 build=%7 reserve=%8 select=%9 order=%10 total=%11",
        _cmdr get "_sideKey",
        _track get "id",
        _metrics get "candidateObjectives",
        _metrics get "poolCount",
        _metrics get "assignedGroups",
        _metrics get "remainingPool",
        _metrics get "candidateBuildMs",
        _metrics get "reserveBandMs",
        _metrics get "selectionMs",
        _metrics get "orderMs",
        _metrics get "totalMs"
    ];
};

_metrics
