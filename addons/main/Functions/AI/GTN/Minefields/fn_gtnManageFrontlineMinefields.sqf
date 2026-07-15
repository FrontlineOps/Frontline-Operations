/*
 * Function: FLO_fnc_gtnManageFrontlineMinefields
 * Author: Frontline Operations Development Group
 * Description:
 *   Lets one GTN commander manage tracked objective minefields for its own
 *   side. This replaces the old autonomous manager loop so placement is driven
 *   directly by commander updates and objective state.
 *
 * Arguments:
 * 0: GTN commander <HASHMAPOBJECT>
 *
 * Return Value:
 * HASHMAP - Cycle metrics
 */

params [["_cmdr", nil]];

private _metrics = createHashMapFromArray [
    ["run", false],
    ["candidateObjectives", 0],
    ["activeFields", 0],
    ["enqueuedFields", 0],
    ["queuedBuilds", 0],
    ["removedFields", 0],
    ["placedFields", 0],
    ["cleanupMs", 0],
    ["staleMs", 0],
    ["candidateBuildMs", 0],
    ["contextResolveMs", 0],
    ["queueMs", 0],
    ["sortMs", 0],
    ["placementMs", 0],
    ["layoutBuildMs", 0],
    ["layoutFrontageMs", 0],
    ["layoutRoadMs", 0],
    ["layoutCoverMs", 0],
    ["layoutBypassMs", 0],
    ["resourceBudgetMs", 0],
    ["spawnMs", 0],
    ["totalMs", 0],
    ["plannedMines", 0],
    ["affordableMines", 0],
    ["placedMines", 0],
    ["spentResources", 0],
    ["resourceSkips", 0],
    ["plannedPackets", 0],
    ["attemptedSlots", 0],
    ["acceptedDirectSlots", 0],
    ["acceptedFallbackSlots", 0],
    ["rejectedNoSafePos", 0],
    ["rejectedWater", 0],
    ["rejectedDefendedObjective", 0],
    ["rejectedForeignObjective", 0],
    ["rejectedSpacing", 0]
];

if (isNil "_cmdr") exitWith { _metrics };
if (!isServer) exitWith { _metrics };
if (isNil "FLO_Objectives") exitWith { _metrics };
if (isNil "FLO_Minefields") exitWith { _metrics };

private _config = _cmdr get "_config";
private _now = diag_tickTime;
private _refreshMinSeconds = (_config get "minefieldRefreshMinSeconds") max 1;
private _runDue = (_cmdr get "_minefieldDirty")
    || {(_cmdr get "_lastMinefieldRunAt") < 0}
    || {_now - (_cmdr get "_lastMinefieldRunAt") >= _refreshMinSeconds};

if (!_runDue) exitWith { _metrics };

_metrics set ["run", true];
_cmdr set ["_minefieldDirty", false];
_cmdr set ["_lastMinefieldRunAt", _now];
private _tCycle = diag_tickTime;

private _ownSide = _cmdr get "_ownSide";
private _sideKey = _cmdr get "_sideKey";
private _activePlayerSide = FLO_ActivePlayerSide;
private _playerProximityMeters = (["activationDistance"] call FLO_fnc_virtualizationGetConfigValue) + (FLO_MinefieldConfig get "playerProximityActivationBufferMeters");
private _activePlayerPositions = [];
if (_activePlayerSide in [east, west]) then {
    {
        if (alive _x && {(side group _x) isEqualTo _activePlayerSide}) then {
            _activePlayerPositions pushBack (getPosATL _x);
        };
    } forEach ([] call FLO_fnc_getConnectedHumanPlayers);
};
private _maxFields = _config get "minefieldMaxFields";
private _placementsPerCycle = _config get "minefieldPlacementsPerCycle";
private _nowDateNum = call FLO_fnc_operationalDateNumber;
private _frontlineEnemyObjectives = _cmdr call ["_getAttackFrontlineEnemyObjectives", []];

private _tPhase = diag_tickTime;
{
    private _fieldId = _x;
    private _field = FLO_Minefields get _fieldId;
    if (isNil "_field") then { continue };
    if ((_field get "side") != _ownSide) then { continue };

    private _activeCount = [_fieldId] call FLO_fnc_minefieldCleanupDestroyedMines;
    if (_activeCount <= 0) then {
        _metrics set ["removedFields", (_metrics get "removedFields") + 1];
    };
} forEach +(keys FLO_Minefields);
_metrics set ["cleanupMs", (diag_tickTime - _tPhase) * 1000];

_tPhase = diag_tickTime;
{
    private _fieldId = _x;
    private _field = FLO_Minefields get _fieldId;
    if (isNil "_field") then { continue };
    if ((_field get "side") != _ownSide) then { continue };

    private _seed = [(_field get "objectiveId"), _ownSide, _cmdr] call FLO_fnc_minefieldBuildObjectiveCandidateSeed;
    if ((keys _seed) isEqualTo []) then {
        if ([_fieldId, "STALE"] call FLO_fnc_minefieldDeleteField) then {
            _metrics set ["removedFields", (_metrics get "removedFields") + 1];
        };
        continue;
    };

    if ((_seed get "threatSignature") != (_field get "threatSignature")) then {
        if ([_fieldId, "STALE"] call FLO_fnc_minefieldDeleteField) then {
            _metrics set ["removedFields", (_metrics get "removedFields") + 1];
        };
    };
} forEach +(keys FLO_Minefields);
_metrics set ["staleMs", (diag_tickTime - _tPhase) * 1000];

private _activeFieldCount = 0;
{
    if ((_y get "sideKey") == _sideKey) then {
        _activeFieldCount = _activeFieldCount + 1;
    };
} forEach FLO_Minefields;
_metrics set ["activeFields", _activeFieldCount];

private _queuedFieldCount = 0;
{
    if ((_y get "sideKey") == _sideKey) then {
        _queuedFieldCount = _queuedFieldCount + 1;
    };
} forEach ((FLO_MinefieldBuild get "jobs"));
_metrics set ["queuedBuilds", _queuedFieldCount];

private _remainingCapacity = _maxFields - _activeFieldCount - _queuedFieldCount;
if (_remainingCapacity <= 0 || {_placementsPerCycle <= 0}) exitWith {
    _metrics set ["totalMs", (diag_tickTime - _tCycle) * 1000];
    _metrics
};

private _candidates = [];
_tPhase = diag_tickTime;
private _candidateObjectiveIds = [];
{
    {
        _candidateObjectiveIds pushBackUnique _x;
    } forEach (_cmdr call ["_getFriendlyAttackSourceObjectives", [_x]]);
} forEach _frontlineEnemyObjectives;

if (_ownSide isNotEqualTo _activePlayerSide && {_activePlayerSide in [east, west]} && {_activePlayerPositions isNotEqualTo []}) then {
    {
        private _objectiveId = _x;
        if (_objectiveId in FLO_MinefieldObjectiveIndex) then { continue };
        if (_objectiveId in (FLO_MinefieldBuild get "objectiveIndex")) then { continue };

        private _cooldownUntil = FLO_MinefieldObjectiveCooldowns getOrDefault [_objectiveId, -1];
        if (_cooldownUntil > _nowDateNum) then { continue };

        if !([_objectiveId, _activePlayerSide, _playerProximityMeters, _activePlayerPositions] call FLO_fnc_minefieldObjectiveHasNearbyPlayer) then { continue };

        private _seed = [_objectiveId, _ownSide, _cmdr] call FLO_fnc_minefieldBuildObjectiveCandidateSeed;
        if ((keys _seed) isEqualTo []) then { continue };

        _candidates pushBack _seed;
    } forEach _candidateObjectiveIds;
};
_metrics set ["candidateBuildMs", (diag_tickTime - _tPhase) * 1000];

_metrics set ["candidateObjectives", count _candidates];
if (_candidates isEqualTo []) exitWith {
    _metrics set ["totalMs", (diag_tickTime - _tCycle) * 1000];
    _metrics
};

_tPhase = diag_tickTime;
private _ranked = [_candidates, [], { _x get "score" }, "DESCEND"] call BIS_fnc_sortBy;
_metrics set ["sortMs", (diag_tickTime - _tPhase) * 1000];
private _placementsRemaining = _placementsPerCycle min _remainingCapacity;

_tPhase = diag_tickTime;
{
    if (_placementsRemaining <= 0) exitWith {};

    private _queueResult = [_x] call FLO_fnc_minefieldQueueObjectiveBuild;
    if !(_queueResult get "queued") then { continue };

    _placementsRemaining = _placementsRemaining - 1;
    _metrics set ["enqueuedFields", (_metrics get "enqueuedFields") + 1];
    _metrics set ["queuedBuilds", (_metrics get "queuedBuilds") + 1];
} forEach _ranked;
_metrics set ["queueMs", (diag_tickTime - _tPhase) * 1000];
_metrics set ["totalMs", (diag_tickTime - _tCycle) * 1000];

if ((_metrics get "removedFields") > 0 || {(_metrics get "enqueuedFields") > 0} || {(_metrics get "resourceSkips") > 0} || {(_metrics get "totalMs") > 25}) then {
    diag_log format [
        "[FLO][PERF] GTN minefield queue %1 active=%2 queued=%3 frontlineEnemy=%4 candidateObjectives=%5 removed=%6 enqueued=%7 resourceSkips=%8 | cleanup=%9 stale=%10 build=%11 sort=%12 queue=%13 total=%14",
        _sideKey,
        _metrics get "activeFields",
        _metrics get "queuedBuilds",
        count _frontlineEnemyObjectives,
        _metrics get "candidateObjectives",
        _metrics get "removedFields",
        _metrics get "enqueuedFields",
        _metrics get "resourceSkips",
        _metrics get "cleanupMs",
        _metrics get "staleMs",
        _metrics get "candidateBuildMs",
        _metrics get "sortMs",
        _metrics get "queueMs",
        _metrics get "totalMs"
    ];
};

_metrics
