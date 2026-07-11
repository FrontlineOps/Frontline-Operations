/*
 * Function: FLO_fnc_factionCompositionDefaultCounts
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds default group count values.
 *
 * Arguments:
 * 0: Maneuver count <NUMBER>
 * 1: Artillery count <NUMBER>
 * 2: Infantry count <NUMBER>
 *
 * Returns:
 * Counts <ARRAY>
 */
params [
    ["_maneuverCount", 1, [0]],
    ["_artilleryCount", 3, [0]],
    ["_infantryCount", 10, [0]]
];

[
    ["infantry", _infantryCount],
    ["motorized", _maneuverCount],
    ["mechanized", _maneuverCount],
    ["armor", _maneuverCount],
    ["helicopter", 1],
    ["jet", 1],
    ["air", 1],
    ["artillery", _artilleryCount],
    ["mobile_aa", 1],
    ["static_aa", 1]
]
