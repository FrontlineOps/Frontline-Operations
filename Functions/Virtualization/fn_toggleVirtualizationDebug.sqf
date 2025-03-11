/*
 * Function: FLO_fnc_toggleVirtualizationDebug
 * Author: Frontline Operations Development Group
 * Description:
 * Toggles debug mode for the OPFOR virtualization system.
 * When enabled, shows markers for all virtual groups on the map.
 *
 * Arguments:
 * 0: Enable <BOOLEAN> - True to enable debug mode, false to disable
 *
 * Return Value:
 * Current Debug State <BOOLEAN>
 *
 * Example:
 * [true] call FLO_fnc_toggleVirtualizationDebug;
 */

params [["_enable", true, [true]]];

// Ensure virtualization system is initialized
if (isNil "FLO_virtualGroups") then {
    [2000] call FLO_fnc_initVirtualization;
};

// Call the _setDebugMode method
[FLO_virtualGroups, _enable] call (FLO_virtualGroups get "_setDebugMode");

// Return current debug state
FLO_virtualGroups get "_debugMode" 