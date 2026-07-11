/*
 * Function: FLO_fnc_virtualizationClearRealVehicles
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the canonical live vehicle references for a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the references were cleared
 */

params ["_groupData"];

_groupData set ["realVehicles", []];

true
