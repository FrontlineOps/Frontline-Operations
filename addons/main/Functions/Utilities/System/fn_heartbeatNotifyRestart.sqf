/*
 * Function: FLO_fnc_heartbeatNotifyRestart
 * Author: Frontline Operations Development Group
 * Description:
 *   Sends the server restart warning notification for one threshold.
 *
 * Arguments:
 * 0: Minutes left <NUMBER>
 *
 * Returns: None
 */
params ["_minutesLeft"];

private _urgency = switch (true) do {
    case (_minutesLeft <= 2):  { 3 };
    case (_minutesLeft <= 5):  { 2 };
    case (_minutesLeft <= 15): { 1 };
    default                    { 0 };
};

private _color = switch (_urgency) do {
    case 3: { "#FF0000" };
    case 2: { "#FF6600" };
    case 1: { "#FFFF00" };
    default { "#FFFFFF" };
};

private _timeStr = [format ["%1 minute%2", _minutesLeft, ["", "s"] select (_minutesLeft != 1)], format ["%1 hour%2", floor(_minutesLeft / 60), ["", "s"] select (_minutesLeft >= 120)]] select (_minutesLeft >= 60);
private _message = format ["SERVER RESTART in %1", _timeStr];

if (_minutesLeft <= 5) then {
    _message = _message + " - Save your progress!";
} else {
    if (_minutesLeft <= 15) then {
        _message = _message + " - Finish current objectives";
    };
};

private _size = 1.0 + (_urgency * 0.15);
private _duration = 5 + (_urgency * 2);
private _formattedText = format ["<t size='%1' color='%2'>%3</t>", _size, _color, _message];

["dynamicTextBroadcasts", 1] call FLO_fnc_netDebugRecord;
[_formattedText, _duration] remoteExec ["FLO_fnc_showDynamicText", 0];

if (_urgency >= 2) then {
    "FD_CP_Not_Clear_F" remoteExec ["playSound", 0];
};

diag_log format ["[FLO_HEARTBEAT] Notification sent: %1 minutes remaining", _minutesLeft];
