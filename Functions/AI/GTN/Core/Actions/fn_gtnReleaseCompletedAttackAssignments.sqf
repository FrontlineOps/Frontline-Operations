/*
 * Function: FLO_fnc_gtnReleaseCompletedAttackAssignments
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Release attack-tasked groups once their assigned objective is no longer enemy-held.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 *
 * Return Value:
 * Metrics <HASHMAP>
 */

params [
    ["_cmdr", nil]
];

private _metrics = createHashMapFromArray [
    ["taskedCount", 0],
    ["releasedCount", 0]
];

if (isNil "_cmdr") exitWith { _metrics };

private _tasked = +(_cmdr get "_gtnTaskedGroups");
_metrics set ["taskedCount", count _tasked];
if ((count _tasked) == 0) exitWith { _metrics };

private _groups = FLO_virtualGroups get "_groups";
private _ws = _cmdr get "_worldState";
private _enemySide = _cmdr get "_enemySide";
private _objectives = _ws call ["_getObjectives", []];
private _releaseIds = [];

{
    private _groupId = _x;
    private _gData = _groups get _groupId;
    if (isNil "_gData") then { continue };
    if ((_gData get "commanderOrder") != "ATTACK") then { continue };

    private _objectiveId = _gData get "attackObjective";
    if (_objectiveId == "") then {
        _releaseIds pushBackUnique _groupId;
        continue;
    };

    if !(_objectiveId in _objectives) then {
        _releaseIds pushBackUnique _groupId;
        continue;
    };

    private _objective = _objectives get _objectiveId;
    if ((_objective get "owner") != _enemySide) then {
        _releaseIds pushBackUnique _groupId;
    };
} forEach _tasked;

if ((count _releaseIds) == 0) exitWith { _metrics };

{
    private _gData = _groups get _x;
    if (isNil "_gData") then { continue };
    [_gData] call FLO_fnc_virtualizationClearMissionLock;
} forEach _releaseIds;

_cmdr call ["_releaseGroups", [_releaseIds, ""]];
_metrics set ["releasedCount", count _releaseIds];

["GTN", 3, format["Attack assignment release: %1 groups returned to pool", count _releaseIds]] call FLO_fnc_log;

_metrics
