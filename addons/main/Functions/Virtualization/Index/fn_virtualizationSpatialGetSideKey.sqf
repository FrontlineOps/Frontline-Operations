/*
 * Function: FLO_fnc_virtualizationSpatialGetSideKey
 */

params [["_side", nil]];

if (isNil "_side") exitWith { "" };
[_side] call FLO_fnc_sideKey
