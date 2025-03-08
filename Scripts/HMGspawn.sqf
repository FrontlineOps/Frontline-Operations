/**
 * @param _this - Array [object] - The triggering object
 * @return - Nothing
 * 
 * Spawns HMG emplacements on nearby buildings based on aggression score
 * Higher aggression scores lead to more HMGs
 */

if (isNil "_this" || {count _this < 1}) exitWith {diag_log "[FLO] ERROR: HMGspawn called with invalid parameters"};

private _thisCntrPos = getPos (_this select 0);
if (isNil "_thisCntrPos") exitWith {diag_log "[FLO] ERROR: HMGspawn invalid position"};

// Get aggression score from marker
private _AGGRSCORE = 0;
private _mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
if (count _mrkrs > 0) then {
    private _mrkr = _mrkrs select 0;
    _AGGRSCORE = parseNumber (markerText _mrkr);
};

// Configuration data using HashMaps
private _buildingConfigs = createHashMapFromArray [
    ["hq", [
        ["Land_Cargo_HQ_V1_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V3_F"],
        [[5, 7], [6, 6]],  // Building positions by aggression level
        200                // Search radius
    ]],
    ["tower", [
        ["Land_Cargo_Tower_V1_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V3_F"],
        [[10, 11, 12, 13, 14, 15, 16, 17], [10, 11, 12, 13, 14, 15, 16, 17]],
        200
    ]],
    ["controltower", [
        ["Land_vn_controltower_01_f"],
        [[17, 15], []],  // Only one aggression level for control towers
        200
    ]]
];

/**
 * Spawns HMG emplacements on specified building types
 *
 * @param _buildingType - String - The building type identifier from the hashmap
 * @param _centerPos - Position - The center position to search from
 * @param _aggScore - Number - Current aggression score
 * @return Nothing
 */
private _fnc_spawnHMGsOnBuildings = {
    params ["_buildingType", "_centerPos", "_aggScore"];
    
    private _config = _buildingConfigs getOrDefault [_buildingType, []];
    if (_config isEqualTo []) exitWith {
        diag_log format ["[FLO] ERROR: Invalid building type: %1", _buildingType];
    };
    
    _config params ["_buildingClasses", "_positions", "_radius"];
    
    // Find nearby buildings
    private _nearBuildings = nearestObjects [_centerPos, _buildingClasses, _radius];
    if (count _nearBuildings == 0) exitWith {};
    
    // Determine which positions array to use based on aggression score
    private _posArray = _positions select 0;
    if (_aggScore > 10 && count _positions > 1) then {
        _posArray append (_positions select 1);
    };
    
    if (count _posArray == 0) exitWith {};
    
    {
        private _building = _x;
        
        // Spawn 1-2 HMGs per building based on chance
        private _chanceToSpawn = selectRandom [5, 10, 15];
        if (_chanceToSpawn > 5) then {
            // Select a random position from the array
            private _selectedPos = selectRandom _posArray;
            
            // Calculate actual position with slight vertical offset to prevent clipping
            private _actualBpodPosition = (_building buildingPos _selectedPos) vectorAdd [0,0,1];
            
            // Error checking for valid position
            if (_actualBpodPosition isEqualTo [0,0,0]) then {
                diag_log format ["[FLO] Warning: Invalid building position %1 for %2", _selectedPos, typeOf _building];
            } else {
                // Add a small delay for performance
                sleep 0.5;
                
                // Create the HMG
                private _hmg = createVehicle ["O_G_HMG_02_high_F", _actualBpodPosition, [], 0, "NONE"];
                _hmg setVectorUp [0,0,1];
                
                // Create crew
                private _crew = createVehicleCrew _hmg;
                
                // Apply unit loadouts from faction
                {
                    _x setUnitLoadout (selectRandom East_Units);
                } forEach units _crew;
            };
        };
    } forEach _nearBuildings;
};

// Spawn HMGs on different building types
["hq", _thisCntrPos, _AGGRSCORE] call _fnc_spawnHMGsOnBuildings;
["tower", _thisCntrPos, _AGGRSCORE] call _fnc_spawnHMGsOnBuildings;
["controltower", _thisCntrPos, _AGGRSCORE] call _fnc_spawnHMGsOnBuildings;