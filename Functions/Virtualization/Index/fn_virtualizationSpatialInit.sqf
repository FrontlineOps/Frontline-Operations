/*
 * Function: FLO_fnc_virtualizationSpatialInit
 */

params [["_cellSize", 500, [0]]];

FLO_VirtSpatial = [_cellSize] call FLO_fnc_virtualizationCreateSpatialState;

["VIRTUALIZATION", 3, format ["Spatial index initialized (cell size: %1m)", _cellSize]] call FLO_fnc_log;

true
