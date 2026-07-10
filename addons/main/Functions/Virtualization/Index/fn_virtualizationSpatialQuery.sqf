/*
 * Function: FLO_fnc_virtualizationSpatialQuery
 */

params ["_position"];

private _cellKey = [_position] call FLO_fnc_virtualizationSpatialGetCellKey;
((call FLO_fnc_virtualizationGetSpatialState) get "grid") getOrDefault [_cellKey, []]
