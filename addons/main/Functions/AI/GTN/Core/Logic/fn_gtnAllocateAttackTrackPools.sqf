/*
 * Function: FLO_fnc_gtnAllocateAttackTrackPools
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Assign the full offensive reserve pool to the single shared attack track.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Attack Tracks <ARRAY>
 * 2: Candidate Group IDs <ARRAY>
 *
 * Return Value:
 * Metrics <HASHMAP>
 */

params [
    ["_cmdr", nil],
    ["_attackTracks", [], [[]]],
    ["_candidateGroupIds", [], [[]]]
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

if (isNil "_cmdr" || {_attackTracks isEqualTo []} || {_candidateGroupIds isEqualTo []}) exitWith { _metrics };

private _config = _cmdr get "_config";
private _stagingFloor = ((_config get "attackLaneStagingMinGroups") max 1);
_metrics set ["stagingFloor", _stagingFloor];

private _frontlineObjectives = _cmdr call ["_getAttackFrontlineEnemyObjectives", []];
if ((keys _frontlineObjectives) isEqualTo []) exitWith { _metrics };

private _track = _attackTracks select 0;
_track set ["groupPool", +_candidateGroupIds];

_metrics set ["viableTrackCount", 1];
_metrics set ["meaningfulTrackCount", 1];
_metrics set ["seededTrackCount", 1];
_metrics set ["stagedTrackCount", parseNumber ((count _candidateGroupIds) >= _stagingFloor)];
_metrics set ["assignedCount", count _candidateGroupIds];
_metrics set ["remainingCount", 0];

["GTN", 3, format [
    "Attack pool allocation (shared track): candidates=%1 assigned=%2 floor=%3",
    _metrics get "candidateCount",
    _metrics get "assignedCount",
    _metrics get "stagingFloor"
]] call FLO_fnc_log;

_metrics
