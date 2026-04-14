/*
    Function: FLO_fnc_heartBeat

    Description:
    Server restart notification system based on server UPTIME, not wall clock.
    Tracks how long the server has been running and notifies players when
    restart is approaching.

    Configuration:
    - RESTART_INTERVAL_HOURS: How often the server restarts (default: 8)
    - Notification thresholds: 60, 30, 15, 10, 5, 2, 1 minutes before restart

    Parameter(s):
        None (self-initializing, run once on server)

    Returns:
        Nothing

    Example:
        [] spawn FLO_fnc_heartBeat;
*/

if (!isServer) exitWith {};
if (!isNil "FLO_Heartbeat_Running") exitWith {
    diag_log "[FLO_HEARTBEAT] Already running, exiting";
};
FLO_Heartbeat_Running = true;

// ============================================================================
// CONFIGURATION
// ============================================================================

// How often does your server restart? (in hours)
private _restartIntervalHours = 8;

// Notification thresholds (minutes before restart) - sorted descending
private _notificationThresholds = [60, 30, 15, 10, 5, 2, 1];

// Check frequency
private _checkFrequencyNormal = 60;  // Check every 60 seconds normally
private _checkFrequencyUrgent = 15;  // Check every 15 seconds when < 5 min left

// ============================================================================
// INITIALIZE
// ============================================================================

// Record server start time using diag_tickTime (real seconds since game start)
private _serverStartTick = diag_tickTime;
private _restartIntervalSeconds = _restartIntervalHours * 3600;

// Calculate restart time
private _restartTick = _serverStartTick + _restartIntervalSeconds;

// Log startup info
private _restartTimeFormatted = [_restartIntervalHours, 0] call {
    params ["_h", "_m"];
    format ["%1h %2m", _h, _m]
};
diag_log format ["[FLO_HEARTBEAT] Started | Restart in %1 (%2 seconds)",
    _restartTimeFormatted, _restartIntervalSeconds];

// Broadcast restart time to clients for UI display if needed
FLO_Server_RestartTick = _restartTick;
FLO_Server_StartTick = _serverStartTick;
publicVariable "FLO_Server_RestartTick";
publicVariable "FLO_Server_StartTick";

// ============================================================================
// NOTIFICATION FUNCTION
// ============================================================================

private _fnc_notify = {
    params ["_minutesLeft"];

    // Determine urgency level and color
    private _urgency = switch (true) do {
        case (_minutesLeft <= 2):  { 3 };  // CRITICAL
        case (_minutesLeft <= 5):  { 2 };  // HIGH
        case (_minutesLeft <= 15): { 1 };  // MEDIUM
        default                    { 0 };  // LOW
    };

    private _color = switch (_urgency) do {
        case 3: { "#FF0000" };  // Red - critical
        case 2: { "#FF6600" };  // Orange - high
        case 1: { "#FFFF00" };  // Yellow - medium
        default { "#FFFFFF" };  // White - low
    };

    // Format message
    private _timeStr = if (_minutesLeft >= 60) then {
        format ["%1 hour%2", floor(_minutesLeft / 60), if (_minutesLeft >= 120) then {"s"} else {""}]
    } else {
        format ["%1 minute%2", _minutesLeft, if (_minutesLeft != 1) then {"s"} else {""}]
    };

    private _message = format ["SERVER RESTART in %1", _timeStr];

    // Add urgency suffix
    if (_minutesLeft <= 5) then {
        _message = _message + " - Save your progress!";
    } else {
        if (_minutesLeft <= 15) then {
            _message = _message + " - Finish current objectives";
        };
    };

    // Size and duration scale with urgency
    private _size = 1.0 + (_urgency * 0.15);
    private _duration = 5 + (_urgency * 2);

    // Send to all players
    private _formattedText = format ["<t size='%1' color='%2'>%3</t>", _size, _color, _message];
    ["dynamicTextBroadcasts", 1] call FLO_fnc_netDebugRecord;
    [_formattedText, _duration] remoteExec ["FLO_fnc_showDynamicText", 0];

    // Play warning sound for urgent notifications
    if (_urgency >= 2) then {
        "FD_CP_Not_Clear_F" remoteExec ["playSound", 0];
    };

    diag_log format ["[FLO_HEARTBEAT] Notification sent: %1 minutes remaining", _minutesLeft];
};

// ============================================================================
// MAIN LOOP
// ============================================================================

[_restartTick, _notificationThresholds, _checkFrequencyNormal, _checkFrequencyUrgent, _fnc_notify] spawn {
    params ["_restartTick", "_thresholds", "_freqNormal", "_freqUrgent", "_fnc_notify"];

    // Track which thresholds we've already notified for
    private _notifiedThresholds = createHashMap;

    while {true} do {
        // Calculate time remaining
        private _secondsLeft = _restartTick - diag_tickTime;
        private _minutesLeft = floor(_secondsLeft / 60);

        // Update public variable for client UI
        FLO_Server_SecondsToRestart = _secondsLeft max 0;
        publicVariable "FLO_Server_SecondsToRestart";

        // Check if we've passed restart time (shouldn't happen, but safety)
        if (_secondsLeft <= 0) exitWith {
            diag_log "[FLO_HEARTBEAT] Restart time reached - notifications complete";
        };

        // Check each threshold
        {
            private _threshold = _x;

            // If we're at or below this threshold and haven't notified
            if (_minutesLeft <= _threshold && {!(_notifiedThresholds getOrDefault [_threshold, false])}) then {
                // Send notification
                [_threshold] call _fnc_notify;

                // Mark as notified
                _notifiedThresholds set [_threshold, true];
            };
        } forEach _thresholds;

        // Determine sleep time
        private _sleepTime = if (_minutesLeft <= 5) then { _freqUrgent } else { _freqNormal };

        sleep _sleepTime;
    };
};
