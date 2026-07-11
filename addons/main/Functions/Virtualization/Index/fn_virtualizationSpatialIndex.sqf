/*
 * Function: FLO_fnc_virtualizationSpatialIndex
 * Author: Frontline Operations Development Group
 * Description:
 *   Spatial index dispatcher for virtualization queries and mutations.
 */

params [["_mode", "init", [""]], ["_args", [], [[]]]];

if (isNil "FLO_VirtualForceRegistry") then {
    throw "Virtualization spatial index used before registry initialization";
};
if ((keys ((call FLO_fnc_virtualizationRequireRegistry) get "spatial")) isEqualTo []) then {
    [500] call FLO_fnc_virtualizationSpatialInit;
};

switch (toLower _mode) do {
    case "init": {
        _args params [["_cellSize", 500, [0]]];
        [_cellSize] call FLO_fnc_virtualizationSpatialInit
    };
    case "add": {
        _args params ["_groupId", "_position", ["_side", nil]];
        [_groupId, _position, _side] call FLO_fnc_virtualizationSpatialAdd
    };
    case "remove": {
        _args params ["_groupId"];
        [_groupId] call FLO_fnc_virtualizationSpatialRemove
    };
    case "update": {
        _args params ["_groupId", "_newPosition", ["_side", nil]];
        [_groupId, _newPosition, _side] call FLO_fnc_virtualizationSpatialUpdate
    };
    case "query": {
        _args params ["_position"];
        [_position] call FLO_fnc_virtualizationSpatialQuery
    };
    case "queryradius": {
        _args params ["_position", "_radius", ["_filterSide", nil], ["_exact", false]];
        [_position, _radius, _filterSide, _exact] call FLO_fnc_virtualizationSpatialQueryRadius
    };
    case "rebuild": {
        call FLO_fnc_virtualizationSpatialRebuild
    };
    default { nil };
}
