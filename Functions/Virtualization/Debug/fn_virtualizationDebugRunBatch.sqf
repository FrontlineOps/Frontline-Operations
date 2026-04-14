/*
 * Function: FLO_fnc_virtualizationDebugRunBatch
 */

params ["_args", "_pfhId"];

if !(FLO_VirtDebug get "enabled") exitWith {};

private _now = diag_tickTime;
private _lastUpdate = FLO_VirtDebug get "lastUpdateTime";
private _interval = FLO_VirtDebug get "updateInterval";

if (_now - _lastUpdate < _interval) exitWith {};

FLO_VirtDebug set ["lastUpdateTime", _now];

private _groups = FLO_virtualGroups get "_groups";
private _groupIds = keys _groups;
private _totalGroups = count _groupIds;
if (_totalGroups == 0) exitWith {};

private _batchSize = FLO_VirtDebug get "batchSize";
private _startIdx = FLO_VirtDebug get "currentBatchIndex";

for "_i" from _startIdx to ((_startIdx + _batchSize - 1) min (_totalGroups - 1)) do {
    private _groupId = _groupIds select _i;
    private _groupData = _groups get _groupId;
    [_groupId, _groupData] call FLO_fnc_virtualizationDebugUpdateMarker;
};

private _nextIdx = _startIdx + _batchSize;
if (_nextIdx >= _totalGroups) then {
    FLO_VirtDebug set ["currentBatchIndex", 0];
} else {
    FLO_VirtDebug set ["currentBatchIndex", _nextIdx];
};
