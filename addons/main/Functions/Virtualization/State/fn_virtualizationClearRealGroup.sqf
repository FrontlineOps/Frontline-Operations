/*
 * Function: FLO_fnc_virtualizationClearRealGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the canonical live-engine group reference for a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the reference was cleared
 */

params ["_groupData"];

_groupData set ["realGroup", grpNull];
_groupData set ["activeInitialUnitCount", 0];

true

