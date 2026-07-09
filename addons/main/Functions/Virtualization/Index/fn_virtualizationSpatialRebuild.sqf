/*
 * Function: FLO_fnc_virtualizationSpatialRebuild
 */

if (isNil "FLO_virtualGroups") exitWith { false };

[FLO_VirtSpatial get "cellSize"] call FLO_fnc_virtualizationSpatialInit;

private _groups = FLO_virtualGroups get "_groups";
{
    [_x, _y get "position", _y get "side"] call FLO_fnc_virtualizationSpatialAdd;
} forEach _groups;

["VIRTUALIZATION", 3, format ["Spatial index rebuilt: %1 groups", count keys _groups]] call FLO_fnc_log;

true
