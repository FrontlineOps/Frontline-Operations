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

// Determine if this is a vehicle or infantry based on config
private _isVehicle = getNumber (configFile >> "CfgVehicles" >> _unitType >> "isVehicle") == 1
    && !(_unitType isKindOf "Man")
    || {_unitType isKindOf "LandVehicle"}
    || {_unitType isKindOf "Air"}
    || {_unitType isKindOf "Ship"};


// Handle based on groupType and unit class
switch (true) do {
     // Aircraft (direct spawn)
    case (_unitType isKindOf "Air"): {
        // Find height
        private _spawnHeight = if (_unitType isKindOf "Plane") then {500} else {100};
        private _spawnPos = [_position select 0, _position select 1, _spawnHeight];
        
        // Direct Create + Crew
        private _veh = createVehicle [_unitType, _spawnPos, [], 0, "FLY"];
        
        // Manual Crew
        private _crewType = getText (configFile >> "CfgVehicles" >> _unitType >> "crew");
        if (_crewType == "") then { _crewType = selectRandom East_Units; };

        // Driver
        private _driver = _realGroup createUnit [_crewType, [0,0,0], [], 0, "NONE"];
        _driver moveInDriver _veh;
        
        // Turrets
        {
           private _gunner = _realGroup createUnit [_crewType, [0,0,0], [], 0, "NONE"];
           _gunner moveInTurret [_veh, _x];
        } forEach (allTurrets [_veh, false]); 
                _createdUnit = _veh;
    };

    // Ground vehicles (direct spawn)
    case (_isVehicle): {
        private _spawnPos = [_position, 10, 150, 10, 0, 0.2, 0] call BIS_fnc_findSafePos;
        
        // Direct Create + Manual Crew
        private _veh = createVehicle [_unitType, _spawnPos, [], 0, "NONE"];
        
        // Ground properly
        _veh setPos [getPos _veh select 0, getPos _veh select 1, 0];
        _veh setVectorUp [0,0,1];

        // Create Crew manually (Fixes 112/116 errors)
        private _crewType = getText (configFile >> "CfgVehicles" >> _unitType >> "crew");
        if (_crewType == "") then { _crewType = selectRandom East_Units; };

        // Driver
        private _driver = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
        _driver moveInDriver _veh;
        
        // Turrets
        {
           private _gunner = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
           _gunner moveInTurret [_veh, _x];
        } forEach (allTurrets [_veh, false]);

        _createdUnit = _veh;
    };

    // Infantry (Direct Spawn)
    default {
        private _spawnPos = [_position, 2, 25, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
        
        // Direct createUnit into the real group
        _createdUnit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
    };
};

// Distribute intel items to non-civilian units (not civilians)
if !(_groupType isEqualTo "civilian") then {
    if (!isNull _createdUnit && {(_createdUnit isKindOf "Man")}) then {
        if (random 1 < 0.3) then {
            private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
            _createdUnit addItem selectRandom _intelItems;
        };
    };
};

// Return the created unit/vehicle
_createdUnit