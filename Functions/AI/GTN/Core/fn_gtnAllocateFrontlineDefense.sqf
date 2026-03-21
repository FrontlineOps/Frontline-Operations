/*
 * Function: FLO_fnc_gtnAllocateFrontlineDefense
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Fill threatened friendly objectives with sticky defenders using a local-first, round-robin allocator.
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
    ["remainingPool", 0]
];

if (isNil "_cmdr" || {isNil "_track"}) exitWith { _metrics };

private _pool = +(_track get "groupPool");
_metrics set ["poolCount", count _pool];
_metrics set ["remainingPool", count _pool];
if ((count _pool) == 0) exitWith { _metrics };

private _ws = _cmdr get "_worldState";
private _ownSide = _cmdr get "_ownSide";
private _enemySide = _cmdr get "_enemySide";
private _groups = FLO_virtualGroups get "_groups";
private _objectives = _ws call ["_getObjectives", []];

private _candidateObjectives = [];
{
    private _objectiveId = _x;
    private _objective = _y;
    if ((_objective get "owner") != _ownSide) then { continue };

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

    private _activeDefenders = _cmdr call ["_countObjectiveDefenders", [_objectiveId]];
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

    private _pressure = ((_enemyCount - (_objective get "friendlyCount")) max 0) + (if (_underAttack) then { 4 } else { 0 });
    private _reserveDistances = [_cmdr, _objectiveId, "defense"] call FLO_fnc_gtnGetObjectiveReserveDistances;

    _candidateObjectives pushBack (createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["objectivePos", _objective get "position"],
        ["linkedObjectives", _objective get "linkedObjectives"],
        ["localReserveMeters", _reserveDistances select 0],
        ["maxPullDistanceMeters", _reserveDistances select 1],
        ["priority", _objective get "priority"],
        ["pressureBand", _pressureBand],
        ["pressure", _pressure],
        ["activeDefenders", _activeDefenders],
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

while {_continueAllocation && {(count _pool) > 0}} do {
    _continueAllocation = false;

    {
        private _deficit = _x get "deficit";
        if (_deficit <= 0) then { continue };

        private _objectiveId = _x get "objectiveId";
        private _objectivePos = _x get "objectivePos";
        private _linkedObjectives = _x get "linkedObjectives";
        private _localReserveMeters = _x get "localReserveMeters";
        private _maxPullDistanceMeters = _x get "maxPullDistanceMeters";

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
            private _homeObjective = _gData getOrDefault ["homeObjective", ""];
            private _distToObjective = _groupPos distance2D _objectivePos;
            private _band = 4;

            if (_homeObjective == _objectiveId) then {
                _band = 0;
            } else {
                if (_homeObjective in _linkedObjectives) then {
                    _band = 1;
                } else {
                    if (_distToObjective <= _localReserveMeters) then {
                        _band = 2;
                    } else {
                        if (_distToObjective <= _maxPullDistanceMeters) then {
                            _band = 3;
                        } else {
                            continue;
                        };
                    };
                };
            };

            if (_band < _bestBand || {_band == _bestBand && {_distToObjective < _bestDist}}) then {
                _bestGroupId = _groupId;
                _bestBand = _band;
                _bestDist = _distToObjective;
            };
        } forEach _pool;

        if (_bestGroupId == "") then { continue };

        if (_cmdr call ["_orderGroupDefend", [_bestGroupId, _objectivePos, _objectiveId]]) then {
            _pool = _pool - [_bestGroupId];
            _x set ["deficit", _deficit - 1];
            _metrics set ["assignedGroups", (_metrics get "assignedGroups") + 1];
            _continueAllocation = true;

            private _assignedHere = _assignedByObjective getOrDefault [_objectiveId, 0];
            if (_assignedHere == 0) then {
                if ((_x get "activeDefenders") > 0) then {
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
    "Track %1 frontline defense allocation: assigned=%2 opened=%3 reinforced=%4 candidates=%5 remaining=%6",
    _track get "id",
    _metrics get "assignedGroups",
    _metrics get "openedObjectives",
    _metrics get "reinforcedObjectives",
    _metrics get "candidateObjectives",
    _metrics get "remainingPool"
]] call FLO_fnc_log;

_metrics
