/*
 * Function: FLO_fnc_civilianMergeObjectiveMemory
 * Author: Frontline Operations Development Group
 * Description:
 *   Merges one civilian memory record into the objective memory ledger while
 *   pruning expired entries and refreshing nearby duplicates.
 *
 * Arguments:
 * 0: Objective memory ledger <HASHMAP>
 * 1: Memory record <HASHMAP>
 * 2: Current time tick <NUMBER>
 *
 * Return Value:
 * HASHMAP - The merged memory record
 */

params [
    ["_ledger", createHashMap, [createHashMap]],
    ["_memory", createHashMap, [createHashMap]],
    ["_nowTick", diag_tickTime, [0]]
];

private _objectiveId = _memory get "objectiveId";
if (_objectiveId == "") exitWith { createHashMap };

private _records = if (_objectiveId in _ledger) then { +(_ledger get _objectiveId) } else { [] };
private _activeRecords = [];
{
    if ((_x get "expiresAt") > _nowTick) then {
        _activeRecords pushBack _x;
    };
} forEach _records;
_records = _activeRecords;

private _memoryPos = _memory get "position";
private _memoryType = _memory get "reportType";
private _memorySourceObjective = _memory get "sourceObjectiveId";
private _matchIndex = -1;

for "_i" from 0 to ((count _records) - 1) do {
    private _record = _records select _i;
    if (
        (_record get "reportType") == _memoryType
        && {(_record get "sourceObjectiveId") == _memorySourceObjective}
        && {((_record get "position") distance2D _memoryPos) < 160}
    ) exitWith {
        _matchIndex = _i;
    };
};

private _mergedMemory = _memory;
if (_matchIndex >= 0) then {
    _mergedMemory = _records select _matchIndex;
    _mergedMemory set ["position", _memoryPos];
    _mergedMemory set ["confidence", ((_mergedMemory get "confidence") max (_memory get "confidence")) min 0.95];
    _mergedMemory set ["gossipDepth", (_mergedMemory get "gossipDepth") min (_memory get "gossipDepth")];
    _mergedMemory set ["previousObjectiveId", _memory get "previousObjectiveId"];
    _mergedMemory set ["firstSeenAt", (_mergedMemory get "firstSeenAt") min (_memory get "firstSeenAt")];
    _mergedMemory set ["lastUpdatedAt", _nowTick];
    _mergedMemory set ["expiresAt", (_mergedMemory get "expiresAt") max (_memory get "expiresAt")];
    _mergedMemory set ["lastSpreadAt", (_mergedMemory get "lastSpreadAt") min (_memory get "lastSpreadAt")];
    _mergedMemory set ["summary", _memory get "summary"];
} else {
    _records pushBack _memory;
};

private _maxMemories = FLO_CivilianConfig get "MEMORY_MAX_PER_OBJECTIVE";
if ((count _records) > _maxMemories) then {
    _records = [_records, [], {
        (_x get "confidence") + (((_x get "expiresAt") - _nowTick) / (FLO_CivilianConfig get "MEMORY_RETENTION_SECONDS"))
    }, "DESCEND"] call BIS_fnc_sortBy;
    _records resize _maxMemories;
};

_ledger set [_objectiveId, _records];
_mergedMemory
