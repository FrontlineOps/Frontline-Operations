/*
 * Function: FLO_fnc_gtnAllocateFrontlineAttacks
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Fill attack deficits across frontline objectives using a graph-local,
 * round-robin allocator. Existing attackers stay sticky on their current
 * objective. Only currently available groups are assigned.
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
    ["phase", ""],
    ["phaseObjective", ""],
    ["poolCount", 0],
    ["candidateObjectives", 0],
    ["assignedGroups", 0],
    ["openedObjectives", 0],
    ["reinforcedObjectives", 0],
    ["remainingPool", 0],
    ["candidateBuildMs", 0],
    ["reserveBandMs", 0],
    ["signatureMs", 0],
    ["selectionMs", 0],
    ["orderMs", 0],
    ["totalMs", 0]
];

if (isNil "_cmdr" || {isNil "_track"}) exitWith { _metrics };

private _tTotal = diag_tickTime;
private _phase = _track get "phase";
private _phaseObjectiveId = _track get "phaseObjectiveId";
_metrics set ["phase", _phase];
_metrics set ["phaseObjective", _phaseObjectiveId];

private _pool = +(_track get "groupPool");
_metrics set ["poolCount", count _pool];
_metrics set ["remainingPool", count _pool];
if ((count _pool) == 0) exitWith { _metrics };
if (_phase != "assault") exitWith { _metrics };
if !(_cmdr call ["_hasStrategicOrderBudget", []]) exitWith { _metrics };

private _ownSide = _cmdr get "_ownSide";
private _groups = FLO_virtualGroups get "_groups";
private _assignmentCache = _cmdr get "_objectiveAssignmentCache";
private _frontlineObjectives = _cmdr call ["_getAttackFrontlineEnemyObjectives", []];
if ((count (keys _frontlineObjectives)) == 0) exitWith { _metrics };

private _trackSectorObjectives = _track get "frontSectorObjectives";
private _trackAnchorPos = +(_track get "frontSectorAnchorPos");
private _reserveGraphDepth = ((_cmdr get "_config") get "attackReserveGraphDepth");
private _fallbackBand = _reserveGraphDepth + 1;
private _assignmentLimit = [_cmdr, "attackAssignmentsPerCycle"] call FLO_fnc_gtnGetTempoScaledAssignmentLimit;
private _activeAttackCounts = _assignmentCache get "attackCounts";
private _idleStrategicOrders = ["PATROL", "DEFEND", ""];

private _tCandidateBuild = diag_tickTime;
private _candidateObjectives = [];
{
    private _objectiveId = _x;
    private _objective = _frontlineObjectives get _objectiveId;
    private _attackCap = _cmdr call ["_getAttackCapForObjective", [_objectiveId]];
    if (_attackCap <= 0) then { continue };

    private _activeAttackers = if (_objectiveId in _activeAttackCounts) then {
        _activeAttackCounts get _objectiveId
    } else {
        0
    };
    private _deficit = (_attackCap - _activeAttackers) max 0;
    if (_deficit <= 0) then { continue };

    private _sourceObjectives = _cmdr call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
    if ((count _sourceObjectives) == 0) then { continue };

    private _selectionDist = if ((count _trackAnchorPos) >= 2) then {
        _trackAnchorPos distance2D (_objective get "position")
    } else {
        1e12
    };

    private _sectorMatch = (count _trackSectorObjectives) == 0
        || {(count (_sourceObjectives arrayIntersect _trackSectorObjectives)) > 0};
    private _pressure = ((_objective get "enemyCount") - (_objective get "friendlyCount")) max 0;
    private _phasePreferred = _phaseObjectiveId != "" && {_objectiveId == _phaseObjectiveId};

    _candidateObjectives pushBack (createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["objectivePos", _objective get "position"],
        ["sourceObjectives", _sourceObjectives],
        ["phasePreferred", _phasePreferred],
        ["sectorMatch", _sectorMatch],
        ["selectionDist", _selectionDist],
        ["priority", _objective get "priority"],
        ["pressure", _pressure],
        ["activeAttackers", _activeAttackers],
        ["deficit", _deficit]
    ]);
} forEach (keys _frontlineObjectives);
_metrics set ["candidateBuildMs", (diag_tickTime - _tCandidateBuild) * 1000];

_metrics set ["candidateObjectives", count _candidateObjectives];
if ((count _candidateObjectives) == 0) exitWith { _metrics };

private _rankedCandidates = [];
{
    _rankedCandidates pushBack [
        if (_x get "phasePreferred") then { 0 } else { 1 },
        if (_x get "sectorMatch") then { 0 } else { 1 },
        _x get "selectionDist",
        -(_x get "pressure"),
        -(_x get "priority"),
        _x
    ];
} forEach _candidateObjectives;
_rankedCandidates sort true;
_candidateObjectives = _rankedCandidates apply { _x select 5 };

private _poolEntries = [];
private _poolEntryById = createHashMap;
private _poolBucketsByHomeObjective = createHashMap;
private _fallbackPoolIds = [];

{
    private _groupId = _x;
    private _gData = _groups get _groupId;
    if (isNil "_gData") then { continue };
    if !([_gData, _ownSide, ["infantry", "motorized", "mechanized", "armor"], _idleStrategicOrders] call FLO_fnc_gtnGroupIsStrategicallyAssignable) then { continue };

    private _homeObjective = _gData get "homeObjective";
    private _groupPos = _gData get "position";

    _poolEntries pushBack _groupId;
    _poolEntryById set [_groupId, createHashMapFromArray [
        ["homeObjective", _homeObjective],
        ["position", _groupPos]
    ]];

    if (_homeObjective == "") then {
        _fallbackPoolIds pushBack _groupId;
    } else {
        private _bucket = if (_homeObjective in _poolBucketsByHomeObjective) then {
            _poolBucketsByHomeObjective get _homeObjective
        } else {
            []
        };
        _bucket pushBack _groupId;
        _poolBucketsByHomeObjective set [_homeObjective, _bucket];
    };
} forEach _pool;

private _assignedByObjective = createHashMap;
private _continueAllocation = true;
private _poolHomeObjectiveIds = keys _poolBucketsByHomeObjective;

while {_continueAllocation && {(count _poolEntries) > 0}} do {
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
            private _bands = [_cmdr, (_x get "sourceObjectives"), _reserveGraphDepth] call FLO_fnc_gtnGetCachedReserveBands;
            _metrics set ["reserveBandMs", (_metrics get "reserveBandMs") + ((diag_tickTime - _tReserve) * 1000)];
            _x set ["reserveBands", _bands];
            _bands
        };
        private _bandedSourceObjectives = if ("bandedSourceObjectives" in _x) then {
            _x get "bandedSourceObjectives"
        } else {
            private _reserveBandKeys = keys _reserveBands;
            _reserveBandKeys sort true;

            private _banded = [];
            {
                _banded pushBack [_reserveBands get _x, _x];
            } forEach _reserveBandKeys;
            _banded sort true;
            _x set ["bandedSourceObjectives", _banded];
            _banded
        };

        private _tSelection = diag_tickTime;
        private _bestGroupId = "";
        private _bestBand = 10;
        private _bestDist = 1e12;

        {
            _x params ["_band", "_sourceObjectiveId"];
            if (_band > _bestBand) exitWith {};
            if !(_sourceObjectiveId in _poolBucketsByHomeObjective) then { continue };

            {
                private _groupId = _x;
                if !(_groupId in _poolEntryById) then { continue };

                private _entry = _poolEntryById get _groupId;
                private _distToObjective = (_entry get "position") distance2D _objectivePos;
                if (_band < _bestBand || {_band == _bestBand && {_distToObjective < _bestDist}}) then {
                    _bestGroupId = _groupId;
                    _bestBand = _band;
                    _bestDist = _distToObjective;
                };
            } forEach (_poolBucketsByHomeObjective get _sourceObjectiveId);
        } forEach _bandedSourceObjectives;

        if (_bestGroupId == "") then {
            {
                private _groupId = _x;
                if !(_groupId in _poolEntryById) then { continue };

                private _entry = _poolEntryById get _groupId;
                private _distToObjective = (_entry get "position") distance2D _objectivePos;
                if (_fallbackBand < _bestBand || {_fallbackBand == _bestBand && {_distToObjective < _bestDist}}) then {
                    _bestGroupId = _groupId;
                    _bestBand = _fallbackBand;
                    _bestDist = _distToObjective;
                };
            } forEach _fallbackPoolIds;

            {
                private _homeObjectiveId = _x;
                if (_homeObjectiveId in _reserveBands) then { continue };

                {
                    private _groupId = _x;
                    if !(_groupId in _poolEntryById) then { continue };

                    private _entry = _poolEntryById get _groupId;
                    private _distToObjective = (_entry get "position") distance2D _objectivePos;
                    if (_fallbackBand < _bestBand || {_fallbackBand == _bestBand && {_distToObjective < _bestDist}}) then {
                        _bestGroupId = _groupId;
                        _bestBand = _fallbackBand;
                        _bestDist = _distToObjective;
                    };
                } forEach (_poolBucketsByHomeObjective get _homeObjectiveId);
            } forEach _poolHomeObjectiveIds;
        };
        _metrics set ["selectionMs", (_metrics get "selectionMs") + ((diag_tickTime - _tSelection) * 1000)];

        if (_bestGroupId == "") then { continue };

        private _tOrder = diag_tickTime;
        private _ordered = _cmdr call ["_orderGroupAttack", [_bestGroupId, _objectivePos, _objectiveId, true]];
        _metrics set ["orderMs", (_metrics get "orderMs") + ((diag_tickTime - _tOrder) * 1000)];

        if (_ordered) then {
            _poolEntryById deleteAt _bestGroupId;
            _poolEntries deleteAt (_poolEntries find _bestGroupId);
            _x set ["deficit", _deficit - 1];
            _metrics set ["assignedGroups", (_metrics get "assignedGroups") + 1];
            _continueAllocation = true;

            private _assignedHere = if (_objectiveId in _assignedByObjective) then {
                _assignedByObjective get _objectiveId
            } else {
                0
            };
            if (_assignedHere == 0) then {
                if ((_x get "activeAttackers") > 0) then {
                    _metrics set ["reinforcedObjectives", (_metrics get "reinforcedObjectives") + 1];
                } else {
                    _metrics set ["openedObjectives", (_metrics get "openedObjectives") + 1];
                };
            };
            _assignedByObjective set [_objectiveId, _assignedHere + 1];
        } else {
            _poolEntryById deleteAt _bestGroupId;
            _poolEntries deleteAt (_poolEntries find _bestGroupId);
        };
    } forEach _candidateObjectives;

    if (_stopAllocation) then {
        _continueAllocation = false;
    };
};

_track set ["groupPool", _poolEntries];
_metrics set ["remainingPool", count _poolEntries];
_metrics set ["totalMs", (diag_tickTime - _tTotal) * 1000];

["GTN", 3, format[
    "Track %1 frontline attack allocation: assigned=%2 opened=%3 reinforced=%4 candidates=%5 remaining=%6",
    _track get "id",
    _metrics get "assignedGroups",
    _metrics get "openedObjectives",
    _metrics get "reinforcedObjectives",
    _metrics get "candidateObjectives",
    _metrics get "remainingPool"
]] call FLO_fnc_log;

if ((_metrics get "totalMs") >= 20) then {
    diag_log format [
        "[FLO][PERF] GTN attack allocation %1 track=%2 phaseObjective=%3 candidates=%4 pool=%5 assigned=%6 remaining=%7 build=%8 reserve=%9 sig=%10 select=%11 order=%12 total=%13",
        _cmdr get "_sideKey",
        _track get "id",
        _phaseObjectiveId,
        _metrics get "candidateObjectives",
        _metrics get "poolCount",
        _metrics get "assignedGroups",
        _metrics get "remainingPool",
        _metrics get "candidateBuildMs",
        _metrics get "reserveBandMs",
        _metrics get "signatureMs",
        _metrics get "selectionMs",
        _metrics get "orderMs",
        _metrics get "totalMs"
    ];
};

_metrics
