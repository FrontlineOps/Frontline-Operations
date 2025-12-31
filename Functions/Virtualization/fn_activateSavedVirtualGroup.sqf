/*
 * Function: FLO_fnc_activateSavedVirtualGroup
 * Author: Frontline Operations Development Group
 * Description:
 * Creates a unit or vehicle for a virtual group with the saved composition
 *
 * Arguments:
 * 0: Real Group <GROUP> - The group to add the unit to
 * 1: Unit Type <STRING> - Class name of the unit or vehicle to create
 * 2: Position <ARRAY> - Position [x,y,z] to create the unit at
 * 3: Side <SIDE> - Side of the unit (east, west, independent)
 * 4: Group Type <STRING> - Type of group ("infantry", "mechanized", etc.) for specialized settings
 *
 * Return Value:
 * Created Unit <OBJECT>
 *
 * Example:
 * [_realGroup, "B_Soldier_F", _position, east, "infantry"] call FLO_fnc_activateSavedVirtualGroup;
 */

params [
    ["_realGroup", grpNull, [grpNull]],
    ["_unitType", "", [""]],
    ["_position", [0,0,0], [[]]],
    ["_side", east, [east]],
    ["_groupType", "", [""]]
];

// Return if invalid parameters
if (isNull _realGroup || _unitType isEqualTo "") exitWith {
    ["VIRTUALIZATION", 1, "Invalid parameters for activateSavedVirtualGroup"] call FLO_fnc_log;
    objNull
};

private _createdUnit = objNull;

// Determine if this is a vehicle or infantry based on config
private _isVehicle = getNumber (configFile >> "CfgVehicles" >> _unitType >> "isVehicle") == 1
    || {_unitType isKindOf "LandVehicle"}
    || {_unitType isKindOf "Air"}
    || {_unitType isKindOf "Ship"};

// Handle based on groupType and unit class
switch (true) do {
    // Civilian units - spawn at exact position
    case (_groupType isEqualTo "civilian"): {
        private _spawnPos = _position;
        private _tempGroup = createGroup [civilian, true];
        _createdUnit = _tempGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
        [_createdUnit] joinSilent _realGroup;
        deleteGroup _tempGroup;
    };

    // Civilian vehicles - need driver and possibly passengers
    case (_groupType isEqualTo "civilianVehicle"): {
        private _spawnPos = [_position, 5, 100, 8, 0, 0.3, 0] call BIS_fnc_findSafePos;
        private _vehicle = createVehicle [_unitType, _spawnPos, [], 0, "CAN_COLLIDE"];
        _vehicle setPos [_spawnPos select 0, _spawnPos select 1, 0];
        _vehicle setVectorUp [0,0,1];
        _vehicle setDir (random 360);
        _vehicle lock 0;
        _vehicle setFuel 1;
        _vehicle setDamage 0;
        _vehicle setVehicleLock "UNLOCKED";

        // Fill driver and optionally passengers
        private _crewPositions = fullCrew [_vehicle, "", true];
        private _driverPos = _crewPositions select {(_x select 1) == "driver"};
        private _cargoPos = _crewPositions select {(_x select 1) == "cargo"};

        // Always fill driver
        if (count _driverPos > 0 && !isNil "CivMenArray") then {
            private _driverType = selectRandom CivMenArray;
            private _driver = _realGroup createUnit [_driverType, [0,0,0], [], 0, "NONE"];
            _driver moveInDriver _vehicle;
        };

        // Randomly fill 0-2 passengers if available
        if (!isNil "CivMenArray") then {
            private _numPassengers = (count _cargoPos) min (floor random 3);
            for "_i" from 0 to (_numPassengers - 1) do {
                if (_i < count _cargoPos) then {
                    private _passengerType = selectRandom CivMenArray;
                    private _unit = _realGroup createUnit [_passengerType, [0,0,0], [], 0, "NONE"];
                    _unit moveInCargo _vehicle;
                };
            };
        };

        _createdUnit = _vehicle;
    };

    // Aircraft (check by inheritance, not string comparison)
    case (_unitType isKindOf "Air"): {
        private _spawnHeight = if (_unitType isKindOf "Plane") then {500} else {100};
        private _spawnPos = [_position select 0, _position select 1, _spawnHeight];

        private _veh = [_spawnPos, random 360, _unitType, _side] call BIS_fnc_spawnVehicle;
        _createdUnit = _veh select 0;
        private _vehGroup = _veh select 2;

        {[_x] joinSilent _realGroup} forEach units _vehGroup;
        deleteGroup _vehGroup;
    };

    // Ground vehicles (check by inheritance)
    case (_isVehicle): {
        private _spawnPos = [_position, 10, 150, 10, 0, 0.2, 0] call BIS_fnc_findSafePos;

        private _veh = [_spawnPos, random 360, _unitType, _side] call BIS_fnc_spawnVehicle;
        _createdUnit = _veh select 0;
        private _vehGroup = _veh select 2;

        // Ground the vehicle properly
        _createdUnit setPos [getPos _createdUnit select 0, getPos _createdUnit select 1, 0];
        _createdUnit setVectorUp [0,0,1];

        {[_x] joinSilent _realGroup} forEach units _vehGroup;
        deleteGroup _vehGroup;
    };

    // Infantry (default for Man units)
    default {
        private _spawnPos = [_position, 2, 25, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;

        private _tempGroup = createGroup [_side, true];
        _createdUnit = _tempGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];

        [_createdUnit] joinSilent _realGroup;
        deleteGroup _tempGroup;
    };
};

// Distribute intel items to non-civilian units (not civilians)
if !(_groupType isEqualTo "civilian") then {
    if (!isNull _createdUnit && {(_createdUnit isKindOf "Man")}) then {
        if (random 1 < 0.2) then {
            private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
            _createdUnit addItem selectRandom _intelItems;
        };
    };
};

// Return the created unit/vehicle
_createdUnit 