/*
 * Function: FLO_fnc_activateSavedVirtualGroup
 * Author: Frontline Operations Development Group
 * Description:
 * Creates a unit or vehicle for a virtual group with the saved composition
 *
 * Arguments:
 * 0: Real Group <GROUP> - The group to add the unit to
 * 1: Unit Type <STRING> - Classname of the unit to create
 * 2: Position <ARRAY> - Position [x,y,z] to create the unit at
 * 3: Side <SIDE> - Side of the unit (east, west, independent)
 * 4: Group Type <STRING> - Type of group ("infantry", "mechanized", etc.) for specialized settings
 *
 * Return Value:
 * Created Unit <OBJECT>
 */

params [
    ["_realGroup", grpNull, [grpNull]],
    ["_unitType", "", [""]],
    ["_position", [0,0,0], [[]]],
    ["_side", east, [east]],
    ["_groupType", "", [""]],
    ["_spawnParkedHelicopter", false, [false]]
];

private _createdUnit = objNull;
private _spawnPools = [_side] call FLO_fnc_virtualizationGetSpawnPools;
private _poolUnits = _spawnPools get "units";
private _sideKey = _spawnPools get "sideKey";

if (isNull _realGroup) exitWith {
    ["VIRTUALIZATION", 1, format [
        "Refusing saved activation of %1 because target group is null",
        _unitType
    ]] call FLO_fnc_log;
    objNull
};

// Determine if this is a vehicle or infantry based on config
private _isVehicle = getNumber (configFile >> "CfgVehicles" >> _unitType >> "isVehicle") == 1
    && !(_unitType isKindOf "Man")
    || {_unitType isKindOf "LandVehicle"}
    || {_unitType isKindOf "Air"}
    || {_unitType isKindOf "Ship"};

// Handle based on groupType and unit class
switch (true) do {
    case (_unitType isKindOf "Air"): {
        private _spawnParked = _spawnParkedHelicopter && { _unitType isKindOf "Helicopter" };
        private _spawnHeight = if (_unitType isKindOf "Plane") then {500} else {100};
        private _spawnPos = if (_spawnParked) then { _position } else { [_position select 0, _position select 1, _spawnHeight] };
        private _crewType = [_unitType, _poolUnits, _sideKey, _groupType] call FLO_fnc_virtualizationResolveCrewType;
        _createdUnit = [_realGroup, _unitType, _spawnPos, _crewType, !_spawnParked] call FLO_fnc_virtualizationCreateCrewedVehicle;
    };

    case (_isVehicle): {
        private _spawnPos = [
            format ["saved_%1", _groupType],
            _position,
            10,
            150,
            10,
            0.2,
            200,
            "saved composition vehicle"
        ] call FLO_fnc_virtualizationResolveGroundSpawnPos;
        private _crewType = [_unitType, _poolUnits, _sideKey, _groupType] call FLO_fnc_virtualizationResolveCrewType;
        _createdUnit = [_realGroup, _unitType, _spawnPos, _crewType] call FLO_fnc_virtualizationCreateCrewedVehicle;
    };

    default {
        private _spawnPos = [_position, 2, 25, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
        _createdUnit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
    };
};

// Return the created unit/vehicle
_createdUnit
