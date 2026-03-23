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
    ["assignedGroups", 0],
    ["openedObjectives", 0],
    ["reinforcedObjectives", 0]
];

if (isNil "_cmdr") exitWith { _metrics };

private _ws = _cmdr get "_worldState";
private _objectives = _ws call ["_getObjectives", []];
if ((count _objectives) == 0) exitWith { _metrics };

private _groups = FLO_virtualGroups get "_groups";
private _ownSide = _cmdr get "_ownSide";
private _reserveGraphDepth = ((_cmdr get "_config") get "defenseReserveGraphDepth");
private _fallbackBand = _reserveGraphDepth + 1;

private _garrisonGroupsByObjective = createHashMap;
private _releaseIds = [];

{
    private _groupId = _x;
    private _gData = _y;
    if ((_gData get "side") != _ownSide) then { continue };
    if ((_gData get "groupType") == "static_aa") then { continue };
    if ((_gData get "commanderOrder") != "GARRISON") then { continue };

    _metrics set ["existingGarrisons", (_metrics get "existingGarrisons") + 1];

    private _objectiveId = _gData get "garrisonObjective";
    if (_objectiveId == "" || {!(_objectiveId in _objectives)}) then {
        _releaseIds pushBackUnique _groupId;
        continue;
    };

    private _objective = _objectives get _objectiveId;
    if ((_objective get "owner") != _ownSide) then {
        _releaseIds pushBackUnique _groupId;
        continue;
    };

    private _bucket = if (_objectiveId in _garrisonGroupsByObjective) then {
        _garrisonGroupsByObjective get _objectiveId
    } else {
        []
    };
    _bucket pushBack _groupId;
    _garrisonGroupsByObjective set [_objectiveId, _bucket];
} forEach _groups;

{
    private _objectiveId = _x;
    private _objective = _objectives get _objectiveId;
    private _garrisonIds = _garrisonGroupsByObjective get _objectiveId;
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

if (_cmdr get "_availabilityCacheDirty") then {
    _cmdr call ["_rebuildAvailabilityCache", []];
};

private _available = (_cmdr get "_availabilityCandidates") apply { _x select 0 };
if ((count _available) == 0) exitWith { _metrics };

private _candidateObjectives = [];
{
    private _objectiveId = _x;
    private _objective = _y;
    if ((_objective get "owner") != _ownSide) then { continue };

    private _cap = _cmdr call ["_getGarrisonCapForObjective", [_objectiveId]];
    if (_cap <= 0) then { continue };

    private _assigned = _cmdr call ["_countObjectiveGarrisons", [_objectiveId]];
    private _deficit = (_cap - _assigned) max 0;
    if (_deficit <= 0) then { continue };

    private _enemyLinkedCount = 0;
    {
        private _linkedObjective = _objectives get _x;
        if (isNil "_linkedObjective") then { continue };
        if ((_linkedObjective get "owner") == (_cmdr get "_enemySide")) then {
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
    private _reserveBands = [_cmdr, [_objectiveId], _reserveGraphDepth] call FLO_fnc_gtnBuildObjectiveReserveBands;

    _candidateObjectives pushBack (createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["objectivePos", _objective get "position"],
        ["reserveBands", _reserveBands],
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
            private _band = _fallbackBand;
            if (_homeObjective in _reserveBands) then {
                _band = _reserveBands get _homeObjective;
            };

            private _distToObjective = _groupPos distance2D _objectivePos;
            if (_band < _bestBand || {_band == _bestBand && {_distToObjective < _bestDist}}) then {
                _bestGroupId = _groupId;
                _bestBand = _band;
                _bestDist = _distToObjective;
            };
        } forEach _available;

        if (_bestGroupId == "") then { continue };

        if (_cmdr call ["_orderGroupGarrison", [_bestGroupId, _objectivePos, _objectiveId]]) then {
            _available = _available - [_bestGroupId];
            _x set ["deficit", _deficit - 1];
            _metrics set ["assignedGroups", (_metrics get "assignedGroups") + 1];
            _continueAllocation = true;

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
            _available = _available - [_bestGroupId];
        };
    } forEach _candidateObjectives;
};

["GTN", 3, format [
    "Baseline garrison allocation: released=%1 assigned=%2 opened=%3 reinforced=%4 candidates=%5",
    _metrics get "releasedGroups",
    _metrics get "assignedGroups",
    _metrics get "openedObjectives",
    _metrics get "reinforcedObjectives",
    _metrics get "candidateObjectives"
]] call FLO_fnc_log;

_metrics
