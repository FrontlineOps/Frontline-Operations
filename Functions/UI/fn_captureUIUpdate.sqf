/*
 * Function: FLO_fnc_captureUIUpdate
 * Author: Frontline Operations Development Group
 * Description:
 *   Client-side polling loop for capture UI.
 *   Reads from publicVariable'd FLO_Objectives and updates HTML UI.
 *   Runs as a spawned loop, started from fn_captureUI "init".
 *
 * Arguments: None (runs as loop)
 *
 * Returns: Nothing
 */

if (!hasInterface) exitWith {};

// Prevent multiple loops
if (!isNil "FLO_CaptureUI_LoopRunning" && {FLO_CaptureUI_LoopRunning}) exitWith {};
FLO_CaptureUI_LoopRunning = true;

// Initialize state
FLO_CaptureUI_DisplayOpen = false;
FLO_CaptureUI_HTMLReady = false;
FLO_CaptureUI_CurrentObj = "";

// Wait for objectives to sync from server
waitUntil { sleep 0.5; !isNil "FLO_Objectives" && {count keys FLO_Objectives > 0} };

// Fast polling for responsive UI (0.05s = 20 FPS)
private _pollInterval = 0.05;

while {FLO_CaptureUI_LoopRunning} do {
    private _playerPos = getPosATL player;
    private _inObjective = false;
    private _currentObjId = "";
    private _currentObjData = createHashMap;

    // Find which objective player is in (if any)
    {
        private _objData = FLO_Objectives get _x;
        if (!isNil "_objData") then {
            if ([_playerPos, _objData] call FLO_fnc_isPositionInObjective) exitWith {
                _inObjective = true;
                _currentObjId = _x;
                _currentObjData = _objData;
            };
        };
    } forEach (keys FLO_Objectives);

    if (_inObjective) then {
        private _name = _currentObjData getOrDefault ["name", _currentObjId];
        private _bluforCount = _currentObjData getOrDefault ["bluforCount", 0];
        private _opforCount = _currentObjData getOrDefault ["opforCount", 0];
        private _totalCount = _bluforCount + _opforCount;
        private _ratio = if (_totalCount > 0) then { _bluforCount / _totalCount } else { 0.5 };

        // Open display if not already open
        if (!FLO_CaptureUI_DisplayOpen) then {
            1 cutRsc ["FLO_CaptureUI", "PLAIN", 0.1];
            FLO_CaptureUI_DisplayOpen = true;
            FLO_CaptureUI_HTMLReady = false;
            FLO_CaptureUI_CurrentObj = _currentObjId;

            // Wait for HTML to load then show
            [_name] spawn {
                params ["_objName"];
                sleep 0.3;

                private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
                if (!isNull _display) then {
                    private _ctrl = _display displayCtrl 1101;
                    if (!isNull _ctrl) then {
                        _ctrl ctrlWebBrowserAction ["ExecJS", format ["showCaptureUI('%1')", _objName]];
                        FLO_CaptureUI_HTMLReady = true;
                    };
                };
            };
        };

        // Handle objective change
        if (FLO_CaptureUI_HTMLReady && {FLO_CaptureUI_CurrentObj != _currentObjId}) then {
            private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
            if (!isNull _display) then {
                private _ctrl = _display displayCtrl 1101;
                if (!isNull _ctrl) then {
                    _ctrl ctrlWebBrowserAction ["ExecJS", format ["showCaptureUI('%1')", _name]];
                };
            };
            FLO_CaptureUI_CurrentObj = _currentObjId;
        };

        // Update UI if ready
        if (FLO_CaptureUI_HTMLReady) then {
            private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
            if (!isNull _display) then {
                private _ctrl = _display displayCtrl 1101;
                if (!isNull _ctrl) then {
                    _ctrl ctrlWebBrowserAction ["ExecJS", format ["updateCaptureUI(%1, %2, %3)", _ratio, _bluforCount, _opforCount]];
                };
            };
        };
    } else {
        // Player not in any objective - hide UI if open
        if (FLO_CaptureUI_DisplayOpen) then {
            private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
            if (!isNull _display) then {
                private _ctrl = _display displayCtrl 1101;
                if (!isNull _ctrl) then {
                    _ctrl ctrlWebBrowserAction ["ExecJS", "hideCaptureUI()"];
                };
            };
            FLO_CaptureUI_DisplayOpen = false;
            FLO_CaptureUI_HTMLReady = false;
            FLO_CaptureUI_CurrentObj = "";
        };
    };

    sleep _pollInterval;
};
