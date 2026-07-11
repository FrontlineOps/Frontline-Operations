/*
 * Function: FLO_fnc_virtualizationSpatialQueryRadius
 */

params ["_position", "_radius", ["_filterSide", nil], ["_exact", false]];

private _cells = [_position, _radius] call FLO_fnc_virtualizationSpatialGetCellsInRadius;
private _sideKey = [_filterSide] call FLO_fnc_virtualizationSpatialGetSideKey;
private _spatial = call FLO_fnc_virtualizationGetSpatialState;
private _grid = if (_sideKey == "") then {
    _spatial get "grid"
} else {
    (_spatial get "gridBySide") get _sideKey
};
private _result = [];

{
    private _groupIds = _grid getOrDefault [_x, []];
    _result append _groupIds;
} forEach _cells;

_result = _result arrayIntersect _result;
if !(_exact) exitWith { _result };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
_result select {
    private _gData = _groups get _x;
    (_gData get "position") distance2D _position <= _radius
}
