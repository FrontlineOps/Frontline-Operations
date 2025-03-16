/*
 * Function: FLO_fnc_ragequitBlocker
 * Author: Frontline Operations Development Group
 * Description:
 * Prevents players from clicking the abort button while dead or unconscious.
 * The abort button is only enabled when the player is alive and conscious.
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

// Wait for the display to be available
[
    {
        (!isNull findDisplay 46)
    },
    {
        private _display = findDisplay 46;

        _display displayAddEventHandler ["KeyDown", {
            params ["", "_key"];    

            private _escapeKeys = actionKeys "ingamePause";

            if (_key in _escapeKeys) then {
                // Default state (enable abort button when alive and conscious)
                private _allowAbort = true;
                
                if (!(alive player) || player getVariable ["ACE_isUnconscious", false]) then {
                    _allowAbort = false;
                    ["MISC", 4, "Player is dead or unconscious, disabling abort button"] call FLO_fnc_log;
                } else {
                    ["MISC", 4, "Player is alive and conscious, allowing abort button"] call FLO_fnc_log;
                };
                
                // Get the abort button from the escape menu and set its state
                [
                    {!isNull (findDisplay 49)},
                    {
                        private _abortButton = (findDisplay 49) displayCtrl 104;
                        _abortButton ctrlEnable (_this select 0);
                        
                        // Add a hint if blocked
                        if (!(_this select 0)) then {
                            hint "Abort button is disabled while you are dead or unconscious.\nYou must be alive and conscious to abort the mission.";
                        };
                    },
                    [_allowAbort]
                ] call CBA_fnc_waitUntilAndExecute;
            };
            
            false
        }];
        
        ["MISC", 3, "Rage quit blocker initialized"] call FLO_fnc_log;
    },    
    []
] call CBA_fnc_waitUntilAndExecute; 