/**
 * Function: FLO_fnc_addIntelServer
 * 
 * Description:
 * Server entry point for recovered battlefield intel items.
 *
 * Parameters:
 * _gridPos - position in grid format
 * _itemClass - recovered intel item classname
 *
 * Returns:
 * nothing
 *
 * Example:
 * [] call FLO_fnc_addIntelServer;
 */
params [
    ["_gridPos", "", [""]],
    ["_itemClass", "", [""]]
];

if !(isServer) exitwith {};

private _playerSide = FLO_ActivePlayerSide;
if !(_playerSide in [east, west]) exitWith {
    ["INTEL", 2, format ["Ignored intel pickup at %1 because active player side is not locked", _gridPos]] call FLO_fnc_log;
};

[_playerSide, _itemClass, _gridPos] call FLO_fnc_gtnRevealIntelPickup;
