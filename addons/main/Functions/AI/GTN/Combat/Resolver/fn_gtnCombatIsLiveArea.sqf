/*
 * Function: FLO_fnc_gtnCombatIsLiveArea
 * Author: Frontline Operations Development Group
 * Description:
 *   Determines whether a combat zone is inside the shared virtualization
 *   activation bubble and should hand combat off to live AI.
 *
 * Arguments:
 *   0: Zone position <ARRAY>
 *   1: Live area radius <NUMBER>
 *
 * Return Value:
 *   Live handoff required <BOOL>
 */

params ["_zonePos", "_radius"];

[_zonePos, _radius] call FLO_fnc_virtualizationIsPositionWithinActivationRange
