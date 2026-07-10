/*
 * Function: FLO_fnc_virtualizationSpatialGetCellsInRadius
 */

params ["_pos", "_radius"];

private _cellSize = (call FLO_fnc_virtualizationGetSpatialState) get "cellSize";
private _centerX = floor ((_pos select 0) / _cellSize);
private _centerY = floor ((_pos select 1) / _cellSize);
private _cellRadius = ceil (_radius / _cellSize);
private _cells = [];

for "_x" from (_centerX - _cellRadius) to (_centerX + _cellRadius) do {
    for "_y" from (_centerY - _cellRadius) to (_centerY + _cellRadius) do {
        _cells pushBack format ["%1_%2", _x, _y];
    };
};

_cells
