/*
 * Function: FLO_fnc_virtualizationDistributeIntelItems
 */

params ["_groupType", "_realGroup"];

if (_groupType in ["civilian", "civilianVehicle"]) exitWith { false };

private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
private _units = units _realGroup;
if (count _units == 0) exitWith { false };
private _carrierChance = 0.5;

{
    if (!(_x isKindOf "Man")) then { continue };

    if (random 1 < _carrierChance) then {
        _x addItem selectRandom _intelItems;
    };
} forEach _units;

true
