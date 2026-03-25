/*
 * Function: FLO_fnc_virtualizationIsPositionWithinActivationRange
 */

params ["_position", ["_radius", -1, [0]]];

if (_radius < 0) then {
    _radius = FLO_virtualGroups get "_activationDistance";
};

if ((FLO_VirtUpdate get "lastPlayerCacheTime") <= 0) then {
    call FLO_fnc_virtualizationCachePlayers;
};

([_position] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance) <= _radius
