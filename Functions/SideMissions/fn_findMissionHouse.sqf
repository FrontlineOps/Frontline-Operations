/*
 * Function: FLO_fnc_findMissionHouse
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects a random building suitable for side missions near a center point.
 * Parameters:
 *   0: Center object or position (default: player)
 *   1: Search radius (NUMBER, default: 7000)
 *   2: Minimum distance from center (NUMBER, default: 500)
 * Returns: OBJECT - selected building or objNull if none found
 */

params [ ["_center", player], ["_radius", 7000], ["_min", 500] ];

private _centerPos = if (typeName _center == "OBJECT") then { position _center } else { _center };

private _houses = nearestObjects [_centerPos, ["House"], _radius] select {
    count (_x buildingPos -1) > 2 && { _centerPos distance _x > _min }
};

if (_houses isEqualTo []) exitWith { objNull };

selectRandom _houses
