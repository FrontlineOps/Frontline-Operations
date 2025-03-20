/*
 * Author: FLOPS Team
 * Server restart notification system that alerts players at configurable intervals
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] spawn FLO_fnc_heartBeat;
 */

if (!isServer) exitWith {};

// Configuration
private _restartIntervals = [0, 6, 12, 18]; // Restart times (24h format)
private _notificationTimes = [30, 15, 5]; // Minutes before restart to notify
private _checkFrequency = 60; // Default check frequency in seconds
private _urgentCheckFrequency = 30; // Check frequency when close to restart

// Time calculation functions
private _fnc_getCurrentTime = {
    private _systemTime = systemTime;
    (_systemTime select 3) + ((_systemTime select 4) / 60)
};

private _fnc_getTimeUntilRestart = {
    params ["_restartIntervals", "_fnc_getCurrentTime"];
    
    private _currentTime = call _fnc_getCurrentTime;
    
    // Find next restart time
    private _nextRestart = 24;
    {
        if (_x > _currentTime) exitWith {
            _nextRestart = _x;
        };
    } forEach _restartIntervals;
    
    // If no restart time found today, use first one tomorrow
    if (_nextRestart isEqualTo 24) then {
        _nextRestart = _restartIntervals select 0;
    };
    
    // Calculate hours until restart
    private _hoursUntilRestart = _nextRestart - _currentTime;
    if (_hoursUntilRestart < 0) then {
        _hoursUntilRestart = _hoursUntilRestart + 24;
    };
    
    _hoursUntilRestart * 60; // Return minutes until restart
};

// Notification function
private _fnc_notifyPlayers = {
    params ["_message", "_importance"];
    
    private _color = switch (_importance) do {
        case 2: { "#FF0000" }; // High - Red
        case 1: { "#FFFF00" }; // Medium - Yellow
        default { "#FFFFFF" }; // Low - White
    };
    
    private _size = 1.1 + (_importance * 0.1); // Size increases with importance
    private _duration = 5 + (_importance * 1); // Duration increases with importance
    
    // Send notification to all players
    [parseText format ["<t size='%1' color='%2'>%3</t>", _size, _color, _message], true, nil, _duration, 0.7, 0.3] remoteExec ["BIS_fnc_dynamicText", 0];
    
    // Play sound for medium and high importance
    if (_importance > 0) then {
        "FD_CP_Not_Clear_F" remoteExec ["playSound", 0];
    };
};

// Main loop - pass all required variables to the spawn
[_restartIntervals, _notificationTimes, _checkFrequency, _urgentCheckFrequency, _fnc_getCurrentTime, _fnc_getTimeUntilRestart, _fnc_notifyPlayers] spawn {
    params [
        "_restartIntervals",
        "_notificationTimes", 
        "_checkFrequency", 
        "_urgentCheckFrequency",
        "_fnc_getCurrentTime",
        "_fnc_getTimeUntilRestart",
        "_fnc_notifyPlayers"
    ];
    
    // Initialize notification flags
    private _notified = [];
    {
        _notified pushBack false;
    } forEach _notificationTimes;
    
    while {true} do {
        private _minutesUntilRestart = [_restartIntervals, _fnc_getCurrentTime] call _fnc_getTimeUntilRestart;
        
        // Check each notification threshold
        {
            private _threshold = _x;
            private _index = _forEachIndex;
            
            // If we're within this threshold and haven't notified yet
            if (_minutesUntilRestart <= _threshold && {!(_notified select _index)}) then {
                // Determine importance (higher for closer to restart)
                private _importance = floor((_forEachIndex) / (count _notificationTimes - 1) * 2);
                
                // Create message
                private _message = format ["SERVER RESTART in %1 minutes", _threshold];
                if (_threshold <= 5) then {
                    _message = _message + " - Please finish your current activity";
                };
                
                // Send notification
                [_message, _importance] call _fnc_notifyPlayers;
                
                // Mark as notified
                _notified set [_index, true];
            };
        } forEach _notificationTimes;
        
        // Reset notifications if we've passed a restart
        if (_minutesUntilRestart > (_notificationTimes select 0)) then {
            {
                _notified set [_forEachIndex, false];
            } forEach _notificationTimes;
        };
        
        // Determine sleep time based on proximity to restart
        private _sleepTime = _checkFrequency;
        if (_minutesUntilRestart < 6) then {
            _sleepTime = _urgentCheckFrequency;
        };
        
        sleep _sleepTime;
    };
};