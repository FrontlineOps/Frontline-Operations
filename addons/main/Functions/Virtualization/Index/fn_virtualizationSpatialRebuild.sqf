/*
 * Function: FLO_fnc_virtualizationSpatialRebuild
 */

if (isNil "FLO_VirtualForceRegistry") exitWith { false };

private _cellSize = (call FLO_fnc_virtualizationGetSpatialState) get "cellSize";
[_cellSize] call FLO_fnc_virtualizationSpatialInit;

private _groups = call FLO_fnc_virtualizationGetGroupMap;
{
    [_x, _y get "position", _y get "side"] call FLO_fnc_virtualizationSpatialAdd;
} forEach _groups;

["VIRTUALIZATION", 3, format ["Spatial index rebuilt: %1 groups", count keys _groups]] call FLO_fnc_log;

true
