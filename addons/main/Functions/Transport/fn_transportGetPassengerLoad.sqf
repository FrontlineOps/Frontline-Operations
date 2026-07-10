/*
 * Function: FLO_fnc_transportGetPassengerLoad
 */

params ["_transportData"];

private _attachedGroups = [_transportData] call FLO_fnc_virtualizationGetTransportPassengers;
private _load = 0;

{
    private _passengerData = [_x] call FLO_fnc_transportGetTrackedGroup;
    _load = _load + (_passengerData get "unitCount");
} forEach _attachedGroups;

_load
