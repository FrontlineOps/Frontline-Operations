/*
 * Function: FLO_fnc_initRunPhase
 * Author: Frontline Operations Development Group
 * Description:
 *   Runs one initialization phase with shared logging and error handling.
 *
 * Arguments:
 * 0: Phase number <NUMBER>
 * 1: Phase name <STRING>
 * 2: Phase function <CODE>
 *
 * Returns:
 * Success <BOOL>
 */
params ["_phaseNum", "_phaseName", "_phaseFunc"];

FLO_InitPhase = _phaseNum;
publicVariable "FLO_InitPhase";

diag_log format ["[FLO_INIT] === PHASE %1: %2 ===", _phaseNum, _phaseName];

private _startTime = diag_tickTime;
private _success = false;

try {
    _success = [] call _phaseFunc;
} catch {
    FLO_InitError = format ["Phase %1 (%2) exception: %3", _phaseNum, _phaseName, _exception];
    diag_log format ["[FLO_INIT] ERROR: %1", FLO_InitError];
    publicVariable "FLO_InitError";
    _success = false;
};

private _duration = diag_tickTime - _startTime;

if (_success) then {
    diag_log format ["[FLO_INIT] Phase %1 completed in %2 seconds", _phaseNum, _duration toFixed 2];
} else {
    if (FLO_InitError isEqualTo "") then {
        FLO_InitError = format ["Phase %1 (%2) returned false", _phaseNum, _phaseName];
        publicVariable "FLO_InitError";
    };
    diag_log format ["[FLO_INIT] Phase %1 FAILED after %2 seconds: %3", _phaseNum, _duration toFixed 2, FLO_InitError];
};

_success
