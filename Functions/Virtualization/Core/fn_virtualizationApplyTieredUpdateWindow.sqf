/*
 * Function: FLO_fnc_virtualizationApplyTieredUpdateWindow
 * Description:
 *   Resolves whether the current batch should process the group and returns
 *   the nearest cached player distance. The PFH batch cadence is now the only
 *   virtualization movement throttle; there is no additional distance-tier skip.
 */

params ["_groupData"];

private _position = _groupData get "position";
private _nearestDist = [_position] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance;

[true, _nearestDist]
