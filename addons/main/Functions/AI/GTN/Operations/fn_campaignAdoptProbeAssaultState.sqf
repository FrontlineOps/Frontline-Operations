/* Seeds a formal assault ledger from its already committed probe groups. */
params [
    "_director",
    ["_operationId", "", [""]],
    ["_operationOverride", createHashMap, [createHashMap]],
    ["_frontOverride", createHashMap, [createHashMap]]
];

private _operation = if ((keys _operationOverride) isEqualTo []) then {
    [_director, _operationId] call FLO_fnc_campaignGetOperation
} else {
    _operationOverride
};
if ((_operation get "operationId") != _operationId) then {
    throw format ["Assault adoption operation key/id mismatch %1/%2", _operationId, _operation get "operationId"];
};
if ((_operation get "phase") != "ASSAULT") then {
    throw format ["Operation %1 cannot adopt probe mass in phase %2", _operationId, _operation get "phase"];
};
private _front = if ((keys _frontOverride) isEqualTo []) then {
    private _state = _director get "_state";
    private _probeId = [
        _operation get "attackerSideKey",
        _operation get "objectiveId"
    ] call FLO_fnc_campaignProbeId;
    (_state get "frontlineProbes") get _probeId
} else {
    _frontOverride
};
if (isNil "_front" || {(_front get "formalOperationId") != _operationId}) then {
    throw format ["Operation %1 has no attached probe front to adopt", _operationId];
};
if ((_front get "stage") != "ASSAULT") then {
    throw format ["Operation %1 tried to adopt unready probe stage %2", _operationId, _front get "stage"];
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _activeGroupIds = (_front get "committedGroupIds") select {
    _x in _groups
    && {((_groups get _x) get "unitCount") > 0}
    && {((_groups get _x) get "commanderOrder") == "ATTACK"}
    && {((_groups get _x) get "campaignOperationId") == _operationId}
};
private _activeCount = count _activeGroupIds;
private _minimum = (_director get "_config") get "probeAssaultMinimumGroups";
if (_activeCount < _minimum) then {
    throw format ["Operation %1 probe adoption has %2 groups, requires %3", _operationId, _activeCount, _minimum];
};

private _now = call FLO_fnc_operationalDateNumber;
_operation set ["assaultPackageTarget", (_operation get "assaultPackageTarget") max _activeCount];
_operation set ["assaultActiveTarget", (_operation get "assaultActiveTarget") min _activeCount];
_operation set ["assaultCommittedTotal", _activeCount];
_operation set ["assaultLosses", 0];
_operation set ["assaultWaveSequence", 1];
_operation set [
    "assaultNextWaveAtDateNum",
    [_now, (_director get "_config") get "assaultWaveCooldownSeconds"] call FLO_fnc_dateNumberAddSeconds
];
_operation set ["assaultPauseUntilDateNum", -1];
_operation set ["assaultLastProgressAtDateNum", _now];
_operation set ["assaultBestDistance", _front get "bestDistance"];
_operation set ["assaultLastEnemyCount", _front get "lastEnemyCount"];
_operation set ["assaultLastArrivedCount", _front get "lastArrivedCount"];
_operation set ["assaultPauseCount", 0];
_operation set ["assaultLastContested", _front get "lastContested"];
_operation set ["assaultStatus", "ADVANCING"];
_operation set ["assaultOpeningEligibleAtDateNum", _now];
[_operation] call FLO_fnc_campaignValidateAssaultState;
[_operation] call FLO_fnc_campaignValidateOperationalState;

["CAMPAIGN", 3, format [
    "Operation %1 adopted %2 probe groups into assault opening mass",
    _operationId,
    _activeCount
]] call FLO_fnc_log;
_activeCount
