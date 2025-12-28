/*
 * Function: FLO_fnc_captureUI
 * Author: Frontline Operations Development Group
 * Description:
 *   Manages the HTML-based capture balance of power UI.
 *   Spawns a client-side polling loop that reads from FLO_Objectives.
 *   This function handles init/cleanup and manual operations.
 *
 * IDC Reference (from FLO_captureUI.hpp):
 *   IDD: 1100
 *   1101 - IFrame control (HTML UI)
 *
 * Arguments:
 *   0: Operation <STRING> - "init", "stop", "show", "hide", "update"
 *   1: Arguments <ARRAY> - Operation-specific arguments
 *
 * Examples:
 *   ["init"] call FLO_fnc_captureUI;
 */

params [["_operation", ""], ["_args", []]];

private _result = nil;

switch (toLower _operation) do {

    // Initialize and start the polling loop
    case "init";
    case "start": {
        if (!hasInterface) exitWith { _result = false };

        // Spawn the polling loop (defined in fn_captureUIUpdate)
        [] spawn FLO_fnc_captureUIUpdate;

        ["UI", 3, "Capture UI polling loop started"] call FLO_fnc_log;
        _result = true;
    };

    // Stop the polling loop and cleanup
    case "stop": {
        if (!hasInterface) exitWith { _result = false };

        // Stop the loop
        FLO_CaptureUI_LoopRunning = false;

        private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
        if (!isNull _display) then {
            private _ctrl = _display displayCtrl 1101;
            if (!isNull _ctrl) then {
                _ctrl ctrlWebBrowserAction ["ExecJS", "hideCaptureUI()"];
            };
        };

        1 cutFadeOut 0.3;
        FLO_CaptureUI_DisplayOpen = false;
        FLO_CaptureUI_HTMLReady = false;
        FLO_CaptureUI_CurrentObj = "";
        _result = true;
    };

    // Show the capture UI (sends command to HTML)
    case "show": {
        _args params [["_objectiveName", "Objective"]];

        private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
        if (isNull _display) exitWith { _result = false };

        private _ctrl = _display displayCtrl 1101;
        if (isNull _ctrl) exitWith { _result = false };

        _ctrl ctrlWebBrowserAction ["ExecJS", format ["showCaptureUI('%1')", _objectiveName]];
        _result = true;
    };

    // Hide the capture UI (sends command to HTML)
    case "hide": {
        private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
        if (!isNull _display) then {
            private _ctrl = _display displayCtrl 1101;
            if (!isNull _ctrl) then {
                _ctrl ctrlWebBrowserAction ["ExecJS", "hideCaptureUI()"];
            };
        };
        FLO_CaptureUI_DisplayOpen = false;
        _result = true;
    };

    // Update the capture bar (sends data to HTML)
    case "update": {
        _args params [["_ratio", 0.5], ["_bluforCount", 0], ["_opforCount", 0]];

        private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
        if (isNull _display) exitWith { _result = false };

        private _ctrl = _display displayCtrl 1101;
        if (isNull _ctrl) exitWith { _result = false };

        _ctrl ctrlWebBrowserAction ["ExecJS", format ["updateCaptureUI(%1, %2, %3)", _ratio, _bluforCount, _opforCount]];
        _result = true;
    };
};

_result

