/*
 * Function: FLO_fnc_virtualizationRemoveEventHandlers
 */

params ["_handlers"];

{
    [_x, _y] call CBA_fnc_removeEventHandler;
} forEach _handlers;

true
