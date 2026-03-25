/*
 * Function: FLO_fnc_virtualizationSetRealGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the canonical live-engine group reference for a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Real group <GROUP>
 *
 * Return Value:
 * BOOL - True when the reference was applied
 */

params ["_groupData", "_realGroup"];

_groupData set ["realGroup", _realGroup];

true

