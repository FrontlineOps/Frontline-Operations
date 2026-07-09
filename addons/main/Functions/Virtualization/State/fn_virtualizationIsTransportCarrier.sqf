/*
 * Function: FLO_fnc_virtualizationIsTransportCarrier
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether a virtual group is acting as a transport carrier.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the group is a transport carrier
 */

params ["_groupData"];

(_groupData get "transportRole") || { _groupData get "isTransport" }

