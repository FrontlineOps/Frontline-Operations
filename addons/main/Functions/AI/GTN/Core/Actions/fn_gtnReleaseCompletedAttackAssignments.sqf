/*
 * Function: FLO_fnc_gtnReleaseCompletedAttackAssignments
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Retains ATTACK orders owned by an active formal operation or canonical
 *   persistent probe front. Expired and mismatched orders return to reserve.
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
private _operations = _state get "operations";
private _fronts = _state get "frontlineProbes";

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _objectives = (_cmdr get "_worldState") call ["_getObjectives", []];
private _enemySide = _cmdr get "_enemySide";
private _releaseIds = [];

{
    private _groupId = _x;
    private _gData = _groups get _groupId;
    if (isNil "_gData") then { continue };
    if ((_gData get "commanderOrder") != "ATTACK") then { continue };

    private _operationId = _gData get "campaignOperationId";
    private _objectiveId = _gData get "attackObjective";
    private _retain = false;
    if (_operationId in _operations) then {
        private _operation = _operations get _operationId;
        _retain = (_operation get "phase") == "ASSAULT"
            && {(_operation get "attackerSideKey") == (_cmdr get "_sideKey")}
            && {(_operation get "objectiveId") == _objectiveId}
            && {_objectiveId in _objectives}
            && {((_objectives get _objectiveId) get "owner") == _enemySide};
    } else {
        if (_operationId in _fronts) then {
            private _front = _fronts get _operationId;
            _retain = (_front get "formalOperationId") == ""
                && {(_front get "sideKey") == (_cmdr get "_sideKey")}
                && {(_front get "objectiveId") == _objectiveId}
                && {_groupId in (_front get "committedGroupIds")}
                && {(_front get "stage") != "REGROUP"}
                && {_objectiveId in _objectives}
                && {((_objectives get _objectiveId) get "owner") == _enemySide};
        };
    };

    if (!_retain) then {
        _releaseIds pushBack _groupId;
    };
} forEach _attackGroupIds;

{
    private _gData = _groups get _x;
    [_x, [], true, "GTN_OPERATION_RELEASE"] call FLO_fnc_updateVirtualGroupWaypoints;
    [_gData] call FLO_fnc_virtualizationClearMissionLock;
} forEach _releaseIds;

if (_releaseIds isNotEqualTo []) then {
    _cmdr call ["_releaseGroups", [_releaseIds, ""]];
    _metrics set ["releasedCount", count _releaseIds];
    ["GTN", 3, format ["Released %1 expired operation attack assignments", count _releaseIds]] call FLO_fnc_log;
};

_metrics
