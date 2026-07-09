/*
 * Function: FLO_fnc_ragequitBlocker
 * Author: Frontline Operations Development Group
 * Description:
 * Prevents players from clicking the abort/respawn buttons while dead or unconscious.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call FLO_fnc_ragequitBlocker;
 */

// Only execute on clients
if (!hasInterface) exitWith {};

["MISC", 3, "Initializing rage quit blocker"] call FLO_fnc_log;

// Wait for the main display to be available
[{!isNull findDisplay 46}, {
    // Add event handler for Escape key
    (findDisplay 46) displayAddEventHandler ["KeyDown", {
        params ["", "_key"];

        // Only process Escape key presses
        if (_key in actionKeys "ingamePause") then {
            // Set button state based on player status
            private _allowControls = alive player && !(player getVariable ["ACE_isUnconscious", false]);

            // Wait for and modify the escape menu
            [{!isNull findDisplay 49}, {
                // Disable/Enable both buttons
                {
                    ((findDisplay 49) displayCtrl _x) ctrlEnable (_this select 0);
                } forEach [104, 1010]; // 104 = Abort, 1010 = Respawn

                // Show message if blocked
                if !(_this select 0) then {
                    hint "Mission controls are disabled while you are dead or unconscious.\nYou must be alive and conscious to abort or respawn.";
                };
            }, [_allowControls]] call CBA_fnc_waitUntilAndExecute;
        };

        false
    }];

    ["MISC", 3, "Rage quit blocker initialized"] call FLO_fnc_log;
}, []] call CBA_fnc_waitUntilAndExecute;
