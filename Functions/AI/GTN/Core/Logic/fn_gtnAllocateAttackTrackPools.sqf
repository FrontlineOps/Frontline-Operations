/*
 * Function: FLO_fnc_gtnAllocateAttackTrackPools
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Distribute attack-capable reserve groups across attack tracks in two passes.
 * First seed as many viable sectors as possible with a meaningful staging
 * package. Then distribute remaining groups by reserve-band locality and track
 * anchor distance.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Attack Tracks <ARRAY>
 * 2: Candidate Group IDs <ARRAY>
 * 3: Track Reserve Bands <HASHMAP>
 * 4: Group Map <HASHMAP>
 *
 * Return Value:
 * Metrics <HASHMAP>
 */

params [
    ["_cmdr", nil],
    ["_attackTracks", [], [[]]],
    ["_candidateGroupIds", [], [[]]],
    ["_trackReserveBands", createHashMap, [createHashMap]],
    ["_groups", createHashMap, [createHashMap]]
];

private _metrics = createHashMapFromArray [
    ["candidateCount", count _candidateGroupIds],
    ["assignedCount", 0],
    ["viableTrackCount", 0],
    ["meaningfulTrackCount", 0],
    ["seededTrackCount", 0],
    ["stagedTrackCount", 0],
    ["stagingFloor", 0],
    ["remainingCount", count _candidateGroupIds]
];

if (isNil "_cmdr" || {(count _attackTracks) == 0} || {(count _candidateGroupIds) == 0}) exitWith { _metrics };

private _config = _cmdr get "_config";
private _reserveGraphDepth = _config get "attackReserveGraphDepth";
private _fallbackAttackBand = _reserveGraphDepth + 1;
private _stagingFloor = ((_config get "attackLaneStagingMinGroups") max 1);
_metrics set ["stagingFloor", _stagingFloor];

private _ws = _cmdr get "_worldState";
private _frontlineObjectives = _cmdr call ["_getAttackFrontlineEnemyObjectives", []];
if ((count (keys _frontlineObjectives)) == 0) then {
    _frontlineObjectives = _ws call ["_getEnemyObjectives", []];
};
if ((count (keys _frontlineObjectives)) == 0) exitWith { _metrics };

private _rankedViableTracks = [];
{
    private _track = _x;
    private _sectorObjectives = _track get "frontSectorObjectives";
    if ((count _sectorObjectives) == 0) then { continue };

    private _phaseObjectiveId = _track get "phaseObjectiveId";
    private _sectorScore = 0;
    private _viableObjectiveCount = 0;

    {
        private _objectiveId = _x;
        private _sourceObjectives = _cmdr call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
        if ((count (_sourceObjectives arrayIntersect _sectorObjectives)) == 0) then { continue };

        private _attackCap = _cmdr call ["_getAttackCapForObjective", [_objectiveId]];
        if (_attackCap <= 0) then { continue };

        private _objective = _frontlineObjectives get _objectiveId;
        private _pressure = ((_objective get "enemyCount") - (_objective get "friendlyCount")) max 0;
        private _objectiveScore = (_objective get "priority")
            + (_pressure * 4)
            + ((_attackCap min 12) * 2)
            + (if (_objective get "contested") then { 25 } else { 0 })
            + (if (_objective get "underAttack") then { 15 } else { 0 });

        if (_objectiveId == _phaseObjectiveId) then {
            _objectiveScore = _objectiveScore + 50;
        };

        _sectorScore = _sectorScore + _objectiveScore;
        _viableObjectiveCount = _viableObjectiveCount + 1;
    } forEach (keys _frontlineObjectives);

    if (_viableObjectiveCount <= 0) then { continue };

    _rankedViableTracks pushBack [
        -_sectorScore,
        -(count _sectorObjectives),
        _track get "id",
        _track
    ];
} forEach _attackTracks;

_rankedViableTracks sort true;
private _viableTracks = _rankedViableTracks apply { _x select 3 };
_metrics set ["viableTrackCount", count _viableTracks];
if ((count _viableTracks) == 0) exitWith { _metrics };

private _meaningfulTrackCount = floor ((count _candidateGroupIds) / _stagingFloor);
if (_meaningfulTrackCount <= 0 && {(count _candidateGroupIds) > 0}) then {
    _meaningfulTrackCount = 1;
};
_meaningfulTrackCount = _meaningfulTrackCount min (count _viableTracks);
_metrics set ["meaningfulTrackCount", _meaningfulTrackCount];

private _seedTracks = [];
for "_i" from 0 to (_meaningfulTrackCount - 1) do {
    _seedTracks pushBack (_viableTracks select _i);
}
_metrics set ["seededTrackCount", count _seedTracks];

private _remainingGroups = +_candidateGroupIds;

if ((count _seedTracks) > 0) then {
    while {(count _remainingGroups) > 0} do {
        private _assignedThisPass = false;
        private _allTracksFilled = true;

        {
            private _track = _x;
            if ((count (_track get "groupPool")) >= _stagingFloor) then { continue };
            _allTracksFilled = false;

            private _trackId = _track get "id";
            private _reserveBands = _trackReserveBands get _trackId;
            private _selection = [_track, _remainingGroups, _groups, _reserveBands, _fallbackAttackBand] call FLO_fnc_gtnSelectBestReserveGroupForTrack;
            private _bestGroupId = _selection select 0;
            if (_bestGroupId == "") then { continue };

            private _pool = _track get "groupPool";
            _pool pushBack _bestGroupId;
            _track set ["groupPool", _pool];
            _remainingGroups = _remainingGroups - [_bestGroupId];
            _metrics set ["assignedCount", (_metrics get "assignedCount") + 1];
            _assignedThisPass = true;
        } forEach _seedTracks;

        if (_allTracksFilled || {!_assignedThisPass}) exitWith {};
    };
};

private _stagedTrackCount = 0;
{
    if ((count (_x get "groupPool")) >= _stagingFloor) then {
        _stagedTrackCount = _stagedTrackCount + 1;
    };
} forEach _seedTracks;
_metrics set ["stagedTrackCount", _stagedTrackCount];

private _postSeedRemaining = +_remainingGroups;
_remainingGroups = [];

{
    private _groupId = _x;
    private _gData = _groups get _groupId;
    if (isNil "_gData") then { continue };

    private _homeObjective = _gData get "homeObjective";
    private _groupPos = _gData get "position";
    private _assignedTrack = nil;
    private _bestBand = 1e12;
    private _bestDist = 1e12;
    private _bestPool = 1000000;

    {
        private _track = _x;
        private _trackId = _track get "id";
        private _reserveBands = _trackReserveBands get _trackId;
        private _anchorPos = _track get "frontSectorAnchorPos";
        private _band = _fallbackAttackBand;
        if (_homeObjective != "" && {_homeObjective in _reserveBands}) then {
            _band = _reserveBands get _homeObjective;
        };

        private _dist = if ((count _anchorPos) >= 2) then {
            _groupPos distance2D _anchorPos
        } else {
            1e12
        };
        private _poolSize = count (_track get "groupPool");

        if (
            isNil "_assignedTrack"
            || { _band < _bestBand }
            || { _band == _bestBand && { _dist < _bestDist } }
            || { _band == _bestBand && { _dist == _bestDist && { _poolSize < _bestPool } } }
        ) then {
            _assignedTrack = _track;
            _bestBand = _band;
            _bestDist = _dist;
            _bestPool = _poolSize;
        };
    } forEach _attackTracks;

    if (isNil "_assignedTrack") then {
        _remainingGroups pushBack _groupId;
        continue;
    };

    private _pool = _assignedTrack get "groupPool";
    _pool pushBack _groupId;
    _assignedTrack set ["groupPool", _pool];
    _metrics set ["assignedCount", (_metrics get "assignedCount") + 1];
} forEach _postSeedRemaining;

_metrics set ["remainingCount", count _remainingGroups];

["GTN", 3, format [
    "Attack track pool allocation: candidates=%1 viable=%2 meaningful=%3 seeded=%4 staged=%5 assigned=%6 remaining=%7 floor=%8",
    _metrics get "candidateCount",
    _metrics get "viableTrackCount",
    _metrics get "meaningfulTrackCount",
    _metrics get "seededTrackCount",
    _metrics get "stagedTrackCount",
    _metrics get "assignedCount",
    _metrics get "remainingCount",
    _metrics get "stagingFloor"
]] call FLO_fnc_log;

_metrics
