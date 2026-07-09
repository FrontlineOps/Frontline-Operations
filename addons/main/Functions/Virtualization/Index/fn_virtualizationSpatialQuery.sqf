/*
 * Function: FLO_fnc_virtualizationSpatialQuery
 */

params ["_position"];

private _cellKey = [_position] call FLO_fnc_virtualizationSpatialGetCellKey;
(FLO_VirtSpatial get "grid") getOrDefault [_cellKey, []]
