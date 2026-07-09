/*
 * Function: FLO_fnc_virtualizationSetRealVehicles
 * Author: Frontline Operations Development Group
 * Description:
 *   Stores the canonical live vehicle references for a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Vehicle refs <ARRAY>
 *
 * Return Value:
 * BOOL - True when the references were updated
 */

params ["_groupData", ["_vehicles", [], [[]]]];

_groupData set ["realVehicles", _vehicles];

true
