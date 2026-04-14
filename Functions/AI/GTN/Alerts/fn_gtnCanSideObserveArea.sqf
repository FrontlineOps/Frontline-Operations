/*
 * Function: FLO_fnc_gtnCanSideObserveArea
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether the provided side has a plausible local observer near the
 *   area. This is used to gate transient GTN alerts so they reflect reported
 *   battlefield information instead of commander intent.
 *
 * Arguments:
 *   0: Position <ARRAY>
 *   1: Radius <NUMBER>
 *   2: Observing side <SIDE>
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_position", [0, 0, 0], [[]], [3]],
    ["_radius", 0, [0]],
    ["_observingSide", sideUnknown]
];

if !(_observingSide in [east, west]) exitWith { false };

if (_radius < 1) then {
    _radius = 1;
};

private _playersNear = {
    alive _x &&
    {side group _x == _observingSide} &&
    {(getPosATL _x) distance2D _position <= _radius}
} count allPlayers;
if (_playersNear > 0) exitWith { true };

private _groups = FLO_virtualGroups get "_groups";
private _nearGroupIds = ["queryRadius", [_position, _radius, _observingSide, true]] call FLO_fnc_virtualizationSpatialIndex;

(_nearGroupIds findIf {
    private _groupData = _groups get _x;
    (_groupData get "isActive") && {(_groupData get "side") == _observingSide}
}) >= 0
