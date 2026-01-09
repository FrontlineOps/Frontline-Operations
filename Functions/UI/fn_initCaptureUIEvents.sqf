/*
 * Function: FLO_fnc_initCaptureUIEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers client-side CBA event handlers for the Capture UI.
 *   Server fires these events to individual clients when they enter/leave objectives.
 *   This approach is more reliable on dedicated servers than polling publicVariables.
 *
 * CBA Events:
 *   FLO_CaptureUI_Show  - [objectiveName, objectiveId] - Shows the UI
 *   FLO_CaptureUI_Hide  - [] - Hides the UI
 *   FLO_CaptureUI_Update - [ratio, bluforCount, opforCount] - Updates the bar
 *
 * Arguments: None
 *
 * Returns: BOOL - True if initialized
 *
 * Example:
 *   [] call FLO_fnc_initCaptureUIEvents;
 */

if (!hasInterface) exitWith { false };

// Prevent multiple initializations
if (!isNil "FLO_CaptureUI_EventsInit" && {FLO_CaptureUI_EventsInit}) exitWith {
    ["UI", 4, "CaptureUI events already initialized - skipping"] call FLO_fnc_log;
    true
};

["UI", 3, "Initializing CaptureUI CBA event handlers..."] call FLO_fnc_log;

// Initialize state
FLO_CaptureUI_DisplayOpen = false;
FLO_CaptureUI_HTMLReady = false;
FLO_CaptureUI_CurrentObj = "";

// ============================================================================
// EVENT: FLO_CaptureUI_Show
// Called by server when player enters an objective area
// ============================================================================
["FLO_CaptureUI_Show", {
    params [["_objectiveName", "Objective"], ["_objectiveId", ""]];

    ["UI", 3, format["CaptureUI_Show event received: %1 (%2)", _objectiveName, _objectiveId]] call FLO_fnc_log;

    // Already showing this objective?
    if (FLO_CaptureUI_DisplayOpen && {FLO_CaptureUI_CurrentObj == _objectiveId}) exitWith {};

    // If showing different objective, just update the name
    if (FLO_CaptureUI_DisplayOpen && {FLO_CaptureUI_HTMLReady}) then {
        private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
        if (!isNull _display) then {
            private _ctrl = _display displayCtrl 1101;
            if (!isNull _ctrl) then {
                _ctrl ctrlWebBrowserAction ["ExecJS", format ["showCaptureUI('%1')", _objectiveName]];
            };
        };
        FLO_CaptureUI_CurrentObj = _objectiveId;
    } else {
        // Create the display
        1 cutRsc ["FLO_CaptureUI", "PLAIN", 0.1];
        FLO_CaptureUI_DisplayOpen = true;
        FLO_CaptureUI_HTMLReady = false;
        FLO_CaptureUI_CurrentObj = _objectiveId;

        // Wait for HTML to load then show (polling with timeout)
        [_objectiveName] spawn {
            params ["_objName"];

            private _startTime = diag_tickTime;
            private _timeout = 3;
            private _display = displayNull;
            private _ctrl = controlNull;

            // Poll until display and control are ready
            waitUntil {
                sleep 0.1;
                _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
                if (!isNull _display) then {
                    _ctrl = _display displayCtrl 1101;
                };
                (!isNull _ctrl) || {(diag_tickTime - _startTime) > _timeout}
            };

            if (isNull _ctrl) exitWith {
                ["UI", 1, "CaptureUI control (1101) NULL after timeout"] call FLO_fnc_log;
            };

            // Additional delay for JavaScript init on dedicated
            sleep 0.5;

            _ctrl ctrlWebBrowserAction ["ExecJS", format ["showCaptureUI('%1')", _objName]];
            FLO_CaptureUI_HTMLReady = true;
            ["UI", 4, format["CaptureUI HTML ready for %1", _objName]] call FLO_fnc_log;
        };
    };
}] call CBA_fnc_addEventHandler;

// ============================================================================
// EVENT: FLO_CaptureUI_Hide
// Called by server when player leaves all objective areas
// ============================================================================
["FLO_CaptureUI_Hide", {
    ["UI", 4, "CaptureUI_Hide event received"] call FLO_fnc_log;

    if (!FLO_CaptureUI_DisplayOpen) exitWith {};

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
}] call CBA_fnc_addEventHandler;

// ============================================================================
// EVENT: FLO_CaptureUI_Update
// Called by server with current capture status
// ============================================================================
["FLO_CaptureUI_Update", {
    params [["_ratio", 0.5], ["_bluforCount", 0], ["_opforCount", 0], ["_owner", "EAST"]];

    if (!FLO_CaptureUI_DisplayOpen || !FLO_CaptureUI_HTMLReady) exitWith {};

    private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
    if (!isNull _display) then {
        private _ctrl = _display displayCtrl 1101;
        if (!isNull _ctrl) then {
            _ctrl ctrlWebBrowserAction ["ExecJS", format ["updateCaptureUI(%1, %2, %3, '%4')", _ratio, _bluforCount, _opforCount, _owner]];
        };
    };
}] call CBA_fnc_addEventHandler;

// Mark as initialized
FLO_CaptureUI_EventsInit = true;
["UI", 3, "CaptureUI CBA event handlers registered"] call FLO_fnc_log;

true

