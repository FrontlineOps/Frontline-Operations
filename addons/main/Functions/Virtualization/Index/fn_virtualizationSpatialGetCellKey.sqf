/*
 * Function: FLO_fnc_virtualizationSpatialGetCellKey
 */

params ["_pos"];

private _cellSize = FLO_VirtSpatial get "cellSize";
private _cellX = floor ((_pos select 0) / _cellSize);
private _cellY = floor ((_pos select 1) / _cellSize);

format ["%1_%2", _cellX, _cellY]
