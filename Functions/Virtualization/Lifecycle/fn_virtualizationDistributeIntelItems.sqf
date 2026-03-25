/*
 * Function: FLO_fnc_virtualizationDistributeIntelItems
 */

params ["_groupType", "_realGroup"];

if (_groupType in ["civilian", "civilianVehicle"]) exitWith { false };

private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
private _units = units _realGroup;
if (count _units == 0) exitWith { false };

private _selectedUnits = _units call BIS_fnc_arrayShuffle;
_selectedUnits resize (floor (count _selectedUnits / 2) max 1);

{
    if (random 1 < 0.3) then {
        _x addItem selectRandom _intelItems;
    };
} forEach _selectedUnits;

true
