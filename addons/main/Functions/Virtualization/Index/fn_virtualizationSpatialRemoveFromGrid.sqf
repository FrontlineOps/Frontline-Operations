/*
 * Function: FLO_fnc_virtualizationSpatialRemoveFromGrid
 */

params ["_grid", "_cellKey", "_groupId"];

private _cell = _grid getOrDefault [_cellKey, []];
_cell = _cell - [_groupId];

if (_cell isEqualTo []) then {
    _grid deleteAt _cellKey;
} else {
    _grid set [_cellKey, _cell];
};

true
