/* Publish one save outcome; a rejected transaction never advances last success. */
params ["_saved", ["_reason", "", [""]]];
if (!isServer || {remoteExecutedOwner > 2}) exitWith { false };
FLO_MissionSaveInProgress = false;
private _duration = (diag_tickTime - (FLO_SaveStatus get "lastAttemptAt")) max 0;
FLO_SaveStatus set ["duration", _duration];
FLO_SaveStatus set ["phase", ["FAILED", "SAVED"] select _saved];
if (_saved) then {
    FLO_SaveStatus set ["lastSuccessAt", diag_tickTime];
    FLO_SaveStatus set ["failures", 0];
    ["SAVE", 3, format ["Campaign save committed duration=%1s", _duration]] call FLO_fnc_log;
    if (FLO_SaveRequester >= 0) then {
        ["Campaign progress saved.", "success", false, FLO_SaveRequester] call FLO_fnc_sendNotification;
    };
} else {
    FLO_SaveStatus set ["failures", (FLO_SaveStatus get "failures") + 1];
    ["SAVE", 1, format ["Campaign save failed duration=%1s reason=%2", _duration, _reason]] call FLO_fnc_log;
    private _message = "Campaign save failed. The last complete save remains available. Check the server RPT.";
    if (FLO_AutosaveIntervalMinutes > 0) then {
        _message = _message + " Autosave will try again at the next interval.";
    };
    [_message, "error", false, 0] call FLO_fnc_sendNotification;
};
FLO_SaveRequester = -1;
["flo_mission_save_completed", [_saved]] call CBA_fnc_globalEvent;
_saved
