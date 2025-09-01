/*
 * Function: FLO_fnc_safeConfirm
 * Author: Frontline Operations Development Group
 * Description:
 *   A safe, single-instance wrapper around BIS_fnc_guiMessage that prevents:
 *   - Multiple dialogs stacking on screen
 *   - Rapid clicking causing multiple triggers
 *   - Cross-client dialog duplication
 *
 * Arguments:
 *   0: Message text <STRING>
 *   1: Title text <STRING> (optional, default: "")
 *   2: Yes button text <STRING> (optional, default: "YES")
 *   3: No button text <STRING> (optional, default: "NO")
 *   4: Default button <ANY> (optional, default: nil)
 *   5: Show close button <BOOL> (optional, default: false)
 *   6: Modal <BOOL> (optional, default: false)
 *
 * Returns:
 *   <BOOL> - true if YES was clicked, false if NO was clicked
 *
 * Example:
 *   private _result = ["Intercept convoy?", "Intel", "YES", "NO"] call FLO_fnc_safeConfirm;
 *   if (_result) then { hint "Starting mission"; };
 */

// Handle variable parameter count robustly
private _paramCount = count _this;
private _text = if (_paramCount > 0) then { _this select 0 } else { "" };
private _title = if (_paramCount > 1) then { _this select 1 } else { "" };
private _yes = if (_paramCount > 2) then { _this select 2 } else { "YES" };
private _no = if (_paramCount > 3) then { _this select 3 } else { "NO" };
private _default = if (_paramCount > 4) then { _this select 4 } else { nil };
private _showClose = if (_paramCount > 5) then { _this select 5 } else { false };
private _modal = if (_paramCount > 6) then { _this select 6 } else { false };

// Only show dialogs on clients with interface
if (!hasInterface) exitWith {false};

// Prevent mission suggestions during startup grace period
private _missionStartTime = missionNamespace getVariable ["FLO_missionStartTime", 0];
private _gracePeriod = 600; // 10 minutes grace period
if (_missionStartTime > 0 && {diag_tickTime - _missionStartTime < _gracePeriod}) exitWith {
    ["UI", 2, format ["FLO_fnc_safeConfirm: Still in startup grace period (%1s remaining)", _gracePeriod - (diag_tickTime - _missionStartTime)]] call FLO_fnc_log;
    false
};

// Prevent multiple dialogs from stacking
if (uiNamespace getVariable ["FLO_confirmBusy", false]) exitWith {
    ["UI", 2, "FLO_fnc_safeConfirm: Dialog already active, ignoring request"] call FLO_fnc_log;
    false
};

// prevent dialogue if player is in ACE arsenal
private _aceId = 1127001;
if ( !isNull findDisplay _aceId) exitWith {
    ["UI", 2, "FLO_fnc_safeConfirm: ace arsenal currently active, aborting dialogue"] call FLO_fnc_log;
    false
};

// Set busy flag to prevent re-entry
uiNamespace setVariable ["FLO_confirmBusy", true];

// Show the dialog - build parameters array dynamically to handle nil properly
private _params = [_text, _title, _yes, _no];
if (!isNil "_default") then { _params pushBack _default } else { _params pushBack nil };
_params pushBack _showClose;
_params pushBack _modal;

private _result = _params call BIS_fnc_guiMessage;

// Small debounce delay to prevent immediate re-clicks
uiSleep 0.1;

// Clear busy flag
uiNamespace setVariable ["FLO_confirmBusy", false];

_result
