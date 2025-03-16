/*
 * Function: FLO_fnc_serverRestartTimer
 * Author: Frontline Operations Development Group
 * Description:
 * Tracks and displays server restart time to players.
 * Call this on the server during initialization.
 *
 * Arguments:
 * 0: _restartInterval - Server restart interval in minutes [Number] (default: 240 - 4 hours)
 * 1: _warningTimes - Array of minutes before restart to show notifications [Array] (default: [60,30,15,10,5,3,1])
 *
 * Return Value:
 * None
 *
 * Example:
 * [240, [60,30,15,10,5,3,1]] call FLO_fnc_serverRestartTimer;
 */

if (!isServer) exitWith {};

params [
    ["_restartInterval", 240, [0]],
    ["_warningTimes", [60,30,15,10,5,3,1], [[]]]
];

// Store server start time
if (isNil "FLO_serverStartTime") then {
    FLO_serverStartTime = diag_tickTime;
    publicVariable "FLO_serverStartTime";
    ["MISC", 3, format["Server restart timer initialized. Interval: %1 minutes", _restartInterval]] call FLO_fnc_log;
};

// Create scheduled notifications
private _scheduledNotifications = [];
{
    private _warningTime = _x;
    private _timeToExecute = (_restartInterval - _warningTime) * 60;
    
    private _handle = [
        {
            params ["_warningTime"];
            private _restartInterval = missionNamespace getVariable ["FLO_restartInterval", 240];
            
            // Calculate time remaining based on current time
            private _startTime = missionNamespace getVariable ["FLO_serverStartTime", diag_tickTime];
            private _timeElapsed = diag_tickTime - _startTime;
            private _timeRemaining = (_restartInterval * 60) - _timeElapsed;
            
            // Update exact remaining time
            private _timeRemainingFormatted = if (_timeRemaining < 60) then {
                format["%1 seconds", round _timeRemaining];
            } else {
                private _mins = floor (_timeRemaining / 60);
                private _secs = floor (_timeRemaining % 60);
                format["%1 minutes and %2 seconds", _mins, _secs];
            };
            
            // Broadcast warning message to all players
            private _message = format["SERVER RESTART in %1 minutes! (%2 remaining)", _warningTime, _timeRemainingFormatted];
            [_message] remoteExec ["systemChat", 0];
            
            ["MISC", 3, format["Server restart warning: %1", _message]] call FLO_fnc_log;
        },
        [_warningTime],
        _timeToExecute
    ] call CBA_fnc_waitAndExecute;
    
    _scheduledNotifications pushBack _handle;
} forEach _warningTimes;

// Set up HUD display for all players
[_restartInterval] remoteExec ["FLO_fnc_initRestartTimerHUD", 0, true];

// Store restart interval globally
missionNamespace setVariable ["FLO_restartInterval", _restartInterval, true];

// Return scheduled notifications if needed for cancellation
_scheduledNotifications 