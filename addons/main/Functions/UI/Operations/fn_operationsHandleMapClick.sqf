/*
 * Function: FLO_fnc_operationsHandleMapClick
 * Description:
 *   Selects the nearest visible objective marker on a native map click.
 */

params ["_map", "_button", "_mouseX", "_mouseY"];

if (_button != 0) exitWith { false };

private _selectedId = "";
private _bestDistance = 0.014;
{
    private _screenPosition = _map ctrlMapWorldToScreen (_x select 1);
    if (_screenPosition isEqualTo []) then { continue };

    private _distance = _screenPosition distance2D [_mouseX, _mouseY];
    if (_distance < _bestDistance) then {
        _bestDistance = _distance;
        _selectedId = _x select 0;
    };
} forEach FLO_OperationsMapDrawData;

if (_selectedId == "") exitWith { false };
[_selectedId, false] call FLO_fnc_operationsSelectObjective
