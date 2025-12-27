/*
 * Starting FOB Initialization
 * Author: Frontline Operations
 *
 * Description:
 * Initializes the starting FOB near the player and adds commander-only
 * hold actions for mission management (save, reset, weather, etc.).
 *
 * This script runs on each client after the starting location is selected.
 *
 * Global Variables Set:
 * - FOBB: Reference to the main FOB building
 */

// ============================================================================
// FOB BUILDING INITIALIZATION
// ============================================================================

FOBB = nearestObjects [position player, [F_HQ_01], 150] select 0;
publicVariable "FOBB";

if (!isNil "FOBB") then {
    [FOBB] call FLO_fnc_initializeFOB;
    ["INIT_FOB", 3, format["FOB initialized at %1", mapGridPosition FOBB]] call FLO_fnc_log;
} else {
    ["INIT_FOB", 1, "Error: No FOB building found within 150m of player"] call FLO_fnc_log;
};

// ============================================================================
// COMMANDER HOLD ACTIONS
// ============================================================================

private _fobContainer = nearestObjects [position player, [F_HQ_C_01], 150] select 0;

if (isNil "_fobContainer") exitWith {
    ["INIT_FOB", 1, "Error: No FOB container found for commander actions"] call FLO_fnc_log;
};

// Common condition for commander-only actions
// Requires: player is commander AND (has admin rights OR is local server)
private _commanderCondition =
    "((player == TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || " +
    "((player == TheCommander) && (isServer))";
private _proximityCondition = "_caller distance _target < 40";
private _iconPath = "Screens\FOBA\b_hq.paa";

// Helper function to create hold actions with consistent format
private _fnc_addCommanderAction = {
    params ["_target", "_label", "_color", "_onComplete", "_duration", "_priority"];

    [
        _target,
        format ["<img size=2 color='%1' image='%2'/><t font='PuristaBold' color='%1'>%3", _color, _iconPath, _label],
        _iconPath,
        _iconPath,
        _commanderCondition,
        _proximityCondition,
        {},  // onStart
        {},  // onProgress
        _onComplete,
        {},  // onCancel
        [],  // arguments
        _duration,
        _priority,
        false,  // removeOnComplete
        false   // showUnconscious
    ] remoteExec ["BIS_fnc_holdActionAdd", 0, true];
};

// Skip Time action
[
    _fobContainer,
    "Skip_Time",
    "#7CC2FF",
    { createDialog "C_LOCK"; },
    5,
    4
] call _fnc_addCommanderAction;

// Change Weather action
[
    _fobContainer,
    "Change_Weather",
    "#7CC2FF",
    { { execVM "Scripts\Init\init_Weather.sqf"; } remoteExec ["call", 2]; },
    5,
    4
] call _fnc_addCommanderAction;

// Save Mission Progress action
[
    _fobContainer,
    "SAVE Mission Progress",
    "#FFE496",
    { remoteExec ["FLO_fnc_MissionSave", 2]; },
    7,
    6
] call _fnc_addCommanderAction;

// Reset Mission Progress action
[
    _fobContainer,
    "RESET Mission Progress",
    "#FFE496",
    { { execVM "Scripts\MissionReset.sqf"; } remoteExec ["call", 2]; },
    7,
    5
] call _fnc_addCommanderAction;

// Bribe Militia action
[
    _fobContainer,
    "Bribe_Militia_(200)",
    "#59ff58",
    { [] execVM "Scripts\BRIBE.sqf"; },
    7,
    3
] call _fnc_addCommanderAction;

// ============================================================================
// NOTIFICATION
// ============================================================================

[playerSide, "HQ"] commandChat "FOB Deployed!";
["INIT_FOB", 3, "Starting FOB initialization complete"] call FLO_fnc_log;