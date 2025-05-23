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

// Handle based on unit type
switch (true) do {
    // Infantry unit
    case (_unitType isEqualTo "infantry"): {
        // Find a safe position nearby
        private _spawnPos = [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
        
        // Create unit with correct side
        private _tempGroup = createGroup [_side, true];
        _createdUnit = _tempGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
        
        // Join to the real group and delete temp group
        [_createdUnit] joinSilent _realGroup;
        deleteGroup _tempGroup;
        
        ["VIRTUALIZATION", 3, format["Created infantry unit %1 with side %2", _unitType, side _createdUnit]] call FLO_fnc_log;
    };
    
    // Helicopters and aircraft
    case (_unitType in ["helicopter", "jet", "air"]): {
        // Set appropriate spawn height based on type
        private _spawnHeight = 0;
        if (_unitType isEqualTo "jet") then { 
            _spawnHeight = 500; 
        } else { 
            _spawnHeight = 100; 
        };
        
        private _spawnPos = [_position select 0, _position select 1, _spawnHeight];
        
        // Create aircraft with crew
        private _veh = [_spawnPos, random 360, _unitType, _side] call BIS_fnc_spawnVehicle;
        private _vehicle = _veh select 0;
        _createdUnit = _vehicle; // Return the vehicle object
        private _crew = _veh select 1;
        private _vehGroup = _veh select 2;
        
        // Transfer crew to real group
        {
            [_x] joinSilent _realGroup;
        } forEach units _vehGroup;
        deleteGroup _vehGroup;
        
        ["VIRTUALIZATION", 3, format["Created aircraft %1 with side %2", _unitType, side _vehicle]] call FLO_fnc_log;
    };
    
    // Armored vehicles and APCs
    case (_unitType in ["motorized", "mechanized", "armor"]): {
        // Find safe position for vehicle (needs more space)
        private _spawnPos = [_position, 5, 50, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
        
        // Create vehicle and crew
        private _veh = [_spawnPos, random 360, _unitType, _side] call BIS_fnc_spawnVehicle;
        private _vehicle = _veh select 0;
        _createdUnit = _vehicle; // Return the vehicle object
        private _crew = _veh select 1;
        private _vehGroup = _veh select 2;
        
        // Transfer crew to real group
        {
            [_x] joinSilent _realGroup;
        } forEach units _vehGroup;
        deleteGroup _vehGroup;
        
        ["VIRTUALIZATION", 3, format["Created armored vehicle %1 with side %2", _unitType, side _vehicle]] call FLO_fnc_log;
    };
    
    // Artillery
    case (_unitType isEqualTo "artillery"): {
        // Find safe position for artillery
        private _spawnPos = [_position, 5, 50, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
        
        // Create vehicle and crew
        private _veh = [_spawnPos, random 360, _unitType, _side] call BIS_fnc_spawnVehicle;
        private _vehicle = _veh select 0;
        _createdUnit = _vehicle; // Return the vehicle object
        private _crew = _veh select 1;
        private _vehGroup = _veh select 2;
        
        // Transfer crew to real group
        {
            [_x] joinSilent _realGroup;
        } forEach units _vehGroup;
        deleteGroup _vehGroup;
        
        ["VIRTUALIZATION", 3, format["Created artillery %1 with side %2", _unitType, side _vehicle]] call FLO_fnc_log;
    };
    
    // Civilian unit (restore to exact saved position if possible)
    case (_groupType isEqualTo "civilian"): {
        // _unitType and _position are passed in as arguments (from [unitType, position] pairs)
        private _spawnPos = if (!(_position isEqualTo [0,0,0])) then {
            _position
        } else {
            [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos
        };
        private _tempGroup = createGroup [_side, true];
        _createdUnit = _tempGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
        [_createdUnit] joinSilent _realGroup;
        deleteGroup _tempGroup;
        ["VIRTUALIZATION", 3, format["Created civilian unit %1 at %2", _unitType, _spawnPos]] call FLO_fnc_log;
    };
    
    // Default case - other vehicles
    default {
        // Find safe position for vehicle
        private _spawnPos = [_position, 5, 30, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
        
        // Create vehicle and crew
        private _veh = [_spawnPos, random 360, _unitType, _side] call BIS_fnc_spawnVehicle;
        private _vehicle = _veh select 0;
        _createdUnit = _vehicle; // Return the vehicle object
        private _crew = _veh select 1;
        private _vehGroup = _veh select 2;
        
        // Transfer crew to real group
        {
            [_x] joinSilent _realGroup;
        } forEach units _vehGroup;
        deleteGroup _vehGroup;
        
        ["VIRTUALIZATION", 3, format["Created vehicle %1 with side %2", _unitType, side _vehicle]] call FLO_fnc_log;
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