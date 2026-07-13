/* Initializes a persisted role/coverage-specific ASSAULT package. */
params ["_director", ["_operationId", "", [""]]];

private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
private _config = _director get "_config";
private _role = _operation get "priorityRole";
private _attackerSide = [_operation get "attackerSideKey"] call FLO_fnc_campaignSideFromKey;
private _coverage = ([_attackerSide, "attackCoverage"] call FLO_fnc_gtnGetSideCommanderHandle) get "value";
private _coverageScale = (((_coverage - 0.5) / 0.75) max 0) min 1;

private _packageMinimum = _config get "supportAssaultPackageMinimum";
private _packageMaximum = _config get "supportAssaultPackageMaximum";
private _activeTarget = _config get "supportAssaultActiveTarget";
private _waveSize = _config get "supportAssaultWaveSize";
if (_role == "MAIN_EFFORT") then {
    _packageMinimum = _config get "mainAssaultPackageMinimum";
    _packageMaximum = _config get "mainAssaultPackageMaximum";
    _activeTarget = _config get "mainAssaultActiveTarget";
    _waveSize = _config get "mainAssaultWaveSize";
};

private _packageTarget = round (_packageMinimum + ((_packageMaximum - _packageMinimum) * _coverageScale));
private _doctrine = _operation get "doctrine";
switch (_doctrine) do {
    case "BREAKTHROUGH": {
        _packageTarget = (_packageTarget + 2) min (_packageMaximum + 2);
        _activeTarget = _activeTarget + 2;
        _waveSize = _waveSize + 1;
    };
    case "COUNTERATTACK": {
        _activeTarget = _activeTarget + 1;
    };
    case "ECONOMY_OF_FORCE": {
        private _minimumOpening = [5, 8] select (_role == "MAIN_EFFORT");
        _packageTarget = _packageMinimum;
        _activeTarget = _activeTarget min _minimumOpening;
        _waveSize = _waveSize min 4;
    };
};
private _now = dateToNumber date;
_operation set ["assaultPackageTarget", _packageTarget];
_operation set ["assaultActiveTarget", _activeTarget];
_operation set ["assaultWaveSize", _waveSize];
_operation set ["assaultCommittedTotal", 0];
_operation set ["assaultLosses", 0];
_operation set ["assaultWaveSequence", 0];
_operation set ["assaultNextWaveAtDateNum", _now];
_operation set ["assaultPauseUntilDateNum", -1];
_operation set ["assaultLastProgressAtDateNum", _now];
_operation set ["assaultBestDistance", 1e12];
_operation set ["assaultLastEnemyCount", -1];
_operation set ["assaultLastArrivedCount", 0];
_operation set ["assaultPauseCount", 0];
_operation set ["assaultLastContested", false];
_operation set ["assaultStatus", "READY"];
_operation set ["assaultOpeningEligibleAtDateNum", _now];

[_operation] call FLO_fnc_campaignValidateAssaultState;
[_operation] call FLO_fnc_campaignValidateOperationalState;
_operation
