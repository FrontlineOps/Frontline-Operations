/*
 * Function: FLO_fnc_gtnIsEngagementRouteActive
 * Author: Frontline Operations Development Group
 * Description:
 *   True when a virtual group is currently following a temporary GTN
 *   engagement-overlay route.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL
 */

params ["_groupData"];

((_groupData get "pathSource") find "GTN_ENGAGE") == 0
