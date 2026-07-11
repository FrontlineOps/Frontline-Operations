/*
 * Function: FLO_fnc_virtualizationSetTransportPassengers
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the canonical passenger manifest for a transport group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Attached passenger group ids <ARRAY>
 *
 * Return Value:
 * BOOL - True when the manifest was applied
 */

params ["_groupData", "_attachedGroups"];

_groupData set ["attachedGroups", _attachedGroups];
_groupData set ["isTransport", _attachedGroups isNotEqualTo []];

true

