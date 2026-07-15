/* Configures the persisted assault ledger. */
params [
    ["_operation", createHashMap, [createHashMap]],
    ["_config", createHashMap, [createHashMap]],
    ["_coverageScale", 0, [0]]
];

private _role = _operation get "priorityRole";
private _isMainEffort = _role == "MAIN_EFFORT";
private _packageMinimum = _config get (["supportAssaultPackageMinimum", "mainAssaultPackageMinimum"] select _isMainEffort);
private _packageMaximum = _config get (["supportAssaultPackageMaximum", "mainAssaultPackageMaximum"] select _isMainEffort);
private _activeTarget = _config get (["supportAssaultActiveTarget", "mainAssaultActiveTarget"] select _isMainEffort);
private _waveSize = _config get (["supportAssaultWaveSize", "mainAssaultWaveSize"] select _isMainEffort);

private _boundedCoverage = (_coverageScale max 0) min 1;
private _packageTarget = round (_packageMinimum + ((_packageMaximum - _packageMinimum) * _boundedCoverage));
switch (_operation get "doctrine") do {
    case "BREAKTHROUGH": {
        _packageTarget = (_packageTarget + 2) min (_packageMaximum + 2);
        _activeTarget = _activeTarget + 2;
        _waveSize = _waveSize + 1;
    };
    case "COUNTERATTACK": {
        _activeTarget = _activeTarget + 1;
    };
    case "ECONOMY_OF_FORCE": {
        private _minimumOpening = [5, 8] select _isMainEffort;
        _packageTarget = _packageMinimum;
        _activeTarget = _activeTarget min _minimumOpening;
        _waveSize = _waveSize min 4;
    };
};

private _now = call FLO_fnc_operationalDateNumber;
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
