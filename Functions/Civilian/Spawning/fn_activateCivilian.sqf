/*
 * Function: FLO_fnc_activateCivilian
 * Author: Frontline Operations Development Group  
 * Description:
 *   Handles activation of civilian virtual groups. Called by FLO_fnc_activateVirtualGroup
 *   when a civilian group type is detected. All civilian-specific spawning logic
 *   lives in this file, keeping virtualization clean.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group Data <HASHMAP>
 *   2: Position <ARRAY>
 *
 * Returns:
 *   Group <GROUP> - The created real group
 */

params ["_groupId", "_groupData", "_position"];

if (!isServer) exitWith { grpNull };

private _groupType = _groupData get "groupType";
private _unitCount = _groupData get "unitCount";
private _spawnClass = _groupData get "spawnClass";
private _realGroup = grpNull;

["CIVILIAN", 3, format["Activating civilian group %1 (type: %2)", _groupId, _groupType]] call FLO_fnc_log;

switch (_groupType) do {
    // ========================================================================
    // CIVILIAN PEDESTRIANS / BUILDING OCCUPANTS
    // ========================================================================
    case "civilian";
    case "civ_pedestrian";
    case "civ_building": {
        _realGroup = createGroup [civilian, true];
        private _civUnits = [];
        private _homeObjective = _groupData get "homeObjective";
        
        if (_homeObjective isEqualTo "civ_building" || _groupType isEqualTo "civ_building") then {
            // Building civilians spawn at exact stored position
            for "_i" from 1 to _unitCount do {
                private _unitType = if (_spawnClass != "") then { _spawnClass } else { selectRandom CivMenArray };
                private _unit = _realGroup createUnit [_unitType, _position, [], 0, "NONE"];
                _civUnits pushBack _unit;
            };
        } else {
            // Pedestrians spawn nearby with safe positioning
            for "_i" from 1 to _unitCount do {
                private _unitType = if (_spawnClass != "") then { _spawnClass } else { selectRandom CivMenArray };
                private _spawnPos = [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
                private _unit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
                _civUnits pushBack _unit;
            };
        };
        
        // Apply behavior from Civilian Manager
        [_civUnits] call FLO_fnc_civilianActions;
    };

    // ========================================================================
    // CIVILIAN VEHICLES
    // ========================================================================
    case "civilianVehicle";
    case "civ_car": {
        _realGroup = createGroup [civilian, true];
        private _vehicleType = selectRandom CivVehArray;

        // Find safe position - prefer roads
        private _spawnPos = _position;
        private _roads = _position nearRoads 100;
        if (count _roads > 0) then {
            private _road = selectRandom _roads;
            _spawnPos = getPos _road;
        } else {
            _spawnPos = [_position, 5, 100, 8, 0, 0.3, 0] call BIS_fnc_findSafePos;
        };

        // Validate spawn position
        private _spawnValid = (_spawnPos isEqualType []) && {count _spawnPos >= 2} &&
            {_spawnPos distance2D _position <= 150} &&
            {(_spawnPos select 0) > 100 || (_spawnPos select 1) > 100};
        if (!_spawnValid) then { _spawnPos = _position; };

        // Create vehicle
        private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, "CAN_COLLIDE"];
        _vehicle setPos [_spawnPos select 0, _spawnPos select 1, 0];
        _vehicle setVectorUp [0,0,1];
        _vehicle setDir (random 360);
        _vehicle lock 0;
        _vehicle setFuel 1;
        _vehicle setDamage 0;
        _vehicle setVehicleLock "UNLOCKED";

        // Fill driver
        private _crewPositions = fullCrew [_vehicle, "", true];
        private _driverPos = _crewPositions select {(_x select 1) == "driver"};
        private _cargoPos = _crewPositions select {(_x select 1) == "cargo"};

        if (count _driverPos > 0) then {
            private _unitType = if (_spawnClass != "") then { _spawnClass } else { selectRandom CivMenArray };
            private _unit = _realGroup createUnit [_unitType, [0,0,0], [], 0, "NONE"];
            _unit moveInDriver _vehicle;
        };

        // Fill 0-2 passengers
        private _numPassengers = (count _cargoPos) min (floor random 3);
        for "_i" from 0 to (_numPassengers - 1) do {
            if (_i < count _cargoPos) then {
                private _unitType = if (_spawnClass != "") then { _spawnClass } else { selectRandom CivMenArray };
                private _unit = _realGroup createUnit [_unitType, [0,0,0], [], 0, "NONE"];
                _unit moveInCargo _vehicle;
            };
        };
    };

    default {
        ["CIVILIAN", 1, format["Unknown civilian group type: %1", _groupType]] call FLO_fnc_log;
    };
};

// Store group reference
if (!isNull _realGroup) then {
    _groupData set ["realGroup", _realGroup];
    _groupData set ["isActive", true];
};

_realGroup
