/*
 * Function: FLO_fnc_disableSystemChat
 * Author: Frontline Operations Development Group
 * Description:
 * Removes system chat for all players to reduce UI clutter.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call FLO_fnc_disableSystemChat;
 */

// Only execute on clients
if (!hasInterface) exitWith {};

["MISC", 3, "Initializing system chat remover"] call FLO_fnc_log;

// Disable chat initially
showChat false;

// Wait for the main interface to be available
[
    {!isNull findDisplay 46},
    {
        // Add an event handler for catching key presses
        (findDisplay 46) displayAddEventHandler ["KeyDown", {
            // If chat becomes visible for any reason, hide it again
            if (shownChat) then {
                showChat false;
                ["MISC", 5, "Chat re-disabled after activation"] call FLO_fnc_log;
            };
            false
        }];
        
        // Also monitor game messages display
        [
            {!isNull findDisplay 24},
            {
                (findDisplay 24) displayAddEventHandler ["Unload", {
                    showChat false;
                }];
            }
        ] call CBA_fnc_waitUntilAndExecute;
        
        ["MISC", 3, "Chat disable systems initialized"] call FLO_fnc_log;
    }
] call CBA_fnc_waitUntilAndExecute;

["MISC", 3, "System chat disabled"] call FLO_fnc_log; 