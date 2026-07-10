/*
 * Function: FLO_fnc_transportCarrierBlocksDeactivation
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether a transport carrier must stay active outside activation
 *   range because it is in the middle of a staged live unload.
 *
 * Arguments:
 *   0: Carrier group data <HASHMAP>
 *
 * Return Value:
 *   BOOL - True when deactivation should still be blocked
 */

params [["_groupData", createHashMap, [createHashMap]]];

if !([_groupData] call FLO_fnc_virtualizationIsTransportCarrier) exitWith { false };

_groupData get "transportUnloadCommandIssued"
