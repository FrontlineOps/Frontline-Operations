/*
 * Function: FLO_fnc_virtualizationSpatialInit
 */

params [["_cellSize", 500, [0]]];

private _registry = call FLO_fnc_virtualizationRequireRegistry;
_registry set [
    "spatial",
    [_cellSize] call FLO_fnc_virtualizationCreateSpatialState
];

["VIRTUALIZATION", 3, format ["Spatial index initialized (cell size: %1m)", _cellSize]] call FLO_fnc_log;

true
