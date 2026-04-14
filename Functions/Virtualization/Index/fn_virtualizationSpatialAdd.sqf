/*
 * Function: FLO_fnc_virtualizationSpatialAdd
 */

params ["_groupId", "_position", ["_side", nil]];

private _cellKey = [_position] call FLO_fnc_virtualizationSpatialGetCellKey;
private _grid = FLO_VirtSpatial get "grid";
private _groupMeta = FLO_VirtSpatial get "groupMeta";
private _sideKey = [_side] call FLO_fnc_virtualizationSpatialGetSideKey;
private _gridBySide = FLO_VirtSpatial get "gridBySide";
private _sideGrid = _gridBySide get _sideKey;

private _cell = _grid getOrDefault [_cellKey, []];
if !(_groupId in _cell) then {
    _cell pushBack _groupId;
    _grid set [_cellKey, _cell];
};

private _sideCell = _sideGrid getOrDefault [_cellKey, []];
if !(_groupId in _sideCell) then {
    _sideCell pushBack _groupId;
    _sideGrid set [_cellKey, _sideCell];
};

_groupMeta set [_groupId, [_cellKey, _sideKey]];

true
