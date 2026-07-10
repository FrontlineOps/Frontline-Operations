/*
 * Function: FLO_fnc_gtnReleaseCompletedAttackAssignments
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Retains only ATTACK orders owned by the current theater operation while
 *   its attacker is in ASSAULT. Legacy, expired, and mismatched orders are
 *   returned to the commander's available pool.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 *
 * Return Value:
 * Metrics <HASHMAP>
 */

params ["_cmdr"];

private _metrics = createHashMapFromArray [
    ["taskedCount", 0],
    ["releasedCount", 0]
];

private _attackGroupIds = +((_cmdr get "_objectiveAssignmentCache") get "attackGroupIds");
_metrics set ["taskedCount", count _attackGroupIds];
if (_attackGroupIds isEqualTo []) exitWith { _metrics };

private _director = _cmdr get "_campaignDirector";
if (isNil "_director") then {
    throw "FLO_fnc_gtnReleaseCompletedAttackAssignments: commander has no campaign director";
};

private _state = _director call ["_getState", []];
private _operationId = _state get "operationId";
private _objectiveId = _state get "objectiveId";
private _commanderOwnsAssault = (_state get "phase") == "ASSAULT"
    && {(_state get "attackerSideKey") == (_cmdr get "_sideKey")}
    && {_operationId != ""}
    && {_objectiveId != ""};

private _groups = FLO_virtualGroups get "_groups";
private _objectives = (_cmdr get "_worldState") call ["_getObjectives", []];
private _enemySide = _cmdr get "_enemySide";
private _releaseIds = [];

{
    private _groupId = _x;
    private _gData = _groups get _groupId;
    if (isNil "_gData") then { continue };
    if ((_gData get "commanderOrder") != "ATTACK") then { continue };

    private _retain = _commanderOwnsAssault
        && {(_gData get "campaignOperationId") == _operationId}
        && {(_gData get "attackObjective") == _objectiveId}
        && {_objectiveId in _objectives}
        && {((_objectives get _objectiveId) get "owner") == _enemySide};

    if (!_retain) then {
        _releaseIds pushBack _groupId;
    };
} forEach _attackGroupIds;

{
    private _gData = _groups get _x;
    [_x, [], false, true, "GTN_OPERATION_RELEASE"] call FLO_fnc_updateVirtualGroupWaypoints;
    [_gData] call FLO_fnc_virtualizationClearMissionLock;
} forEach _releaseIds;

if (_releaseIds isNotEqualTo []) then {
    _cmdr call ["_releaseGroups", [_releaseIds, ""]];
    _metrics set ["releasedCount", count _releaseIds];
    ["GTN", 3, format ["Released %1 expired operation attack assignments", count _releaseIds]] call FLO_fnc_log;
};

_metrics
