/*
 * Function: FLO_fnc_gtnAllocateFrontlineAttacks
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Fill attack deficits across frontline objectives using a graph-local, round-robin allocator.
 * Existing attackers stay sticky on their current objective. Only currently available groups are assigned.
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
    ["remainingPool", 0]
];

if (isNil "_cmdr" || {isNil "_track"}) exitWith { _metrics };

private _phase = _track get "phase";
private _phaseObjectiveId = _track get "phaseObjectiveId";
_metrics set ["phase", _phase];
_metrics set ["phaseObjective", _phaseObjectiveId];

private _pool = +(_track get "groupPool");
_metrics set ["poolCount", count _pool];
_metrics set ["remainingPool", count _pool];
if ((count _pool) == 0) exitWith { _metrics };
if (_phase != "assault") exitWith { _metrics };

private _ws = _cmdr get "_worldState";
private _ownSide = _cmdr get "_ownSide";
private _groups = FLO_virtualGroups get "_groups";
private _frontlineObjectives = _ws call ["_getFrontlineEnemyObjectives", []];
if ((count (keys _frontlineObjectives)) == 0) then {
    _frontlineObjectives = _ws call ["_getEnemyObjectives", []];
};
if ((count (keys _frontlineObjectives)) == 0) exitWith { _metrics };

private _trackSectorObjectives = _track get "frontSectorObjectives";
private _trackAnchorPos = +(_track get "frontSectorAnchorPos");
private _reserveGraphDepth = ((_cmdr get "_config") get "attackReserveGraphDepth");
private _fallbackBand = _reserveGraphDepth + 1;

private _activeAttackCounts = createHashMap;
{
    private _gData = _y;
    if ((_gData get "side") != _ownSide) then { continue };
    if ((_gData get "currentOrder") != "ATTACK") then { continue };

    private _attackObjective = _gData get "attackObjective";
    if (_attackObjective == "") then { continue };

    private _activeAttackCount = if (_attackObjective in _activeAttackCounts) then {
        _activeAttackCounts get _attackObjective
    } else {
        0
    };
    _activeAttackCounts set [_attackObjective, _activeAttackCount + 1];
} forEach _groups;

private _candidateObjectives = [];
{
    private _objectiveId = _x;
    if (_phaseObjectiveId != "" && {_objectiveId != _phaseObjectiveId}) then { continue };

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
        || { (count ((_objective get "linkedObjectives") arrayIntersect _trackSectorObjectives)) > 0 };
    private _pressure = ((_objective get "enemyCount") - (_objective get "friendlyCount")) max 0;
    private _reserveBands = [_cmdr, _sourceObjectives, _reserveGraphDepth] call FLO_fnc_gtnBuildObjectiveReserveBands;

    _candidateObjectives pushBack (createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["objectivePos", _objective get "position"],
        ["reserveBands", _reserveBands],
        ["sectorMatch", _sectorMatch],
        ["selectionDist", _selectionDist],
        ["priority", _objective get "priority"],
        ["pressure", _pressure],
        ["activeAttackers", _activeAttackers],
        ["deficit", _deficit]
    ]);
} forEach (keys _frontlineObjectives);

_metrics set ["candidateObjectives", count _candidateObjectives];
if ((count _candidateObjectives) == 0) exitWith { _metrics };

private _rankedCandidates = [];
{
    _rankedCandidates pushBack [
        if (_x get "sectorMatch") then { 0 } else { 1 },
        _x get "selectionDist",
        -(_x get "pressure"),
        -(_x get "priority"),
        _x
    ];
} forEach _candidateObjectives;
_rankedCandidates sort true;
_candidateObjectives = _rankedCandidates apply { _x select 4 };

private _assignedByObjective = createHashMap;
private _continueAllocation = true;

while {_continueAllocation && {(count _pool) > 0}} do {
    _continueAllocation = false;

    {
        private _deficit = _x get "deficit";
        if (_deficit <= 0) then { continue };

        private _objectiveId = _x get "objectiveId";
        private _objectivePos = _x get "objectivePos";
        private _reserveBands = _x get "reserveBands";

        private _bestGroupId = "";
        private _bestBand = 10;
        private _bestDist = 1e12;

        {
            private _groupId = _x;
            private _gData = _groups get _groupId;
            if (isNil "_gData") then { continue };
            if ((_gData get "side") != _ownSide) then { continue };
            if !((_gData get "groupType") in ["infantry", "recon", "motorized", "mechanized", "armor"]) then { continue };

            private _groupPos = _gData get "position";
            private _homeObjective = _gData get "homeObjective";
            private _distToObjective = _groupPos distance2D _objectivePos;
            private _band = _fallbackBand;
            if (_homeObjective in _reserveBands) then {
                _band = _reserveBands get _homeObjective;
            };

            if (_band < _bestBand || {_band == _bestBand && {_distToObjective < _bestDist}}) then {
                _bestGroupId = _groupId;
                _bestBand = _band;
                _bestDist = _distToObjective;
            };
        } forEach _pool;

        if (_bestGroupId == "") then { continue };

        if (_cmdr call ["_orderGroupAttack", [_bestGroupId, _objectivePos, _objectiveId]]) then {
            _pool = _pool - [_bestGroupId];
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
            _pool = _pool - [_bestGroupId];
        };
    } forEach _candidateObjectives;
};

_track set ["groupPool", _pool];
_metrics set ["remainingPool", count _pool];

["GTN", 3, format[
    "Track %1 frontline attack allocation: assigned=%2 opened=%3 reinforced=%4 candidates=%5 remaining=%6",
    _track get "id",
    _metrics get "assignedGroups",
    _metrics get "openedObjectives",
    _metrics get "reinforcedObjectives",
    _metrics get "candidateObjectives",
    _metrics get "remainingPool"
]] call FLO_fnc_log;

_metrics
