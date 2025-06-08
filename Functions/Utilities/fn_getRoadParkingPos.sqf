/*
 * Function: FLO_fnc_getRoadParkingPos
 * Author: Frontline Operations Development Group
 * Description:
 * Finds a nearby road segment around a position and returns a parking position
 * aligned with that road. If no roads are found within the search radius the
 * original position is returned.
 *
 * Arguments:
 * 0: Position <ARRAY> - Base position to search around
 * 1: Search Radius <NUMBER> - (Optional, default: 200) Radius to search for roads
 * 2: Spacing <NUMBER> - (Optional, default: 10) Distance from the road centre
 *
 * Return Value:
 * Array - [Parking Position <ARRAY>, Direction <NUMBER>]
 *
 * Example:
 * [_pos] call FLO_fnc_getRoadParkingPos;
 */

params [
    ["_position", [0,0,0], [[]]],
    ["_radius", 200, [0]],
    ["_spacing", 10, [0]]
];

private _roads = _position nearRoads _radius;
if (count _roads isEqualTo 0) exitWith { [_position, random 360] };

private _road = selectRandom _roads;
private _base = getPos _road;
private _dir = random 360;
private _cons = roadsConnectedTo _road;
if (count _cons > 0) then {
    _dir = _road getDir (_cons select 0);
};

private _parkingPos = [
    (_base select 0) + (sin _dir) * _spacing,
    (_base select 1) + (cos _dir) * _spacing,
    _base select 2
];

[_parkingPos, _dir]
