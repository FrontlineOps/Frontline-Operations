/* Owns the server's single restartable periodic campaign-save worker. */
if (!isServer) exitWith { false };

private _intervalMinutes = FLO_AutosaveIntervalMinutes;
if !(_intervalMinutes in [0, 5, 10, 15, 30, 60]) then {
    private _error = format ["Automatic save interval %1 minutes is unsupported", _intervalMinutes];
    ["SAVE", 1, _error] call FLO_fnc_log;
    throw _error;
};

if (FLO_AutosavePFH >= 0) then {
    [FLO_AutosavePFH] call CBA_fnc_removePerFrameHandler;
    FLO_AutosavePFH = -1;
};

if (_intervalMinutes == 0) exitWith {
    ["SAVE", 3, "Automatic campaign saving disabled"] call FLO_fnc_log;
    true
};

FLO_AutosavePFH = [{
    if (!FLO_MissionReady || {FLO_MissionSaveInProgress}) exitWith {};
    [] spawn FLO_fnc_MissionSave;
}, _intervalMinutes * 60, []] call CBA_fnc_addPerFrameHandler;

["SAVE", 3, format [
    "Automatic campaign saving scheduled every %1 minutes handler=%2",
    _intervalMinutes,
    FLO_AutosavePFH
]] call FLO_fnc_log;

true
