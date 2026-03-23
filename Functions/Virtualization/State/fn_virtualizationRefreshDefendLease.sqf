/*
 * Function: FLO_fnc_virtualizationRefreshDefendLease
 * Author: Frontline Operations Development Group
 * Description:
 *   Refreshes the defend lease timestamps for a commander defend order.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Lease issued at <NUMBER>
 * 2: Lease until <NUMBER>
 *
 * Return Value:
 * BOOL - True when the lease was refreshed
 */

params ["_groupData", "_leaseIssuedAt", "_leaseUntil"];

_groupData set ["defendLeaseIssuedAt", _leaseIssuedAt];
_groupData set ["defendLeaseUntil", _leaseUntil];

true
