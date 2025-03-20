private _getCurrentSystemTime = {
    private _systemTime = systemTime; // [year, month, day, hour, minute, second, milliseconds]
    private _hour = _systemTime select 3; // Extract the hour
    private _minute = _systemTime select 4; // Extract the minute
    private _currentTime = _hour + (_minute / 60); // Convert to decimal hours
    _currentTime
};

// Time until restart calculation
private _calculateTimeUntilRestart = {
    private _currentTime = call _getCurrentSystemTime;
    
    // Define restart intervals (every 6 hours: 0, 6, 12, 18)
    private _restartTimes = [0, 6, 12, 18];
    
    // Find the next restart time
    private _nextRestart = 24; // Default to next day
    {
        if (_x > _currentTime) exitWith {
            _nextRestart = _x;
        };
    } forEach _restartTimes;
    
    // If we didn't find a restart time today, use the first one tomorrow
    if (_nextRestart == 24) then {
        _nextRestart = _restartTimes select 0;
    };
    
    // Calculate hours until restart
    private _hoursUntilRestart = _nextRestart - _currentTime;
    if (_hoursUntilRestart < 0) then {
        _hoursUntilRestart = _hoursUntilRestart + 24;
    };
    
    _hoursUntilRestart
};

// Notification function
private _notifyPlayers = {
    params ["_message", "_importance"];
    
    // Different notification styles based on importance
    switch (_importance) do {
        // High importance - red text
        case 2: {
            [parseText format ["<t size='1.3' color='#FF0000'>%1</t>", _message], true, nil, 7, 0.7, 0.3] spawn BIS_fnc_dynamicText;
            playSound "FD_CP_Not_Clear_F";
        };
        // Medium importance - yellow text
        case 1: {
            [parseText format ["<t size='1.2' color='#FFFF00'>%1</t>", _message], true, nil, 5, 0.7, 0.3] spawn BIS_fnc_dynamicText;
            playSound "FD_CP_Not_Clear_F";
        };
        // Low importance - white text
        default {
            [parseText format ["<t size='1.1' color='#FFFFFF'>%1</t>", _message], true, nil, 5, 0.7, 0.3] spawn BIS_fnc_dynamicText;
        };
    };
};

// Initialize last check time
private _lastCheckTime = -1;
private _notified30min = false;
private _notified15min = false;
private _notified5min = false;

// Main heartbeat loop
[] spawn {
    while { true } do {
        // Calculate time until restart
        private _hoursUntilRestart = call _calculateTimeUntilRestart;
        private _minutesUntilRestart = _hoursUntilRestart * 60;
        
        // Check for notification thresholds
        if (_minutesUntilRestart <= 30 && _minutesUntilRestart > 15 && !_notified30min) then {
            ["SERVER RESTART in 30 minutes", 0] call _notifyPlayers;
            _notified30min = true;
        };
        
        if (_minutesUntilRestart <= 15 && _minutesUntilRestart > 5 && !_notified15min) then {
            ["SERVER RESTART in 15 minutes", 1] call _notifyPlayers;
            _notified15min = true;
        };
        
        if (_minutesUntilRestart <= 5 && !_notified5min) then {
            ["SERVER RESTART in 5 minutes - Please finish your current activity", 2] call _notifyPlayers;
            _notified5min = true;
        };
        
        // Reset notifications if we've passed a restart time
        if (_notified5min && _minutesUntilRestart > 5.1) then {
            _notified30min = false;
            _notified15min = false;
            _notified5min = false;
        };
        
        // Wait before next check
        // Check more frequently as we get closer to restart time
        private _sleepTime = 60; // Default to check every minute
        if (_minutesUntilRestart < 6) then {
            _sleepTime = 30; // Check every 30 seconds when close to restart
        };
        
        sleep _sleepTime;
    };
};

// Return the current time function in case it's needed elsewhere
_getCurrentSystemTime