/*
 * Function: FLO_fnc_transportGetSpeed
 * Author: Frontline Operations Development Group
 * Description:
 *   Get virtual movement speed for a group type.
 *
 * Arguments:
 *   0: Group type <STRING>
 *
 * Return Value:
 *   Speed in m/s <NUMBER>
 *
 * Example:
 *   ["motorized"] call FLO_fnc_transportGetSpeed; // Returns 15
 */

params [["_groupType", "", [""]]];

FLO_Transport_Speeds getOrDefault [_groupType, 5]
