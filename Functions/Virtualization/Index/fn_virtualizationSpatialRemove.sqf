/*
 * Function: FLO_fnc_virtualizationSpatialRemove
 */

params ["_groupId"];

private _groupMeta = FLO_VirtSpatial get "groupMeta";
private _meta = _groupMeta get _groupId;
_meta params [["_cellKey", ""], ["_sideKey", "UNKNOWN"]];

private _grid = FLO_VirtSpatial get "grid";
[_grid, _cellKey, _groupId] call FLO_fnc_virtualizationSpatialRemoveFromGrid;

private _gridBySide = FLO_VirtSpatial get "gridBySide";
private _sideGrid = _gridBySide get _sideKey;
[_sideGrid, _cellKey, _groupId] call FLO_fnc_virtualizationSpatialRemoveFromGrid;

_groupMeta deleteAt _groupId;

true
