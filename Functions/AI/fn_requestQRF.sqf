/*
    Function: FLO_fnc_requestQRF
    
    Description:
    Requests and spawns a Quick Reaction Force based on threat level and location.
    Now requires and consumes OPFOR resources.
    
    Parameters:
    _targetPos - Position to respond to [Array or Object] - Can be position array or trigger/object
    _radius - Radius of the area to consider for threat calculation [Number]
    
    Returns:
    Array - [success (Boolean), spawnedGroups (Array)]
*/

// Check if communications are disrupted
if (COMMSDIS != 0) exitWith {
    [false, []]
};

params [
    ["_targetPos", [0,0,0], [[], objNull], [3]],
    ["_radius", 500, [0]]
];

// Convert _targetPos to position array if it's an object
_targetPos = if (_targetPos isEqualType objNull) then {getPos _targetPos} else {_targetPos};

// Resource costs for different QRF tiers
private _resourceCosts = createHashMapFromArray [
    ["Tier4", 50],  // Heavy combined arms
    ["Tier3", 35],  // Mechanized + Air support
    ["Tier2", 20],  // Mechanized/Motorized
    ["Tier1", 10]   // Light/Motorized
];

// Find nearest valid OPFOR outpost
private _opforOutpostMarkers = allMapMarkers select {
    markerType _x in ["o_installation", "o_service", "o_support"]
};

private _nearestOutpost = "";
private _nearestDistance = 1e10;

{
    private _markerPos = getMarkerPos _x;
    private _distance = _markerPos distance _targetPos;
    
    // Check if there are any players near this outpost
    private _noPlayersNear = {
        if (side _x isEqualTo west && alive _x) exitWith {1};
    } count (_markerPos nearEntities [["Man", "Car", "Tank", "Ship", "LandVehicle"], 1000]) isEqualTo 0;
    
    if (_distance < _nearestDistance && _noPlayersNear) then {
        _nearestDistance = _distance;
        _nearestOutpost = _x;
    };
} forEach _opforOutpostMarkers;

if (_nearestOutpost == "") exitWith {
    ["No valid OPFOR outpost found for QRF deployment"] remoteExec ["hint", remoteExecutedOwner];
    [false, []]
};

// Get aggression score
private _AGGRSCORE = parseNumber (markerText ((allMapMarkers select {markerColor _x == "Color6_FD_F"}) select 0));

// Calculate threat level based on radius and player presence
private _threatLevel = linearConversion [500, 2500, _radius, 0, 1, true];
private _responseParams = [_threatLevel, _AGGRSCORE] call FLO_fnc_calculateQRFResponse;
_responseParams params ["_tier", "_type"];

// Calculate total resource cost based on tier and spawn count
private _baseCost = _resourceCosts get _tier;
private _spawnCount = switch (true) do {
    case (_AGGRSCORE >= 5): { 4 };    // Low-medium aggression - reinforced platoon
    case (_AGGRSCORE >= 3): { 2 };    // Low aggression - platoon-sized
    default { 1 };                    // Minimal aggression - squad-sized
};

// Calculate total cost
private _totalCost = _baseCost * _spawnCount;

// Try to spend resources for QRF
if !(["spend", [_totalCost]] call FLO_fnc_opforResources) exitWith {
    diag_log "[FLO][QRF] Insufficient resources for QRF deployment";
    [false, []];
};

// Get spawn position
private _spawnPos = getMarkerPos _nearestOutpost;

// Select appropriate insertion method
private _insertionTypes = switch (_tier) do {
    case "Tier4": {
        selectRandom [
            ["HeliInsert", 1200],
            ["ArmorInsert", 1000],
            ["MechInsert", 800]
        ]
    };
    case "Tier3": {
        selectRandom [
            ["HeliInsert", 1000],
            ["MechInsert", 800],
            ["MotorizedInsert", 600]
        ]
    };
    case "Tier2": {
        selectRandom [
            ["MotorizedInsert", 800],
            ["HeliInsert", 600]
        ]
    };
    default {
        ["MotorizedInsert", 600]
    };
};

_insertionTypes params ["_insertType", "_approachDistance"];

// Calculate approach position
private _dir = _spawnPos getDir _targetPos;
private _approachPos = _targetPos getPos [_approachDistance, _dir - 180];
_approachPos = [_approachPos, 0, 200, 10, 0, 0.2, 0, [], [_approachPos, _approachPos]] call BIS_fnc_findSafePos;

// Helper function for vehicle and crew creation
private _fnc_createVehicleWithCrew = {
    params ["_vehType", "_spawnPos"];
    
    // Add debug logging
    //diag_log format ["[FLO][QRF] Creating vehicle of type %1 at position %2", _vehType, _spawnPos];
    
    // Find nearest road within a reasonable distance
    private _nearRoads = _spawnPos nearRoads 1500;
    private _spawnPosRoad = if (count _nearRoads > 0) then {
        private _road = selectRandom (_nearRoads select [0, (count _nearRoads) min 10]);
        getPos _road
    } else {
        // If no road found, use original position but ensure it's safe
        private _safePosParams = [_spawnPos, 0, 150, 10, 0, 0.25, 0, [], [_spawnPos, _spawnPos]];
        _spawnPos = _safePosParams call BIS_fnc_findSafePos;
        _spawnPos
    };
    
    // Add debug logging for final spawn position
    //diag_log format ["[FLO][QRF] Final vehicle spawn position (after road check): %1", _spawnPosRoad];
    
    private _veh = createVehicle [_vehType, _spawnPosRoad, [], 0, "NONE"];
    _veh setDir (_veh getDir _targetPos);
    
    private _group = createGroup [EAST, true];
    createVehicleCrew _veh;
    
    // Move crew to EAST side
    {
        [_x] joinSilent _group;
    } forEach (crew _veh);
    
    // Calculate cargo capacity (total seats minus crew seats)
    private _totalSeats = [typeOf _veh, true] call BIS_fnc_crewCount;  // Get total seats including cargo
    private _crewSeats = [typeOf _veh, false] call BIS_fnc_crewCount;  // Get crew seats only
    private _maxCargo = _totalSeats - _crewSeats;  // Calculate actual cargo capacity
    
    // Add intel to crew
    private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
    private _crewUnits = crew _veh;
    private _selectedCrew = ((_crewUnits call BIS_fnc_arrayShuffle) select [0, floor(count _crewUnits / 2)]);
    
    {
        _x addItem selectRandom _intelItems;
    } forEach _selectedCrew;
    
    // Add debug logging for created vehicle
    //diag_log format ["[FLO][QRF] Vehicle created successfully at %1 with group %2", getPos _veh, _group];
    
    [_veh, _group, _maxCargo]
};

// Helper function to distribute intel to infantry group
private _fnc_addIntelToGroup = {
    params ["_group"];
    private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
    private _groupUnits = units _group;
    private _selectedUnits = ((_groupUnits call BIS_fnc_arrayShuffle) select [0, floor(count _groupUnits / 2)]);
    
    {
        _x addItem selectRandom _intelItems;
    } forEach _selectedUnits;
};

// Calculate spawn positions in a spiral pattern with safe distances
private _spawnPositions = [];
private _baseAngle = 360 / _spawnCount;
private _minSafeDistance = 50; // Minimum distance between spawn points
private _spiralGrowth = 20;    // How much the spiral grows per point

{
    private _angle = _baseAngle * _forEachIndex;
    private _spiralDistance = _minSafeDistance + (_spiralGrowth * _forEachIndex); // Spiral growth
    private _distance = _approachDistance + _spiralDistance + (random 200 - random 100); // Add some randomness
    private _pos = _targetPos getPos [_distance, (_dir - 180) + _angle];
    
    // Find safe position with larger search radius and minimum building distance
    _pos = [_pos, 0, 300, 15, 0, 0.3, 0, [], [_pos, _pos]] call BIS_fnc_findSafePos;
    
    // Ensure minimum distance from other spawn points
    private _isSafe = true;
    {
        if (_pos distance2D _x < _minSafeDistance) then {
            _isSafe = false;
        };
    } forEach _spawnPositions;
    
    // If position isn't safe, try to find a new one
    if (!_isSafe) then {
        for "_i" from 1 to 5 do {
            _distance = _approachDistance + _spiralDistance + (random 300);
            _pos = _targetPos getPos [_distance, (_dir - 180) + _angle + (random 60 - random 60)];
            _pos = [_pos, 0, 300, 15, 0, 0.3, 0, [], [_pos, _pos]] call BIS_fnc_findSafePos;
            _isSafe = true;
            {
                if (_pos distance2D _x < _minSafeDistance) then {
                    _isSafe = false;
                };
            } forEach _spawnPositions;
            if (_isSafe) exitWith {};
        };
    };
    
    _spawnPositions pushBack _pos;
} forEach ([] call {private _arr = []; for "_i" from 1 to _spawnCount do {_arr pushBack _i}; _arr});

// Calculate total spawn delay based on force size
private _totalDelay = switch (true) do {
    case (_spawnCount >= 15): { 300 };  // 5 minutes for large forces
    case (_spawnCount >= 9): { 180 };   // 3 minutes for medium forces
    default { 120 };                    // 2 minutes for small forces
};

// Calculate delay between each spawn
private _delayPerSpawn = _totalDelay / _spawnCount;

// Function to handle delayed spawn
private _fnc_delayedSpawn = {
    params ["_spawnIndex", "_delay"];
    sleep _delay;
};

// Function to check if position is within radio coverage
private _fnc_hasRadioCoverage = {
    params ["_pos"];
    private _transmitterMarkers = allMapMarkers select { markerType _x == "loc_Transmitter" && markerColor _x == "colorBLUFOR" };
    private _hasRadio = false;
    
    {
        if ((getMarkerPos _x) distance _pos < 3500) exitWith {
            _hasRadio = true;
        };
    } forEach _transmitterMarkers;
    
    _hasRadio
};

// Initialize groups array
// Create a unique variable name for this QRF request
private _qrfVarName = format ["FLO_QRF_Groups_%1", floor random 999999];
missionNamespace setVariable [_qrfVarName, []];

// Store spawn position in a variable that will be accessible inside the spawn
private _originalSpawnPos = getMarkerPos _nearestOutpost;

// Spawn the loop to handle delays properly
[
    _spawnCount,
    _spawnPositions,
    _delayPerSpawn,
    _fnc_hasRadioCoverage,
    _AGGRSCORE,
    _targetPos,
    _originalSpawnPos,  // Pass the original spawn position
    _insertType,
    _fnc_delayedSpawn,
    _fnc_createVehicleWithCrew,
    _fnc_addIntelToGroup,
    _approachDistance,
    _dir,
    _qrfVarName
] spawn {
    params [
        "_spawnCount",
        "_spawnPositions",
        "_delayPerSpawn",
        "_fnc_hasRadioCoverage",
        "_AGGRSCORE",
        "_targetPos",
        "_spawnPos",  // Receive the spawn position
        "_insertType",
        "_fnc_delayedSpawn",
        "_fnc_createVehicleWithCrew",
        "_fnc_addIntelToGroup",
        "_approachDistance",
        "_dir",
        "_qrfVarName"
    ];

    // Add debug logging
    //diag_log format ["[FLO][QRF] Spawn Position: %1", _spawnPos];
    
    private _groups = [];
    
    // Function to set up group behavior
    private _fnc_setupGroupBehavior = {
        params ["_group", "_targetPos", "_spawnPos", "_approachDistance", "_dir", "_spawnIndex", "_totalGroups"];
        
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        
        // Calculate unique approach position
        private _sectorSize = 360 / _totalGroups;
        private _groupAngle = _sectorSize * (_spawnIndex - 1);
        private _groupDistance = _approachDistance + (random 300 - random 300);
        private _groupApproachPos = _targetPos getPos [_groupDistance, (_dir - 180) + _groupAngle];
        _groupApproachPos = [_groupApproachPos, 0, 200, 10, 0, 0.2, 0, [], [_groupApproachPos, _groupApproachPos]] call BIS_fnc_findSafePos;
        
        // First move to approach position, then to target
        private _wp = _group addWaypoint [_groupApproachPos, 50];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed (if (_spawnIndex <= (_totalGroups * 0.3)) then {"NORMAL"} else {"LIMITED"});
        _wp setWaypointBehaviour "AWARE";
        
        // After reaching approach position, move to actual target with coordinated timing
        [_group, _targetPos, _groupApproachPos, _spawnIndex, _totalGroups] spawn {
            params ["_group", "_targetPos", "_approachPos", "_index", "_total"];
            
            waitUntil {
                sleep 5;
                leader _group distance _approachPos < 100
            };
            
            // Coordinate attack timing based on group position
            private _delay = if (_index < (_total * 0.3)) then {
                5 // First wave
            } else {
                if (_index < (_total * 0.6)) then {
                    15 // Second wave
                } else {
                    30 // Reserve/support elements
                };
            };
            sleep _delay;
            
            // Delete the approach waypoint
            deleteWaypoint [_group, currentWaypoint _group];
            
            // Add new attack waypoint to target
            [_group, _targetPos, 50] call BIS_fnc_taskAttack;
        };
        
        // Add killed event handler to each unit
        {
            _x addEventHandler ["Killed", {
                params ["_unit"];
                private _nearVeh = nearestObjects [_unit, ["LandVehicle"], 50] select 0;
                {
                    if !(_x in [driver _nearVeh, gunner _nearVeh, commander _nearVeh]) then {
                        [_x] orderGetIn false;
                        [_x] allowGetIn false;
                        unassignVehicle _x;
                        doGetOut _x;
                    };
                } forEach crew _nearVeh;
            }];
        } forEach units _group;
        
        // Get the vehicle the group is using
        private _groupVeh = vehicle leader _group;
        if (_groupVeh != leader _group) then {
            // Create and setup dismount trigger
            private _dismountTrigger = createTrigger ["EmptyDetector", getPos _groupVeh, false];
            _dismountTrigger setTriggerArea [750, 750, 0, false, 100];
            _dismountTrigger setTriggerActivation ["WEST", "PRESENT", false];
            _dismountTrigger setTriggerStatements [
                "this",
                "
                private _veh = nearestObjects [thisTrigger, ['LandVehicle'], 50] select 0;
                {
                    if !(_x in [driver _veh, gunner _veh, commander _veh]) then {
                        [_x] orderGetIn false;
                        [_x] allowGetIn false;
                        unassignVehicle _x;
                        doGetOut _x;
                    };
                } forEach crew _veh;
                ",
                ""
            ];
            _dismountTrigger attachTo [_groupVeh, [0,0,0]];
        };
    };
    
    for "_spawnIndex" from 1 to _spawnCount do {
        // Get spawn position for this element
        private _elementApproachPos = _spawnPositions select (_spawnIndex - 1);
        
        // Debug logging for each spawn
        //diag_log format ["[FLO][QRF] Spawning group %1 at position %2", _spawnIndex, _spawnPos];
        
        // Add delay between spawns
        if (_spawnIndex > 1) then {
            private _delay = _delayPerSpawn + (60 + random 180); // Random delay between 60-240 seconds
            [_spawnIndex, _delay] call _fnc_delayedSpawn;
        };
        
        // Only show announcements if within radio tower range
        if ([_elementApproachPos] call _fnc_hasRadioCoverage) then {
            // Announce reinforcements periodically
            if (_spawnIndex == 1) then {
                ["showNotification", ["! WARNING !", "Enemy QRF Forces Inbound!", "warning"]] call FLO_fnc_intelSystem;
                private _attackingAtGrid = mapGridPosition _elementApproachPos;
                [[west,"HQ"], "Enemy QRF forces detected moving at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];
            } else {
                if (_spawnIndex mod 3 == 0) then {
                    private _msg = selectRandom [
                        "Additional enemy forces detected!",
                        "More hostile units approaching!",
                        "Enemy reinforcements moving in!"
                    ];
                    ["showNotification", ["! WARNING !", _msg, "warning"]] call FLO_fnc_intelSystem;
                };
            };
        };

        // Adjust tier based on spawn index and total count
        private _adjustedTier = switch (true) do {
            case (_spawnIndex <= (_spawnCount * 0.2)): { 
                // First 20% are highest tier
                if (_AGGRSCORE >= 13) then { "Tier4" } else { "Tier3" };
            };
            case (_spawnIndex <= (_spawnCount * 0.5)): { 
                // Next 30% are medium-high tier
                if (_AGGRSCORE >= 11) then { "Tier3" } else { "Tier2" };
            };
            case (_spawnIndex <= (_spawnCount * 0.8)): { 
                // Next 30% are medium tier
                "Tier2"
            };
            default { 
                // Last 20% are support/reserve elements
                "Tier1"
            };
        };

        switch (_adjustedTier) do {
            case "Tier4": {
                // Combined Arms Response - Armor + Mechanized + Air Support
                
                // Spawn armor element
                private _armorVehType = selectRandom (FLO_configCache get "vehicles" select 3); // MBT
                private _result = [_armorVehType, _spawnPos] call _fnc_createVehicleWithCrew;
                private _armorVeh = _result select 0;
                private _armorGroup = _result select 1;
                private _armorMaxCargo = _result select 2;
                _groups pushBack _armorGroup;
                
                // Set up behavior for armor group immediately
                [_armorGroup, _targetPos, _spawnPos, _approachDistance, _dir, _spawnIndex, count _groups] call _fnc_setupGroupBehavior;
                
                // Spawn mechanized infantry with APC
                private _mechVehType = selectRandom (FLO_configCache get "vehicles" select 2); // APC
                _result = [_mechVehType, _spawnPos] call _fnc_createVehicleWithCrew;
                private _mechVeh = _result select 0;
                private _mechGroup = _result select 1;
                private _mechMaxCargo = _result select 2;
                
                // Create and add infantry to APC
                private _mechInfGroup = createGroup EAST;
                for "_i" from 1 to _mechMaxCargo do {
                    // 5% chance to add a fire observer, otherwise use regular infantry
                    private _unitType = if (random 1 < 0.05) then {
                        selectRandom (FLO_configCache get "fireObservers")
                    } else {
                        selectRandom (FLO_configCache get "units")
                    };
                    
                    private _unit = _mechInfGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
                    if (_unitType in (FLO_configCache get "fireObservers")) then {
                        [_unit, EAST] call FLO_fnc_fireObserver;
                    };
                    _unit assignAsCargo _mechVeh;
                    _unit moveInCargo _mechVeh;
                };
                
                // Add intel to infantry group
                [_mechInfGroup] call _fnc_addIntelToGroup;
                
                (units _mechInfGroup) joinSilent _mechGroup;
                _groups pushBack _mechGroup;
                
                // Set up behavior for mech group immediately
                [_mechGroup, _targetPos, _spawnPos, _approachDistance, _dir, _spawnIndex, count _groups] call _fnc_setupGroupBehavior;
                
                // Add air support if first spawn
                if (_spawnIndex == 1) then {
                    [_targetPos, "CAS"] call FLO_fnc_airSupport;
                };
                
                // Add transport helicopter if using heli insert
                if (_insertType == "HeliInsert") then {
                    [_thisHeliInsertTrigger, _targetPos, _spawnPos] call FLO_fnc_heliInsert;
                };
            };
            
            case "Tier3": {
                // Heavy response - mechanized infantry + air support
                private _mechVehType = selectRandom (FLO_configCache get "vehicles" select 2);
                private _result = [_mechVehType, _spawnPos] call _fnc_createVehicleWithCrew;
                private _mechVeh = _result select 0;
                private _mechGroup = _result select 1;
                private _mechMaxCargo = _result select 2;
                
                // Create and add infantry to APC
                private _mechInfGroup = createGroup EAST;
                for "_i" from 1 to _mechMaxCargo do {
                    // 5% chance to add a fire observer, otherwise use regular infantry
                    private _unitType = if (random 1 < 0.05) then {
                        selectRandom (FLO_configCache get "fireObservers")
                    } else {
                        selectRandom (FLO_configCache get "units")
                    };
                    
                    private _unit = _mechInfGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
                    if (_unitType in (FLO_configCache get "fireObservers")) then {
                        [_unit, EAST] call FLO_fnc_fireObserver;
                    };
                    _unit assignAsCargo _mechVeh;
                    _unit moveInCargo _mechVeh;
                };
                
                // Add intel to infantry group
                [_mechInfGroup] call _fnc_addIntelToGroup;
                
                (units _mechInfGroup) joinSilent _mechGroup;
                _groups pushBack _mechGroup;
                
                // Set up behavior for group immediately
                [_mechGroup, _targetPos, _spawnPos, _approachDistance, _dir, _spawnIndex, count _groups] call _fnc_setupGroupBehavior;
                
                if (_insertType == "HeliInsert") then {
                    [_thisHeliInsertTrigger, _targetPos, _spawnPos] call FLO_fnc_heliInsert;
                };
                
                // Add air support if first spawn and aggression is high
                if (_spawnIndex == 1 && _AGGRSCORE > 5) then {
                    [_targetPos, "CAS"] call FLO_fnc_airSupport;
                };
            };
            
            case "Tier2": {
                // Medium response - mechanized infantry
                private _vehType = selectRandom (FLO_configCache get "vehicles" select 2);
                private _result = [_vehType, _spawnPos] call _fnc_createVehicleWithCrew;
                private _veh = _result select 0;
                private _motorGroup = _result select 1;
                private _maxCargo = _result select 2;
                
                // Create and add infantry
                private _infGroup = createGroup EAST;
                for "_i" from 1 to _maxCargo do {
                    // 5% chance to add a fire observer, otherwise use regular infantry
                    private _unitType = if (random 1 < 0.05) then {
                        selectRandom (FLO_configCache get "fireObservers")
                    } else {
                        selectRandom (FLO_configCache get "units")
                    };
                    
                    private _unit = _infGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
                    if (_unitType in (FLO_configCache get "fireObservers")) then {
                        [_unit, EAST] call FLO_fnc_fireObserver;
                    };
                    _unit assignAsCargo _veh;
                    _unit moveInCargo _veh;
                };
                
                // Add intel to infantry group
                [_infGroup] call _fnc_addIntelToGroup;
                
                (units _infGroup) joinSilent _motorGroup;
                _groups pushBack _motorGroup;
                
                // Set up behavior for group immediately
                [_motorGroup, _targetPos, _spawnPos, _approachDistance, _dir, _spawnIndex, count _groups] call _fnc_setupGroupBehavior;
                
                // Add light armor support if first spawn and aggression is high
                if (_spawnIndex == 1 && _AGGRSCORE > 7) then {
                    private _lightArmorType = selectRandom (FLO_configCache get "vehicles" select 2);
                    _result = [_lightArmorType, _spawnPos] call _fnc_createVehicleWithCrew;
                    private _lightVeh = _result select 0;
                    private _lightGroup = _result select 1;
                    private _lightMaxCargo = _result select 2;
                    _groups pushBack _lightGroup;
                    
                    // Set up behavior for light armor group immediately
                    [_lightGroup, _targetPos, _spawnPos, _approachDistance, _dir, _spawnIndex, count _groups] call _fnc_setupGroupBehavior;
                };
            };
            
            default {
                // Light response - motorized style
                private _vehType = selectRandom (FLO_configCache get "vehicles" select 1);
                private _result = [_vehType, _spawnPos] call _fnc_createVehicleWithCrew;
                private _veh = _result select 0;
                private _lightGroup = _result select 1;
                private _maxCargo = _result select 2;
                
                // Create and add infantry
                private _infGroup = createGroup EAST;
                for "_i" from 1 to _maxCargo do {
                    // 5% chance to add a fire observer, otherwise use regular infantry
                    private _unitType = if (random 1 < 0.05) then {
                        selectRandom (FLO_configCache get "fireObservers")
                    } else {
                        selectRandom (FLO_configCache get "units")
                    };
                    
                    private _unit = _infGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
                    if (_unitType in (FLO_configCache get "fireObservers")) then {
                        [_unit, EAST] call FLO_fnc_fireObserver;
                    };
                    _unit assignAsCargo _veh;
                    _unit moveInCargo _veh;
                };
                
                // Add intel to infantry group
                [_infGroup] call _fnc_addIntelToGroup;
                
                (units _infGroup) joinSilent _lightGroup;
                _groups pushBack _lightGroup;
                
                // Set up behavior for light group immediately
                [_lightGroup, _targetPos, _spawnPos, _approachDistance, _dir, _spawnIndex, count _groups] call _fnc_setupGroupBehavior;
                
                // Add mrap support if first spawn and aggression is high
                if (_spawnIndex == 1 && _AGGRSCORE > 3) then {
                    private _mrapType = selectRandom (FLO_configCache get "vehicles" select 2);
                    _result = [_mrapType, _spawnPos] call _fnc_createVehicleWithCrew;
                    private _mrapVeh = _result select 0;
                    private _mrapGroup = _result select 1;
                    private _mrapMaxCargo = _result select 2;
                    _groups pushBack _mrapGroup;
                    
                    // Set up behavior for MRAP group immediately
                    [_mrapGroup, _targetPos, _spawnPos, _approachDistance, _dir, _spawnIndex, count _groups] call _fnc_setupGroupBehavior;
                };
            };
        };
        
        // Update the groups in missionNamespace immediately after creating each group
        missionNamespace setVariable [_qrfVarName, _groups];
    };

    // Final update of groups in missionNamespace
    missionNamespace setVariable [_qrfVarName, _groups];
};

// Return the variable name so the caller can retrieve the groups
[true, _qrfVarName] 