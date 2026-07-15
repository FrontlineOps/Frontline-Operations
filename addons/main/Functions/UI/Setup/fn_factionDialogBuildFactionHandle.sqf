/*
 * Function: FLO_fnc_factionDialogBuildFactionHandle
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the mission config faction handle from setup dialog selections.
 *
 * Arguments:
 * 0: Selections <ARRAY>
 * 1: Native config side <NUMBER>
 *
 * Returns:
 * Faction handle <HASHMAP>
 */
params ["_selections", "_side"];

private _selection = (_selections apply { _x select 0 }) joinString " + ";
private _data = (_selections select 0) select 1;

private _handle = createHashMapFromArray [
    ["name", _selection],
    ["source", "custom"],
    ["side", _side]
];

if (count _selections > 1) then {
    private _factionClasses = _selections apply { (_x select 1) select [5] };
    _handle set ["source", "auto_multi"];
    _handle set ["factionClass", _factionClasses select 0];
    _handle set ["factionClasses", _factionClasses];
} else {
    if ((_data find "auto|") == 0) then {
        _handle set ["source", "auto"];
        _handle set ["factionClass", _data select [5]];
    };
};

_handle
