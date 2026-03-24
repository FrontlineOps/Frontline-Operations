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
    ["_groupType", "", [""]]
];

private _createdUnit = objNull;
private _spawnPools = [_side] call FLO_fnc_virtualizationGetSpawnPools;
private _poolUnits = _spawnPools get "units";
private _sideKey = _spawnPools get "sideKey";

// Determine if this is a vehicle or infantry based on config
private _isVehicle = getNumber (configFile >> "CfgVehicles" >> _unitType >> "isVehicle") == 1
    && !(_unitType isKindOf "Man")
    || {_unitType isKindOf "LandVehicle"}
    || {_unitType isKindOf "Air"}
    || {_unitType isKindOf "Ship"};

// Handle based on groupType and unit class
switch (true) do {
    case (_unitType isKindOf "Air"): {
        private _spawnHeight = if (_unitType isKindOf "Plane") then {500} else {100};
        private _spawnPos = [_position select 0, _position select 1, _spawnHeight];
        private _crewType = [_unitType, _poolUnits, _sideKey, _groupType] call FLO_fnc_virtualizationResolveCrewType;
        _createdUnit = [_realGroup, _unitType, _spawnPos, _crewType, true] call FLO_fnc_virtualizationCreateCrewedVehicle;
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

// Distribute intel items to non-civilian units (not civilians)
if !(_groupType isEqualTo "civilian") then {
    if (!isNull _createdUnit && {(_createdUnit isKindOf "Man")}) then {
        if (random 1 < 0.4) then {
            private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
            _createdUnit addItem selectRandom _intelItems;
        };
    };
};

// Return the created unit/vehicle
_createdUnit
