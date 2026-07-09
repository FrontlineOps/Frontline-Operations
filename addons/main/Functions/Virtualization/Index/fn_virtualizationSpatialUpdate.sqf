/*
 * Function: FLO_fnc_virtualizationSpatialUpdate
 */

params ["_groupId", "_newPosition", ["_side", nil]];

private _groupMeta = FLO_VirtSpatial get "groupMeta";
private _meta = _groupMeta get _groupId;
_meta params [["_oldCellKey", ""], ["_oldSideKey", "UNKNOWN"]];
private _newCellKey = [_newPosition] call FLO_fnc_virtualizationSpatialGetCellKey;
private _newSideKey = [_side] call FLO_fnc_virtualizationSpatialGetSideKey;

if (_oldCellKey != _newCellKey || {_oldSideKey != _newSideKey}) then {
    [_groupId] call FLO_fnc_virtualizationSpatialRemove;
    [_groupId, _newPosition, _side] call FLO_fnc_virtualizationSpatialAdd;
};

true
