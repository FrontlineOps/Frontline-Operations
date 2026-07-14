/* Records only successfully committed ATTACK orders against the package. */
params [
    "_director",
    ["_operationId", "", [""]],
    ["_committedCount", 0, [0]],
    ["_openingComplete", true, [true]]
];

if (_committedCount <= 0) exitWith { false };
private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
if ((_operation get "phase") != "ASSAULT") then {
    throw format ["Cannot commit ASSAULT wave to %1 in phase %2", _operationId, _operation get "phase"];
};

private _nextCommitted = (_operation get "assaultCommittedTotal") + _committedCount;
private _packageTarget = _operation get "assaultPackageTarget";
if (_nextCommitted > _packageTarget) then {
    throw format ["Operation %1 wave exceeds package: %2 > %3", _operationId, _nextCommitted, _packageTarget];
};

private _now = call FLO_fnc_operationalDateNumber;
private _config = _director get "_config";
private _waveSequence = _operation get "assaultWaveSequence";
_operation set ["assaultCommittedTotal", _nextCommitted];
if (_waveSequence == 0 && {!_openingComplete}) then {
    _operation set ["assaultNextWaveAtDateNum", _now];
    _operation set ["assaultStatus", "OPENING_COMMIT"];
} else {
    _operation set ["assaultWaveSequence", _waveSequence + 1];
    _operation set [
        "assaultNextWaveAtDateNum",
        [_now, _config get "assaultWaveCooldownSeconds"] call FLO_fnc_dateNumberAddSeconds
    ];
    _operation set ["assaultStatus", "ADVANCING"];
};
[_operation] call FLO_fnc_campaignValidateAssaultState;

private _state = _director get "_state";
_state set ["revision", (_state get "revision") + 1];
[_state] call FLO_fnc_campaignSyncPrimaryProjection;
["FLO_Campaign_OperationChanged", [_state get "revision", _operationId, "ASSAULT"]] call CBA_fnc_localEvent;
true
