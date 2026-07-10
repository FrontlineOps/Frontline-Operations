/*
 * Function: FLO_fnc_aftermathIsWreckSettled
 * Description:
 *   Prevents cleanup while a destroyed vehicle is still falling, flying,
 *   sliding, sinking through the surface, or otherwise visibly moving.
 */

params [["_wreck", objNull, [objNull]]];

if (isNull _wreck || {alive _wreck}) exitWith { false };
if !(_wreck isKindOf "LandVehicle" || {_wreck isKindOf "Air"} || {_wreck isKindOf "Ship"}) then {
    throw format ["Aftermath settlement check received unsupported object %1", typeOf _wreck];
};

private _state = FLO_AftermathCleanup;
private _maxSpeed = _state get "wreckSettleMaxSpeed";
if ((vectorMagnitude (velocity _wreck)) > _maxSpeed) exitWith { false };

private _surfaceClearance = _state get "wreckSurfaceClearance";
private _positionATL = getPosATL _wreck;
private _nearSurface = false;

if (surfaceIsWater _positionATL) then {
    _nearSurface = ((getPosASL _wreck) select 2) <= _surfaceClearance;
} else {
    _nearSurface = isTouchingGround _wreck || {(_positionATL select 2) <= _surfaceClearance};
};

_nearSurface
