/*
 * Function: FLO_fnc_gtnAllocateFrontlineAttacks
 * Description:
 *   Fills direct ATTACK deficits across every connected enemy frontline
 *   objective from the post-garrison, post-defense surplus pool.
 */

params [
    ["_cmdr", nil],
    ["_candidateGroupIds", [], [[]]]
];

private _metrics = createHashMapFromArray [
    ["poolCount", count _candidateGroupIds],
    ["frontlineObjectives", 0],
    ["candidateObjectives", 0],
    ["saturatedObjectives", 0],
    ["disconnectedObjectives", 0],
    ["landRejectedObjectives", 0],
    ["assignedGroups", 0],
    ["openedObjectives", 0],
    ["reinforcedObjectives", 0],
    ["effectiveCap", 0],
    ["routeRejected", 0],
    ["remainingPool", count _candidateGroupIds],
    ["candidateBuildMs", 0],
    ["reserveBandMs", 0],
    ["selectionMs", 0],
    ["orderMs", 0],
    ["totalMs", 0]
];

if (isNil "_cmdr" || {_candidateGroupIds isEqualTo []}) exitWith { _metrics };
if !(_cmdr call ["_hasStrategicOrderBudget", []]) exitWith { _metrics };

private _startedAt = diag_tickTime;
private _ownSide = _cmdr get "_ownSide";
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _assignmentCache = _cmdr get "_objectiveAssignmentCache";
private _activeAttackCounts = _assignmentCache get "attackCounts";
private _frontlineObjectives = _cmdr call ["_getAttackFrontlineEnemyObjectives", []];
_metrics set ["frontlineObjectives", count (keys _frontlineObjectives)];
private _config = _cmdr get "_config";
private _attackCap = [
    _config get "attackCoverageMultiplier",
    _config get "attackObjectiveGroupCap"
] call FLO_fnc_gtnResolveAttackCoverageCap;
_metrics set ["effectiveCap", _attackCap];
private _reserveGraphDepth = ((_cmdr get "_config") get "attackReserveGraphDepth");
private _fallbackBand = _reserveGraphDepth + 1;
private _assignmentLimit = [_cmdr, "attackAssignmentsPerCycle"] call FLO_fnc_gtnGetTempoScaledAssignmentLimit;
private _idleStrategicOrders = ["PATROL", "DEFEND", ""];

private _candidateBuildStartedAt = diag_tickTime;
private _rankedCandidates = [];
{
    private _objectiveId = _x;
    private _objective = _frontlineObjectives get _objectiveId;
    private _activeAttackers = if (_objectiveId in _activeAttackCounts) then {
        _activeAttackCounts get _objectiveId
    } else {
        0
    };
    private _deficit = (_attackCap - _activeAttackers) max 0;
    if (_deficit <= 0) then {
        _metrics set ["saturatedObjectives", (_metrics get "saturatedObjectives") + 1];
        continue
    };

    private _sourceObjectives = _cmdr call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
    if (_sourceObjectives isEqualTo []) then {
        _metrics set ["disconnectedObjectives", (_metrics get "disconnectedObjectives") + 1];
        continue
    };

    private _attackPos = [_objectiveId, _objective] call FLO_fnc_gtnResolveAttackLandAnchor;
    if (_attackPos isEqualTo []) then {
        _metrics set ["landRejectedObjectives", (_metrics get "landRejectedObjectives") + 1];
        continue
    };

    private _pressure = ((_objective get "enemyCount") - (_objective get "friendlyCount")) max 0;
    _rankedCandidates pushBack [
        -_pressure,
        -(_objective get "priority"),
        _objectiveId,
        createHashMapFromArray [
            ["objectiveId", _objectiveId],
            ["attackPos", _attackPos],
            ["sourceObjectives", _sourceObjectives],
            ["activeAttackers", _activeAttackers],
            ["deficit", _deficit]
        ]
    ];
} forEach (keys _frontlineObjectives);
_rankedCandidates sort true;
private _candidateObjectives = _rankedCandidates apply { _x select 3 };
_metrics set ["candidateBuildMs", (diag_tickTime - _candidateBuildStartedAt) * 1000];
_metrics set ["candidateObjectives", count _candidateObjectives];
if (_candidateObjectives isEqualTo []) exitWith {
    _metrics set ["totalMs", (diag_tickTime - _startedAt) * 1000];
    _metrics
};

private _poolEntries = [];
private _poolEntryById = createHashMap;
private _poolBucketsByHomeObjective = createHashMap;
private _fallbackPoolIds = [];
{
    private _groupId = _x;
    private _groupData = _groups get _groupId;
    if (isNil "_groupData") then { continue };
    if !([_groupData, _ownSide, ["infantry", "motorized", "mechanized", "armor"], _idleStrategicOrders] call FLO_fnc_gtnGroupIsStrategicallyAssignable) then { continue };

    private _homeObjective = _groupData get "homeObjective";
    _poolEntries pushBack _groupId;
    _poolEntryById set [_groupId, createHashMapFromArray [
        ["homeObjective", _homeObjective],
        ["position", _groupData get "position"]
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
} forEach _candidateGroupIds;

private _assignedByObjective = createHashMap;
private _poolHomeObjectiveIds = keys _poolBucketsByHomeObjective;
private _continueAllocation = true;
while {_continueAllocation && {_poolEntries isNotEqualTo []}} do {
    _continueAllocation = false;
    private _stopAllocation = false;

    {
        if (_stopAllocation) then { continue };
        if ((_metrics get "assignedGroups") >= _assignmentLimit || {!(_cmdr call ["_hasStrategicOrderBudget", []])}) then {
            _stopAllocation = true;
            continue;
        };

        private _deficit = _x get "deficit";
        if (_deficit <= 0) then { continue };

        private _objectiveId = _x get "objectiveId";
        private _attackPos = _x get "attackPos";
        private _reserveBands = if ("reserveBands" in _x) then {
            _x get "reserveBands"
        } else {
            private _reserveStartedAt = diag_tickTime;
            private _bands = [_cmdr, _x get "sourceObjectives", _reserveGraphDepth] call FLO_fnc_gtnGetCachedReserveBands;
            _metrics set ["reserveBandMs", (_metrics get "reserveBandMs") + ((diag_tickTime - _reserveStartedAt) * 1000)];
            _x set ["reserveBands", _bands];
            _bands
        };
        private _bandedSources = if ("bandedSources" in _x) then {
            _x get "bandedSources"
        } else {
            private _banded = [];
            { _banded pushBack [_reserveBands get _x, _x]; } forEach (keys _reserveBands);
            _banded sort true;
            _x set ["bandedSources", _banded];
            _banded
        };

        private _selectionStartedAt = diag_tickTime;
        private _bestGroupId = "";
        private _bestBand = 1e12;
        private _bestDistance = 1e12;
        {
            _x params ["_band", "_sourceObjectiveId"];
            if (_band > _bestBand) exitWith {};
            if !(_sourceObjectiveId in _poolBucketsByHomeObjective) then { continue };
            {
                if !(_x in _poolEntryById) then { continue };
                private _distance = ((_poolEntryById get _x) get "position") distance2D _attackPos;
                if (_band < _bestBand || {_band == _bestBand && {_distance < _bestDistance}}) then {
                    _bestGroupId = _x;
                    _bestBand = _band;
                    _bestDistance = _distance;
                };
            } forEach (_poolBucketsByHomeObjective get _sourceObjectiveId);
        } forEach _bandedSources;

        if (_bestGroupId == "") then {
            {
                if !(_x in _poolEntryById) then { continue };
                private _distance = ((_poolEntryById get _x) get "position") distance2D _attackPos;
                if (_fallbackBand < _bestBand || {_fallbackBand == _bestBand && {_distance < _bestDistance}}) then {
                    _bestGroupId = _x;
                    _bestBand = _fallbackBand;
                    _bestDistance = _distance;
                };
            } forEach _fallbackPoolIds;
            {
                if (_x in _reserveBands) then { continue };
                {
                    if !(_x in _poolEntryById) then { continue };
                    private _distance = ((_poolEntryById get _x) get "position") distance2D _attackPos;
                    if (_fallbackBand < _bestBand || {_fallbackBand == _bestBand && {_distance < _bestDistance}}) then {
                        _bestGroupId = _x;
                        _bestBand = _fallbackBand;
                        _bestDistance = _distance;
                    };
                } forEach (_poolBucketsByHomeObjective get _x);
            } forEach _poolHomeObjectiveIds;
        };
        _metrics set ["selectionMs", (_metrics get "selectionMs") + ((diag_tickTime - _selectionStartedAt) * 1000)];
        if (_bestGroupId == "") then { continue };

        private _orderStartedAt = diag_tickTime;
        private _ordered = _cmdr call ["_orderGroupAttack", [_bestGroupId, _attackPos, _objectiveId, true]];
        _metrics set ["orderMs", (_metrics get "orderMs") + ((diag_tickTime - _orderStartedAt) * 1000)];

        _poolEntryById deleteAt _bestGroupId;
        _poolEntries deleteAt (_poolEntries find _bestGroupId);
        if (_ordered) then {
            _x set ["deficit", _deficit - 1];
            _metrics set ["assignedGroups", (_metrics get "assignedGroups") + 1];
            _continueAllocation = true;

            private _assignedHere = if (_objectiveId in _assignedByObjective) then { _assignedByObjective get _objectiveId } else { 0 };
            if (_assignedHere == 0) then {
                if ((_x get "activeAttackers") > 0) then {
                    _metrics set ["reinforcedObjectives", (_metrics get "reinforcedObjectives") + 1];
                } else {
                    _metrics set ["openedObjectives", (_metrics get "openedObjectives") + 1];
                };
            };
            _assignedByObjective set [_objectiveId, _assignedHere + 1];
        } else {
            _metrics set ["routeRejected", (_metrics get "routeRejected") + 1];
        };
    } forEach _candidateObjectives;

    if (_stopAllocation) then { _continueAllocation = false };
};

_metrics set ["remainingPool", count _poolEntries];
_metrics set ["totalMs", (diag_tickTime - _startedAt) * 1000];

if ((_metrics get "assignedGroups") > 0) then {
    ["GTN", 3, format [
        "%1 direct attacks assigned=%2 opened=%3 reinforced=%4 fronts=%5 cap=%6 remaining=%7",
        _cmdr get "_sideKey",
        _metrics get "assignedGroups",
        _metrics get "openedObjectives",
        _metrics get "reinforcedObjectives",
        _metrics get "candidateObjectives",
        _metrics get "effectiveCap",
        _metrics get "remainingPool"
    ]] call FLO_fnc_log;
};

if ((_metrics get "totalMs") >= 20) then {
    diag_log format [
        "[FLO][PERF] GTN direct attacks %1 fronts=%2 eligible=%3 full=%4 disconnected=%5 noLand=%6 cap=%7 pool=%8 assigned=%9 routeRejected=%10 build=%11 reserve=%12 select=%13 order=%14 total=%15",
        _cmdr get "_sideKey",
        _metrics get "frontlineObjectives",
        _metrics get "candidateObjectives",
        _metrics get "saturatedObjectives",
        _metrics get "disconnectedObjectives",
        _metrics get "landRejectedObjectives",
        _metrics get "effectiveCap",
        _metrics get "poolCount",
        _metrics get "assignedGroups",
        _metrics get "routeRejected",
        _metrics get "candidateBuildMs",
        _metrics get "reserveBandMs",
        _metrics get "selectionMs",
        _metrics get "orderMs",
        _metrics get "totalMs"
    ];
};

_metrics
