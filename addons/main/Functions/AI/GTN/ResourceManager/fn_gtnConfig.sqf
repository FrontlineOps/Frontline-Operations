/*
 * Function: FLO_fnc_gtnConfig
 * Author: Frontline Operations Development Group
 * Description:
 * Returns the GTN configuration HashMap.
 *
 * Arguments: None
 * Return Value: Configuration HashMap <HASHMAP>
 */

if (!isNil "FLO_GTNConfig") exitWith { FLO_GTNConfig };

FLO_GTNConfig = createHashMapFromArray [
    ["gtnUpdateInterval", 10],           // GTN update cycle interval (seconds)
    ["gtnReplanInterval", 60],           // Minimum time between replans (seconds)
    ["gtnCasualtyThreshold", 0.2]        // Force loss ratio to trigger replan (0-1)
];

["GTN Config", 3, "Configuration loaded"] call FLO_fnc_log;

FLO_GTNConfig
