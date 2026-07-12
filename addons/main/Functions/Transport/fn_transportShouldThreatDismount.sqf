/*
 * Function: FLO_fnc_transportShouldThreatDismount
 * Author: Frontline Operations Development Group
 * Description:
 *   Determines whether a transport carrier should unload because it is in
 *   contact or because maintained side-owned intel reports enemy presence close
 *   to the carrier.
 *
 * Arguments:
 *   0: Carrier Group Data <HASHMAP>
 *   1: Carrier Position <ARRAY>
 *
 * Return Value:
 *   BOOL - True when threat conditions justify an unload
 */

params [
    ["_groupData", createHashMap, [createHashMap]],
    ["_carrierPos", [0, 0, 0], [[]]]
];

if (_groupData get "inCombat") exitWith { true };

[(_groupData get "side"), _carrierPos, FLO_Transport_ThreatDismountRadius] call FLO_fnc_transportHasKnownEnemyNearby
