/*
 * Function: FLO_fnc_initRestartTimerHUD
 * Author: Frontline Operations Development Group
 * Description:
 * Initializes the client-side restart timer HUD.
 * This is called from the server via remoteExec.
 *
 * Arguments:
 * 0: _restartInterval - Server restart interval in minutes [Number]
 *
 * Return Value:
 * None
 */

if (!hasInterface) exitWith {};

params [
    ["_restartInterval", 240, [0]]
];

// Create timer display
[] spawn {
    disableSerialization;
    
    // Remove existing display if present
    if (!isNil "FLO_restartTimerLayer") then {
        FLO_restartTimerLayer cutText ["", "PLAIN"];
    };
    
    // Create layer for our display
    FLO_restartTimerLayer = "FLO_RestartTimer" cutRsc ["RscTitleDisplayEmpty", "PLAIN"];
    private _display = uiNamespace getVariable "RscTitleDisplayEmpty";
    
    // Create timer text
    private _ctrlTimer = _display ctrlCreate ["RscText", -1];
    _ctrlTimer ctrlSetPosition [
        safezoneX + safezoneW - 0.2, // Right side of screen
        safezoneY + 0.02,            // Near top
        0.2,                         // Width
        0.03                         // Height
    ];
    _ctrlTimer ctrlSetTextColor [1, 1, 1, 0.7]; // White with some transparency
    _ctrlTimer ctrlSetFont "PuristaMedium";
    _ctrlTimer ctrlSetFontHeight 0.03;
    _ctrlTimer ctrlSetBackgroundColor [0, 0, 0, 0.3]; // Dark background
    _ctrlTimer ctrlCommit 0;
    
    // Update timer every second
    while {true} do {
        if (isNil "FLO_serverStartTime") then {
            // If server data not available yet
            _ctrlTimer ctrlSetText "Restart: Wait...";
        } else {
            private _startTime = missionNamespace getVariable ["FLO_serverStartTime", diag_tickTime];
            private _restartInterval = missionNamespace getVariable ["FLO_restartInterval", 240];
            
            private _elapsed = diag_tickTime - _startTime;
            private _remaining = (_restartInterval * 60) - _elapsed;
            
            if (_remaining <= 0) then {
                _ctrlTimer ctrlSetText "RESTARTING...";
                _ctrlTimer ctrlSetTextColor [1, 0, 0, 1]; // Bright red
            } else {
                private _hours = floor (_remaining / 3600);
                private _minutes = floor ((_remaining % 3600) / 60);
                private _seconds = floor (_remaining % 60);
                
                private _timeText = if (_hours > 0) then {
                    format["Restart: %1h %2m", _hours, _minutes];
                } else {
                    if (_minutes > 0) then {
                        format["Restart: %1m %2s", _minutes, _seconds];
                    } else {
                        format["Restart: %1s", _seconds];
                    };
                };
                
                _ctrlTimer ctrlSetText _timeText;
                
                // Change color as we get closer to restart
                if (_remaining < 300) then { // Less than 5 minutes
                    _ctrlTimer ctrlSetTextColor [1, 0.3, 0.3, 0.9]; // Red
                } else {
                    if (_remaining < 600) then { // Less than 10 minutes
                        _ctrlTimer ctrlSetTextColor [1, 0.6, 0.2, 0.8]; // Orange
                    };
                };
            };
        };
        
        // Update interval
        sleep 1;
    };
}; 