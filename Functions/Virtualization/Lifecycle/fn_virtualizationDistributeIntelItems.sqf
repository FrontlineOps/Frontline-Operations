/*
 * Function: FLO_fnc_virtualizationDistributeIntelItems
 */

params ["_groupType", "_realGroup"];

if (_groupType in ["civilian", "civilianVehicle", "civ_pedestrian", "civ_building", "civ_car"]) exitWith { false };

private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
private _units = (units _realGroup) select { alive _x && {_x isKindOf "Man"} };
if ((count _units) == 0) exitWith { false };
private _carrierChance = 0.5;
private _assignedCount = 0;
private _carrierCandidates = [];

{
    if (random 1 < _carrierChance) then {
        _carrierCandidates pushBack _x;
    };
} forEach _units;

if ((count _carrierCandidates) == 0) then {
    _carrierCandidates pushBack (selectRandom _units);
};

{
    if ([_x, selectRandom _intelItems] call FLO_fnc_virtualizationAssignIntelItem) then {
        _assignedCount = _assignedCount + 1;
    };
} forEach _carrierCandidates;

if (_assignedCount == 0) then {
    private _vehicles = [];
    {
        private _veh = vehicle _x;
        if (_veh != _x) then {
            _vehicles pushBackUnique _veh;
        };
    } forEach _units;

    if ((count _vehicles) > 0) then {
        (selectRandom _vehicles) addItemCargoGlobal [selectRandom _intelItems, 1];
        _assignedCount = 1;
    };
};

_assignedCount > 0
