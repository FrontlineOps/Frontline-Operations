/*
 * Function: FLO_fnc_virtualizationSpawnFromComposition
 */

params ["_side", "_groupType", "_position", "_comp"];

private _realGroup = createGroup [_side, true];
{
    [_realGroup, _x, _position, _side, _groupType] call FLO_fnc_activateSavedVirtualGroup;
} forEach _comp;

_realGroup
