/* Replaces an existing ATTACK route without consuming a new assignment slot. */
params [
    "_cmdr",
    ["_groupId", "", [""]],
    ["_approachRoute", [], [[]]],
    ["_objectiveId", "", [""]],
    ["_campaignOperationId", "", [""]]
];

if (_groupId == "" || {_objectiveId == ""} || {_campaignOperationId == ""}) then {
    throw "GTN attack retask requires group, objective, and campaign ownership";
};
if ((count _approachRoute) != 2) then {
    throw format ["GTN attack retask requires a two-point route for %1", _groupId];
};
_approachRoute params ["_entryPos", "_attackPos"];
if (count _entryPos < 2 || {count _attackPos < 2}) then {
    throw format ["GTN attack retask received an invalid route for %1: %2", _groupId, _approachRoute];
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
if !(_groupId in _groups) then {
    throw format ["GTN attack retask references missing group %1", _groupId];
};
private _groupData = _groups get _groupId;
if (
    (_groupData get "commanderOrder") != "ATTACK"
    || {(_groupData get "attackObjective") != _objectiveId}
    || {(_groupData get "campaignOperationId") != _campaignOperationId}
) then {
    throw format ["GTN attack retask ownership mismatch for %1", _groupId];
};

private _waypoints = [
    [_entryPos, "MOVE", "AWARE", "FULL", "STAG COLUMN", "YELLOW", 75],
    [_attackPos, "MOVE", "AWARE", "FULL", "STAG COLUMN", "YELLOW", 50]
];
private _result = [
    _groupId,
    _groupData,
    "ATTACK",
    _waypoints,
    _attackPos,
    "GTN_ATTACK",
    _objectiveId,
    "",
    -1,
    -1,
    _campaignOperationId
] call FLO_fnc_virtualizationCommitCommanderOrder;
_result params ["_success", "_routeMs", "_assignMs", "_transportMs", "_orderMs"];
if (!_success) exitWith { false };

[_cmdr, "ATTACK_RETASK", _groupId, _groupData get "groupType", _objectiveId, _routeMs, _assignMs, _transportMs, _orderMs]
    call FLO_fnc_gtnLogStrategicOrderPerf;
_cmdr call ["_taskGroups", [[_groupId]]];
true
