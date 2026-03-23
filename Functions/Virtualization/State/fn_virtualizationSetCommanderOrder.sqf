/*
 * Function: FLO_fnc_virtualizationSetCommanderOrder
 * Author: Frontline Operations Development Group
 * Description:
 *   Sets canonical GTN commander intent on a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Commander order <STRING>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_order"];

_groupData set ["commanderOrder", _order];

true
