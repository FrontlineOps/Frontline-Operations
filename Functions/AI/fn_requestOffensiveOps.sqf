/*
    Function: FLO_fnc_requestOffensiveOps
    
    Description:
    Requests and executes a full-scale offensive operation against a BLUFOR installation.
    Uses OPFOR resources to fund the operation and coordinates multiple attack elements.
    
    Parameters:
    _aggressionScore - Current aggression score [Number]
    
    Returns:
    Boolean - True if operation was launched successfully
*/

params [
    ["_aggressionScore", 0, [0]]
];

// Check if an offensive operation is already underway
if (OffensiveOperationUnderway && !isNil "OffensiveOperationUnderway") exitWith {
    diag_log "[FLO][OffensiveOps] Another offensive operation is already underway";
    false
};

// Set operation flag
OffensiveOperationUnderway = true;

// Resource cost for offensive operations
private _operationCost = 100 + (_aggressionScore * 10);

// Try to spend resources for offensive operation
if !(["spend", [_operationCost]] call FLO_fnc_opforResources) exitWith {
    diag_log "[FLO][OffensiveOps] Insufficient resources for offensive operation";
    // Reset the flag if we can't afford the operation
    OffensiveOperationUnderway = false;
    false
};

// Find suitable OPFOR and BLUFOR installations
private _opforInstallations = allMapMarkers select {
    markerType _x in ["loc_Power", "o_support", "n_support", "loc_Ruin", "n_installation", "o_installation"]
};

private _bluforInstallations = allMapMarkers select {
    markerType _x == "b_installation" &&
    (markerColor _x == "ColorYellow" || markerColor _x == "colorBLUFOR" || markerColor _x == "colorWEST")
};

// Exit if no valid installations found
if (_opforInstallations isEqualTo [] || _bluforInstallations isEqualTo []) exitWith {
    diag_log "[FLO][OffensiveOps] No valid installations found for offensive operation";
    OffensiveOperationUnderway = false;
    false
};

// Find closest OPFOR installation to a BLUFOR installation
private _distanceMap = [];

{
    private _opforPos = getMarkerPos _x;
    
    {
        private _bluforPos = getMarkerPos _x;
        private _distance = _opforPos distanceSqr _bluforPos;
        _distanceMap pushBack [_distance, _x, _foreachindex];
    } forEach _bluforInstallations;
} forEach _opforInstallations;

_distanceMap sort true;
private _closestPair = _distanceMap select 0;
private _targetBluforMarker = _closestPair select 1;

// Find the OPFOR installation that's closest to this BLUFOR target
private _opforDistances = [];
{
    private _opforPos = getMarkerPos _x;
    private _bluforPos = getMarkerPos _targetBluforMarker;
    private _distance = _opforPos distanceSqr _bluforPos;
    _opforDistances pushBack [_distance, _x];
} forEach _opforInstallations;

_opforDistances sort true;
private _sourceOpforMarker = (_opforDistances select 0) select 1;

// Find the target building (HQ or similar structure)
private _targetBuilding = (nearestObjects [
    getMarkerPos _targetBluforMarker,
    FLO_configCache get "HQbuildings",
    300
]) select 0;

// Create assault marker
private _assaultMarkerName = "AssltDest" + (str ([0, 0, 0] getPos [(10 + (random 150)), (0 + (random 360))]));
publicVariable "_assaultMarkerName";

createMarker [_assaultMarkerName, getPos _targetBuilding];
_assaultMarkerName setMarkerType "mil_marker_noShadow";
_assaultMarkerName setMarkerColor "colorOPFOR";
_assaultMarkerName setMarkerSize [2.5, 2.5];
_assaultMarkerName setMarkerAlpha 0.5;

// Notify players
["showNotification", ["! CRITICAL WARNING !", "Friendly Objective is Under Attack!", "warning"]] call FLO_fnc_intelSystem;
private _attackingAtGrid = mapGridPosition getMarkerPos _assaultMarkerName;
[[west,"HQ"], "ALERT: Friendly Location Under Enemy attack at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];

// Calculate attack direction
private _assaultAzimuth = (getMarkerPos _targetBluforMarker) getDir (getMarkerPos _sourceOpforMarker);

// Get spawn position
private _spawnPos = getMarkerPos _sourceOpforMarker;
private _targetPos = getPos _targetBuilding;

// Start with recon if aggression is high enough
if (_aggressionScore > 3) then {
    ["showNotification", ["! INTELLIGENCE !", "Enemy reconnaissance aircraft spotted!", "info"]] call FLO_fnc_intelSystem;
    [_targetPos] call FLO_fnc_airRecon;
    sleep 300;
};

// Artillery prep based on aggression - now with looping capability
if (_aggressionScore > 5) then {
    // Initial artillery barrage
    ["showNotification", ["! WARNING !", "Enemy artillery fire incoming!", "warning"]] call FLO_fnc_intelSystem;
    [_targetPos, _aggressionScore] call FLO_fnc_artilleryPrep;
    
    // Calculate number of artillery barrages based on aggression
    private _artilleryBarrages = floor (_aggressionScore / 3);
    _artilleryBarrages = _artilleryBarrages max 1 min 5; // Between 1 and 5 barrages
    
    // Schedule additional artillery barrages
    if (_artilleryBarrages > 1) then {
        [_targetPos, _aggressionScore, _artilleryBarrages] spawn {
            params ["_targetPos", "_aggressionScore", "_barrages"];
            
            for "_i" from 2 to _barrages do {
                // Wait between barrages - higher aggression means more frequent barrages
                private _delay = 600 - (_aggressionScore * 15); // Between 375-150 seconds based on aggression
                _delay = _delay max 150; // Minimum 150 seconds between barrages
                sleep _delay;
                
                // Notify players of continued artillery
                ["showNotification", ["! WARNING !", "Enemy artillery continuing bombardment!", "warning"]] call FLO_fnc_intelSystem;
                
                // Adjust target position slightly for each barrage
                private _adjustedPos = _targetPos getPos [random 100, random 360];
                [_adjustedPos, _aggressionScore] call FLO_fnc_artilleryPrep;
            };
        };
    };
    
    // Wait after initial barrage before continuing with ground forces
    sleep 180;
};

// Select attack pattern based on terrain and situation
private _pattern = selectRandom ["PINCER", "FRONTAL", "INFILTRATION"];
if (_aggressionScore > 10) then {
    _pattern = "FRONTAL"; // More aggressive at high aggression
};

// Execute the attack with combined arms
[_targetPos, getMarkerPos _sourceOpforMarker, _pattern, _aggressionScore] call FLO_fnc_executeAttackPattern;

// Calculate force size based on aggression
private _forceSize = switch (true) do {
    case (_aggressionScore >= 15): { 48 };  // Maximum aggression - Full Brigade Attack
    case (_aggressionScore >= 12): { 28 };   // Very high aggression - BTG Attack
    case (_aggressionScore >= 9): { 20 };    // High aggression - Reinforced Company Attack
    case (_aggressionScore >= 6): { 14 };    // Medium aggression - Company Attack
    case (_aggressionScore >= 3): { 9 };    // Low aggression - Reinforced Platoon Attack
    default { 6 };                          // Minimal aggression - Platoon Attack
};

// Helper function for vehicle and crew creation
private _fnc_createVehicleWithCrew = {
    params ["_vehType", "_spawnPos"];
    
    // Find nearest road
    private _nearRoads = _spawnPos nearRoads 1500;
    private _spawnPosRoad = if (count _nearRoads > 0) then {
        getPos (_nearRoads select 0)
    } else {
        _spawnPos
    };
    
    private _veh = createVehicle [_vehType, _spawnPosRoad, [], 0, "NONE"];
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
private _baseAngle = 360 / _forceSize;
private _minSafeDistance = 50; // Minimum distance between spawn points
private _spiralGrowth = 20;    // How much the spiral grows per point
private _approachDistance = 800; // Base approach distance

{
    private _angle = _baseAngle * _forEachIndex;
    private _spiralDistance = _minSafeDistance + (_spiralGrowth * _forEachIndex); // Spiral growth
    private _distance = _approachDistance + _spiralDistance + (random 200 - random 100); // Add some randomness
    private _pos = _targetPos getPos [_distance, (_assaultAzimuth - 180) + _angle];
    
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
            _pos = _targetPos getPos [_distance, (_assaultAzimuth - 180) + _angle + (random 60 - random 60)];
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
} forEach ([] call {private _arr = []; for "_i" from 1 to _forceSize do {_arr pushBack _i}; _arr});

// Create a unique variable name for this offensive operation
private _offensiveOpsVarName = format ["FLO_OffensiveOps_Groups_%1", floor random 999999];
missionNamespace setVariable [_offensiveOpsVarName, []];

// Spawn the offensive forces
[
    _forceSize,
    _spawnPositions,
    _aggressionScore,
    _targetPos,
    _spawnPos,
    _fnc_createVehicleWithCrew,
    _fnc_addIntelToGroup,
    _assaultAzimuth,
    _offensiveOpsVarName,
    _targetBluforMarker
] spawn {
    params [
        "_forceSize",
        "_spawnPositions",
        "_aggressionScore",
        "_targetPos",
        "_spawnPos",
        "_fnc_createVehicleWithCrew",
        "_fnc_addIntelToGroup",
        "_assaultAzimuth",
        "_offensiveOpsVarName",
        "_targetBluforMarker"
    ];
    
    private _groups = [];
    
    // Function to set up group behavior
    private _fnc_setupGroupBehavior = {
        params ["_group", "_targetPos", "_spawnPos", "_spawnIndex", "_totalGroups"];
        
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
        
        // Calculate unique approach position
        private _sectorSize = 360 / _totalGroups;
        private _groupAngle = _sectorSize * (_spawnIndex - 1);
        private _groupDistance = 500 + (random 300 - random 150);
        private _groupApproachPos = _targetPos getPos [_groupDistance, _groupAngle];
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
                leader _group distance _approachPos < 100 || {!alive _x} count units _group > (count units _group * 0.5)
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
                if (!isNil "_nearVeh" && {_nearVeh != objNull}) then {
                    {
                        if !(_x in [driver _nearVeh, gunner _nearVeh, commander _nearVeh]) then {
                            [_x] orderGetIn false;
                            [_x] allowGetIn false;
                            unassignVehicle _x;
                            doGetOut _x;
                        };
                    } forEach crew _nearVeh;
                };
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
                if (!isNil '_veh' && {_veh != objNull}) then {
                    {
                        if !(_x in [driver _veh, gunner _veh, commander _veh]) then {
                            [_x] orderGetIn false;
                            [_x] allowGetIn false;
                            unassignVehicle _x;
                            doGetOut _x;
                        };
                    } forEach crew _veh;
                };
                ",
                ""
            ];
            _dismountTrigger attachTo [_groupVeh, [0,0,0]];
        };
    };
    
    // Organize forces into waves for better tactical deployment and performance
    private _waveCount = switch (true) do {
        case (_forceSize >= 40): { 5 }; // 5 waves for brigade-sized force
        case (_forceSize >= 25): { 4 }; // 4 waves for battalion-sized force
        case (_forceSize >= 15): { 3 }; // 3 waves for company-sized force
        case (_forceSize >= 8): { 2 };  // 2 waves for platoon-sized force
        default { 1 };                  // 1 wave for small forces
    };
    
    private _unitsPerWave = ceil(_forceSize / _waveCount);
    private _waveTiming = switch (_waveCount) do {
        case 5: { [0, 300, 600, 1200, 1800] }; // 0min, 5min, 10min, 20min, 30min
        case 4: { [0, 300, 900, 1500] };       // 0min, 5min, 15min, 25min
        case 3: { [0, 450, 1200] };            // 0min, 7.5min, 20min
        case 2: { [0, 600] };                  // 0min, 10min
        default { [0] };                       // All at once
    };
    
    // Spawn forces in waves
    for "_wave" from 1 to _waveCount do {
        private _waveStartIndex = (_wave - 1) * _unitsPerWave + 1;
        private _waveEndIndex = _wave * _unitsPerWave min _forceSize;
        private _waveDelay = _waveTiming select (_wave - 1);
        
        if (_wave > 1) then {
            // Wait for the appropriate wave timing
            sleep _waveDelay;
            
            // Announce new wave
            private _waveSize = switch (_wave) do {
                case 2: { "secondary" };
                case 3: { "main" };
                case 4: { "reserve" };
                case 5: { "final" };
                default { "additional" };
            };
            
            ["showNotification", ["! WARNING !", format["Enemy %1 attack wave incoming!", _waveSize], "warning"]] call FLO_fnc_intelSystem;
            [[west,"HQ"], format["ALERT: Enemy %1 attack wave detected!", _waveSize]] remoteExec ["sideChat", 0];
        };
        
        // Calculate wave composition - earlier waves get better units
        private _waveTierModifier = switch (_wave) do {
            case 1: { 2 };  // First wave gets +2 tier boost
            case 2: { 1 };  // Second wave gets +1 tier boost
            case 3: { 0 };  // Third wave is standard
            case 4: { -1 }; // Fourth wave gets -1 tier penalty
            default { -2 }; // Fifth wave gets -2 tier penalty
        };
        
        // Spawn units for this wave
        for "_spawnIndex" from _waveStartIndex to _waveEndIndex do {
            // Get spawn position for this element
            private _elementSpawnPos = _spawnPositions select (_spawnIndex - 1);
            
            // Add small delay between individual unit spawns within the wave
            if (_spawnIndex > _waveStartIndex) then {
                private _intraWaveDelay = 15 + (random 30); // 15-45 seconds between units in same wave
                sleep _intraWaveDelay;
            };
            
            // Announce reinforcements periodically
            if (_spawnIndex == _waveStartIndex) then {
                if (_wave == 1) then {
                    ["showNotification", ["! WARNING !", "Enemy Assault Forces Inbound!", "warning"]] call FLO_fnc_intelSystem;
                    private _attackingAtGrid = mapGridPosition _elementSpawnPos;
                    [[west,"HQ"], "Enemy assault forces detected moving at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];
                };
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

            // Adjust tier based on spawn index, total count, and wave modifier
            private _baseWaveTier = switch (true) do {
                case (_spawnIndex <= (_forceSize * 0.2)): { 
                    // First 20% are highest tier
                    if (_aggressionScore >= 13) then { 4 } else { 3 };
                };
                case (_spawnIndex <= (_forceSize * 0.5)): { 
                    // Next 30% are medium-high tier
                    if (_aggressionScore >= 11) then { 3 } else { 2 };
                };
                case (_spawnIndex <= (_forceSize * 0.8)): { 
                    // Next 30% are medium tier
                    2
                };
                default { 
                    // Last 20% are support/reserve elements
                    1
                };
            };
            
            // Apply wave modifier
            private _adjustedTierValue = _baseWaveTier + _waveTierModifier;
            _adjustedTierValue = _adjustedTierValue max 1 min 4; // Ensure between Tier1 and Tier4
            
            private _adjustedTier = "Tier" + str(_adjustedTierValue);

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
                    [_armorGroup, _targetPos, _spawnPos, _spawnIndex, _forceSize] call _fnc_setupGroupBehavior;
                    
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
                    [_mechGroup, _targetPos, _spawnPos, _spawnIndex, _forceSize] call _fnc_setupGroupBehavior;
                    
                    // Add air support if first spawn
                    if (_spawnIndex == 1) then {
                        [_targetPos, "CAS"] call FLO_fnc_airSupport;
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
                    [_mechGroup, _targetPos, _spawnPos, _spawnIndex, _forceSize] call _fnc_setupGroupBehavior;
                    
                    // Add air support if first spawn and aggression is high
                    if (_spawnIndex == 1 && _aggressionScore > 5) then {
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
                    [_motorGroup, _targetPos, _spawnPos, _spawnIndex, _forceSize] call _fnc_setupGroupBehavior;
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
                    [_lightGroup, _targetPos, _spawnPos, _spawnIndex, _forceSize] call _fnc_setupGroupBehavior;
                };
            };
            
            // Create additional patrol group for each spawn
            private _patrolGroup = [
                (getMarkerPos _targetBluforMarker) getPos [(500 + (random 100)), (_assaultAzimuth + (random 20))], 
                East, 
                [
                    selectRandom (FLO_configCache get "units"), 
                    selectRandom (FLO_configCache get "units"), 
                    selectRandom (FLO_configCache get "units"),
                    selectRandom (FLO_configCache get "units"), 
                    selectRandom (FLO_configCache get "units"), 
                    selectRandom (FLO_configCache get "units")
                ]
            ] call BIS_fnc_spawnGroup;
            
            private _waypoint = _patrolGroup addWaypoint [_targetPos, 0];
            _waypoint setWaypointType "MOVE";
            _groups pushBack _patrolGroup;
            
            // Update the groups in missionNamespace immediately after creating each group
            missionNamespace setVariable [_offensiveOpsVarName, _groups];
        };
        
        // Add helicopter insertion for high aggression in later waves
        if (_wave > 1 && _aggressionScore > 8 && _wave mod 2 == 0) then {
            ["showNotification", ["! WARNING !", "Enemy helicopter insertion detected!", "warning"]] call FLO_fnc_intelSystem;
            [_thisHeliInsertTrigger, _targetPos, _spawnPos] call FLO_fnc_heliInsert;
        };
    };
    
    // Final update of groups in missionNamespace
    missionNamespace setVariable [_offensiveOpsVarName, _groups];
};

// Schedule the reset of the offensive operation flag after a delay
[{
    OffensiveOperationUnderway = false;
    diag_log "[FLO][OffensiveOps] Offensive operation complete, flag reset";
}, [], 3600] call CBA_fnc_waitAndExecute; // Reset after 60 minutes

true