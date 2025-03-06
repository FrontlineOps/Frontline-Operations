/*
 * Function: FLO_fnc_aiCommander
 * Author: Azraeelian Angel
 * Description:
 * Creates an AI Commander that controls overall OPFOR operations.
 * Sets operation modes (Attack, Defend, Skirmish) and coordinates task forces.
 *
 * Arguments:
 * 0: Operation Mode <STRING> - "ATTACK", "DEFEND", "SKIRMISH" (Optional, default: "DEFEND")
 *
 * Return Value:
 * AI Commander HashMap Object <HASHMAP>
 *
 * Example:
 * ["ATTACK"] call FLO_fnc_aiCommander;
 */

params [["_operationMode", "DEFEND", [""]]];

// Log function start
["AI Commander", 3, format["Starting AI Commander with operation mode: %1", _operationMode]] call FLO_fnc_log;

// Initialize variables
private _hasSpecialOps = false;
private _lastCommanderUpdate = diag_tickTime;
private _commanderUpdateInterval = 300; // 5 minutes between strategy updates
private _specialOpsUpdateInterval = 900; // 15 minutes between special ops deployments
private _lastSpecialOpsTime = diag_tickTime - 600; // Start with a delay
private _currentThreatLevel = 0;
private _threatThreshold = 0.6; // Threshold to switch to defensive mode if under heavy attack
private _taskForceStrengthFactor = 1.0; // Multiplier for task force size

// Set up the Commander object using a HashMap
private _aiCommander = createHashMapObject [[
    ["_operationMode", _operationMode],
    ["_hasSpecialOps", _hasSpecialOps],
    ["_threatLevel", _currentThreatLevel],
    ["_lastUpdate", _lastCommanderUpdate],
    ["_lastSpecialOps", _lastSpecialOpsTime],
    ["_activeTasks", createHashMap],
    ["_outpostStatus", createHashMap],
    ["_taskForcePool", []],
    
    // Methods
    ["_updateOperationMode", {
        params ["_newMode"];
        private _oldMode = _self get "_operationMode";
        
        if (_oldMode != _newMode) then {
            _self set ["_operationMode", _newMode];
            ["AI Commander", 3, format["Operation mode changed from %1 to %2", _oldMode, _newMode]] call FLO_fnc_log;
            
            // Adjust task force behavior based on new mode
            switch (_newMode) do {
                case "ATTACK": {
                    _self set ["_taskForceStrengthFactor", 1.5]; // More offensive units
                };
                case "DEFEND": {
                    _self set ["_taskForceStrengthFactor", 0.8]; // Focus on defense
                };
                case "SKIRMISH": {
                    _self set ["_taskForceStrengthFactor", 1.2]; // Balanced approach
                };
            };
        };
    }],
    
    ["_assessThreat", {
        // Get all OPFOR outposts - updated with correct marker criteria
        private _outposts = (allMapMarkers select {
            markerColor _x in ["colorOPFOR", "ColorEAST"] && 
            markerType _x in ["o_support", "n_support", "o_installation", "n_installation", "loc_Power", "loc_Ruin", "o_recon", "o_antiair", "o_service"]
        });
        
        // Count blufor forces near OPFOR outposts to assess threat
        private _totalThreat = 0;
        private _totalOutposts = count _outposts;
        
        {
            private _outpost = _x;
            private _position = getMarkerPos _outpost;
            private _nearBlufor = _position nearEntities [["Man", "LandVehicle"], 500];
            _nearBlufor = _nearBlufor select {side _x == west && !(captive _x)};
            
            private _outpostThreat = count _nearBlufor / 20; // Normalize
            _outpostThreat = _outpostThreat min 1; // Cap at 1
            
            // Save status to outpost map
            (_self get "_outpostStatus") set [_outpost, [_outpostThreat, _nearBlufor]];
            
            _totalThreat = _totalThreat + _outpostThreat;
        } forEach _outposts;
        
        // Calculate average threat
        if (_totalOutposts > 0) then {
            _totalThreat = _totalThreat / _totalOutposts;
        };
        
        // Update threat level
        _self set ["_threatLevel", _totalThreat];
        
        // Auto-adjust operation mode based on threat
        if (_totalThreat > (_self get "_threatThreshold") && (_self get "_operationMode") == "ATTACK") then {
            _self call ["_updateOperationMode", ["DEFEND"]];
        };
        
        if (_totalThreat < 0.3 && (_self get "_operationMode") == "DEFEND") then {
            _self call ["_updateOperationMode", ["SKIRMISH"]];
        };
        
        ["AI Commander", 3, format["Current threat assessment: %1", _totalThreat]] call FLO_fnc_log;
        
        _totalThreat
    }],
    
    ["_deployTaskForces", {  
        // Get the current operation mode
        private _mode = _self get "_operationMode";
        private _taskForceStrengthFactor = _self get "_taskForceStrengthFactor";
        
        // Get outposts that can deploy task forces
        private _outposts = keys (_self get "_outpostStatus");
        private _availableOutposts = _outposts select {
            private _data = ((_self get "_outpostStatus") get _x) select 0;
            _data < 0.4 // Only deploy from outposts not under heavy threat
        };
        
        if (count _availableOutposts == 0) exitWith {
            ["AI Commander", 3, "No outposts available to deploy task forces"] call FLO_fnc_log;
        };
        
        // Initialize the garrison integration system if not done already
        if (isNil "FLO_TaskForce_Garrison_Integration") then {
            FLO_TaskForce_Garrison_Integration = call FLO_fnc_taskForceGarrisonIntegration;
        };
        
        // Logic varies by operation mode
        switch (_mode) do {
            case "ATTACK": {
                // Find blufor objectives to attack - updated with correct marker criteria
                private _bluforObjectives = allMapMarkers select {
                    markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] &&
                    markerType _x in ["b_installation", "b_support", "respawn_west", "b_hq"]
                };
                
                if (count _bluforObjectives > 0) then {
                    private _targetObj = selectRandom _bluforObjectives;
                    private _sourceOutpost = selectRandom _availableOutposts;
                    
                    // Calculate task force size based on outpost garrison strength and type
                    private _garrisonStrength = FLO_TaskForce_Garrison_Integration call ["_checkGarrisonStrength", [_sourceOutpost]];
                    private _taskForceSize = round((_garrisonStrength * 0.4) * _taskForceStrengthFactor);
                    _taskForceSize = _taskForceSize max 8 min 40; // Ensure reasonable size limits
                    
                    // Generate a unique task force ID
                    private _taskForceID = format ["TF_ATTACK_%1_%2", _sourceOutpost, floor(random 1000)];
                    
                    // Define unit composition for offensive operations
                    private _unitTypes = East_Units + East_Units_Officers;
                    
                    // Pull units from the garrison
                    private _units = FLO_TaskForce_Garrison_Integration call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                    
                    if (count _units > 0) then {
                        // Deploy offensive task force with the pulled units
                        private _taskForceGroup = [_sourceOutpost, getMarkerPos _targetObj, "ATTACK", _taskForceStrengthFactor, _units, _taskForceID] call FLO_fnc_TaskForceSystem;
                        ["AI Commander", 3, format["Deploying offensive task force from %1 to %2 with %3 units", _sourceOutpost, _targetObj, count _units]] call FLO_fnc_log;
                        
                        // Assign attack actions to the task force
                        _self call ["_assignTaskForceActions", [_taskForceGroup, getMarkerPos _targetObj, "ATTACK"]];
                    } else {
                        ["AI Commander", 3, format["Failed to pull units from garrison at %1 for offensive task force", _sourceOutpost]] call FLO_fnc_log;
                    };
                };
                
                // Also check for BLUFOR troops in the field
                _self call ["_attackBluforInField", [_taskForceStrengthFactor * 1.2]];
            };
            
            case "DEFEND": {
                // Reinforce threatened outposts
                private _threatenedOutposts = _outposts select {
                    private _data = ((_self get "_outpostStatus") get _x) select 0;
                    _data >= 0.4 && _data < 0.7 // Moderate threat
                };
                
                if (count _threatenedOutposts > 0 && count _availableOutposts > 0) then {
                    private _targetOutpost = selectRandom _threatenedOutposts;
                    private _sourceOutpost = selectRandom (_availableOutposts - [_targetOutpost]);
                    
                    if (!isNil "_sourceOutpost") then {
                        // Calculate task force size based on outpost garrison strength and type
                        private _garrisonStrength = FLO_TaskForce_Garrison_Integration call ["_checkGarrisonStrength", [_sourceOutpost]];
                        private _taskForceSize = round((_garrisonStrength * 0.3) * _taskForceStrengthFactor);
                        _taskForceSize = _taskForceSize max 6 min 30; // Ensure reasonable size limits
                        
                        // Generate a unique task force ID
                        private _taskForceID = format ["TF_DEFEND_%1_%2", _sourceOutpost, floor(random 1000)];
                        
                        // Define unit composition for defensive operations - use array with AT specialists
                        // For defensive operations, prioritize units good for defense
                        private _defensiveUnits = East_Units select {
                            _x find "_AT_F" > 0 ||   // AT specialists
                            _x find "_AR_F" > 0 ||   // Autoriflemen
                            _x find "_MG_F" > 0 ||   // Machine gunners
                            _x find "_medic_F" > 0   // Medics
                        };
                        
                        private _unitTypes = if (count _defensiveUnits > 0) then {
                            East_Units + _defensiveUnits  // Add defensive specialists with extra weight
                        } else {
                            East_Units
                        };
                        
                        // Pull units from the garrison
                        private _units = FLO_TaskForce_Garrison_Integration call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                        
                        if (count _units > 0) then {
                            // Deploy defensive task force with the pulled units
                            private _taskForceGroup = [_sourceOutpost, getMarkerPos _targetOutpost, "DEFEND", _taskForceStrengthFactor, _units, _taskForceID] call FLO_fnc_TaskForceSystem;
                            ["AI Commander", 3, format["Reinforcing %1 with defensive task force from %2 with %3 units", _targetOutpost, _sourceOutpost, count _units]] call FLO_fnc_log;
                            
                            // Assign defend actions to the task force
                            _self call ["_assignTaskForceActions", [_taskForceGroup, getMarkerPos _targetOutpost, "DEFEND"]];
                        } else {
                            ["AI Commander", 3, format["Failed to pull units from garrison at %1 for defensive task force", _sourceOutpost]] call FLO_fnc_log;
                        };
                    };
                };
            };
            
            case "SKIRMISH": {
                // Mix of patrols and counter-attacks
                if (random 1 > 0.5) then {
                    // Find patrol points - roads between outposts
                    private _sourceOutpost = selectRandom _availableOutposts;
                    private _roads = (getMarkerPos _sourceOutpost) nearRoads 2000;
                    
                    if (count _roads > 0) then {
                        private _targetRoad = selectRandom _roads;
                        
                        // Calculate task force size based on outpost garrison strength and type
                        private _garrisonStrength = FLO_TaskForce_Garrison_Integration call ["_checkGarrisonStrength", [_sourceOutpost]];
                        private _taskForceSize = round((_garrisonStrength * 0.2) * _taskForceStrengthFactor * 0.7);
                        _taskForceSize = _taskForceSize max 4 min 16; // Smaller patrol groups
                        
                        // Generate a unique task force ID
                        private _taskForceID = format ["TF_PATROL_%1_%2", _sourceOutpost, floor(random 1000)];
                        
                        // Define unit composition for patrol operations
                        private _unitTypes = East_Units;
                        
                        // Pull units from the garrison
                        private _units = FLO_TaskForce_Garrison_Integration call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                        
                        if (count _units > 0) then {
                            // Deploy patrol task force with the pulled units
                            private _taskForceGroup = [_sourceOutpost, getPos _targetRoad, "PATROL", _taskForceStrengthFactor * 0.7, _units, _taskForceID] call FLO_fnc_TaskForceSystem;
                            ["AI Commander", 3, format["Deploying patrol from %1 with %2 units", _sourceOutpost, count _units]] call FLO_fnc_log;
                            
                            // Assign patrol actions to the task force
                            _self call ["_assignTaskForceActions", [_taskForceGroup, getPos _targetRoad, "PATROL"]];
                        } else {
                            ["AI Commander", 3, format["Failed to pull units from garrison at %1 for patrol task force", _sourceOutpost]] call FLO_fnc_log;
                        };
                    };
                } else {
                    // Small raids against blufor positions - updated with correct marker criteria
                    private _bluforPositions = allMapMarkers select {
                        markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] &&
                        markerType _x in ["b_installation", "b_support", "respawn_west", "b_hq"]
                    };
                    
                    if (count _bluforPositions > 0 && count _availableOutposts > 0) then {
                        private _targetPos = selectRandom _bluforPositions;
                        private _sourceOutpost = selectRandom _availableOutposts;
                        
                        // Calculate task force size based on outpost garrison strength and type
                        private _garrisonStrength = FLO_TaskForce_Garrison_Integration call ["_checkGarrisonStrength", [_sourceOutpost]];
                        private _taskForceSize = round((_garrisonStrength * 0.25) * _taskForceStrengthFactor * 0.8);
                        _taskForceSize = _taskForceSize max 5 min 20; // Balanced skirmish size
                        
                        // Generate a unique task force ID
                        private _taskForceID = format ["TF_SKIRMISH_%1_%2", _sourceOutpost, floor(random 1000)];
                        
                        // Define unit composition for skirmish operations
                        private _unitTypes = East_Units + East_Units_Officers;
                        
                        // Pull units from the garrison
                        private _units = FLO_TaskForce_Garrison_Integration call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                        
                        if (count _units > 0) then {
                            // Deploy skirmish task force with the pulled units
                            private _taskForceGroup = [_sourceOutpost, getMarkerPos _targetPos, "SKIRMISH", _taskForceStrengthFactor * 0.8, _units, _taskForceID] call FLO_fnc_TaskForceSystem;
                            ["AI Commander", 3, format["Deploying skirmish force from %1 to %2 with %3 units", _sourceOutpost, _targetPos, count _units]] call FLO_fnc_log;
                            
                            // Assign skirmish actions to the task force
                            _self call ["_assignTaskForceActions", [_taskForceGroup, getMarkerPos _targetPos, "SKIRMISH"]];
                        } else {
                            ["AI Commander", 3, format["Failed to pull units from garrison at %1 for skirmish task force", _sourceOutpost]] call FLO_fnc_log;
                        };
                    };
                    
                    // Also occasionally attack BLUFOR in the field during skirmish mode
                    if (random 1 > 0.7) then {
                        _self call ["_attackBluforInField", [_taskForceStrengthFactor * 0.9]];
                    };
                };
            };
        };
    }],
    
    ["_attackBluforInField", {
        params ["_taskForceStrengthFactor"];
        
        // Get outposts that can deploy task forces
        private _outposts = keys (_self get "_outpostStatus");
        private _availableOutposts = _outposts select {
            private _data = ((_self get "_outpostStatus") get _x) select 0;
            _data < 0.4 // Only deploy from outposts not under heavy threat
        };
        
        if (count _availableOutposts == 0) exitWith {
            ["AI Commander", 3, "No outposts available to deploy attack forces"] call FLO_fnc_log;
            false
        };
        
        // Find BLUFOR units in the field
        private _allDetectedUnits = [];
        private _detectionRange = 3000; // How far OPFOR can detect BLUFOR units
        
        // Check each outpost for detected BLUFOR units
        {
            private _outpost = _x;
            private _position = getMarkerPos _outpost;
            
            // Get all BLUFOR units within detection range
            private _nearBlufor = _position nearEntities [["Man", "LandVehicle", "Air"], _detectionRange];
            _nearBlufor = _nearBlufor select {side _x == west && !(captive _x)};
            
            // Add each unit with its position and the detecting outpost
            {
                _allDetectedUnits pushBack [_x, getPos _x, _outpost, group _x];
            } forEach _nearBlufor;
        } forEach _outposts;
        
        // If no units detected, exit
        if (count _allDetectedUnits == 0) exitWith {
            ["AI Commander", 3, "No BLUFOR units detected in the field to attack"] call FLO_fnc_log;
            false
        };
        
        // Group detected units by their groups to avoid sending multiple task forces to the same group
        private _groupedDetections = createHashMap;
        
        {
            _x params ["_unit", "_position", "_detectingOutpost", "_group"];
            
            // Use the group as the key
            private _groupID = str _group;
            private _existingEntry = _groupedDetections getOrDefault [_groupID, []];
            
            if (count _existingEntry == 0) then {
                // New group, initialize with units and position
                _groupedDetections set [_groupID, [1, _position, _detectingOutpost]];
            } else {
                // Existing group, update count
                _existingEntry set [0, (_existingEntry select 0) + 1];
                _groupedDetections set [_groupID, _existingEntry];
            };
        } forEach _allDetectedUnits;
        
        // Now filter for groups that have a significant number of units (worth attacking)
        private _significantGroups = [];
        
        {
            private _groupData = _y;
            _groupData params ["_unitCount", "_position", "_detectingOutpost"];
            
            // Only target groups with at least 3 units
            if (_unitCount >= 3) then {
                _significantGroups pushBack [_x, _unitCount, _position, _detectingOutpost];
            };
        } forEach _groupedDetections;
        
        // If no significant groups, exit
        if (count _significantGroups == 0) exitWith {
            ["AI Commander", 3, "No significant BLUFOR groups in the field to attack"] call FLO_fnc_log;
            false
        };
        
        // Sort groups by size (largest first)
        _significantGroups sort false;
        
        // Choose one significant group to attack (prioritize larger groups)
        private _targetGroup = selectRandom (_significantGroups select [0, (count _significantGroups) min 3]);
        _targetGroup params ["_groupID", "_unitCount", "_position", "_detectingOutpost"];
        
        // Determine attack strength based on group size
        private _attackStrength = switch (true) do {
            case (_unitCount > 10): {_taskForceStrengthFactor * 1.5}; // Large group
            case (_unitCount > 5): {_taskForceStrengthFactor * 1.2}; // Medium group
            default {_taskForceStrengthFactor * 0.8}; // Small group
        };
        
        // Select a nearby outpost to deploy the attack force
        private _nearOutposts = _availableOutposts select {
            (getMarkerPos _x) distance _position < 5000
        };
        
        private _sourceOutpost = if (count _nearOutposts > 0) then {
            // Prefer closer outposts
            _nearOutposts = [_nearOutposts, [], {(getMarkerPos _x) distance _position}, "ASCEND"] call BIS_fnc_sortBy;
            _nearOutposts select 0
        } else {
            // Fall back to any available outpost
            selectRandom _availableOutposts
        };
        
        // Calculate task force size based on BLUFOR group size and our strength factor
        private _taskForceSize = round(_unitCount * 1.5 * _attackStrength);
        _taskForceSize = _taskForceSize max 6 min 30; // Ensure reasonable size limits
        
        // Generate a unique task force ID
        private _taskForceID = format ["TF_FIELDATTACK_%1_%2", _sourceOutpost, floor(random 1000)];
        
        // Define unit composition for field attack operations - combat-focused with specialists
        // For field attacks, we want combat specialists and heavy firepower
        private _combatSpecialists = East_Units select {
            _x find "_AT_F" > 0 ||   // AT specialists
            _x find "_AR_F" > 0 ||   // Autoriflemen
            _x find "_GL_F" > 0 ||   // Grenadiers
            _x find "_M_F" > 0       // Marksmen
        };
        
        private _unitTypes = if (count _combatSpecialists > 0) then {
            East_Units + _combatSpecialists  // Add combat specialists with extra weight
        } else {
            East_Units
        };
        
        // Pull units from the garrison
        private _units = FLO_TaskForce_Garrison_Integration call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
        
        if (count _units > 0) then {
            // Deploy attack force with pulled units
            private _taskForceGroup = [_sourceOutpost, _position, "ATTACK", _attackStrength, _units, _taskForceID] call FLO_fnc_TaskForceSystem;
            
            // Assign attack actions to the task force
            _self call ["_assignTaskForceActions", [_taskForceGroup, _position, "ATTACK"]];
            
            // Create a temporary marker for the target location (for debugging and visual reference)
            private _markerName = format ["blufor_detected_%1_%2", floor random 1000, floor diag_tickTime];
            private _marker = createMarker [_markerName, _position];
            _marker setMarkerType "o_unknown";
            _marker setMarkerColor "ColorRed";
            _marker setMarkerAlpha 0.7;
            _marker setMarkerText format ["Detected BLUFOR (%1)", _unitCount];
            
            // Set up marker deletion after 5 minutes
            [_markerName] spawn {
                params ["_markerName"];
                sleep 300;
                deleteMarker _markerName;
            };
            
            ["AI Commander", 3, format["Deploying force from %1 to attack %2 BLUFOR units in the field with %3 of our units", _sourceOutpost, _unitCount, count _units]] call FLO_fnc_log;
            true
        } else {
            ["AI Commander", 3, format["Failed to pull units from garrison at %1 for field attack task force", _sourceOutpost]] call FLO_fnc_log;
            false
        };
    }],
    
    ["_deploySpecialOperations", {   
        // Only deploy special ops at night
        private _hour = date select 3;
        if (_hour < 20 && _hour > 4) exitWith {
            ["AI Commander", 3, "Special operations only deploy at night (20:00-04:00)"] call FLO_fnc_log;
            false
        };
        
        // Find suitable targets - undefended or lightly defended blufor positions - updated with correct marker criteria
        private _bluforPositions = allMapMarkers select {
            markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] &&
            markerType _x in ["b_installation", "b_support", "respawn_west", "b_hq"]
        };
        
        if (count _bluforPositions == 0) exitWith {
            ["AI Commander", 3, "No suitable targets for special operations"] call FLO_fnc_log;
            false
        };
        
        // Select a random target
        private _targetPos = selectRandom _bluforPositions;
        private _targetPosition = getMarkerPos _targetPos;
        
        // Check if target is lightly defended
        private _nearUnits = _targetPosition nearEntities [["Man", "LandVehicle"], 500];
        private _bluforUnits = _nearUnits select {side _x == west && !(captive _x)};
        
        if (count _bluforUnits > 10) exitWith {
            ["AI Commander", 3, format["Target %1 too heavily defended for special operations", _targetPos]] call FLO_fnc_log;
            false
        };
        
        // Find suitable insertion point
        private _insertionPoint = [_targetPosition, 1000, 1500, 10, 0, 0.2, 0] call BIS_fnc_findSafePos;
        
        // Create and deploy special forces team
        private _specialOpsGroup = createGroup [east, true];
        
        // Add special forces operators
        for "_i" from 1 to 8 do {
            // Select appropriate unit types for special operations
            // Prefer marksmen, special forces, and specialists
            private _specialOpsCandidates = East_Units select {
                _x find "_M_F" > 0 ||    // Marksmen
                _x find "_TL_F" > 0 ||   // Team leaders  
                _x find "_exp_F" > 0 ||  // Explosive specialists
                _x find "_medic_F" > 0 || // Medics
                _x find "_GL_F" > 0      // Grenadiers
            };
            
            // If no specialized units found, fall back to regular units
            private _unitType = if (count _specialOpsCandidates > 0) then {
                selectRandom _specialOpsCandidates
            } else {
                selectRandom East_Units
            };
            
            private _unit = _specialOpsGroup createUnit [_unitType, _insertionPoint, [], 0, "NONE"];
            _unit allowDamage false; // Temporarily prevent damage during spawn
            
            // Equip unit with night operations gear
            _unit addPrimaryWeaponItem "acc_pointer_IR";
            _unit addPrimaryWeaponItem "optic_Nightstalker";
            _unit addHeadgear "H_HelmetSpecO_blk";
            _unit addGoggles "G_Balaclava_blk";
            
            // Add NVGs
            _unit linkItem "NVGoggles_OPFOR";
            
            // Special loadout for demo expert
            if (_unitType find "_exp_F" > 0) then {
                for "_m" from 1 to 3 do {
                    _unit addMagazine "DemoCharge_Remote_Mag";
                }; 
            };
            
            // All units get silencers
            _unit addPrimaryWeaponItem "muzzle_snds_H";
            
            // Re-enable damage after setup
            [_unit, true] remoteExec ["allowDamage", 0, _unit];
        };
        
        // Set group behaviors
        _specialOpsGroup setBehaviour "STEALTH";
        _specialOpsGroup setCombatMode "GREEN";
        _specialOpsGroup setSpeedMode "LIMITED";
        
        // Assign tasks based on mission
        // Mine roads or recon the area
        if (random 1 > 0.5) then {
            private _roads = _targetPosition nearRoads 1000;
            if (count _roads > 0) then {
                private _minePoints = [];
                for "_i" from 1 to (3 + floor(random 3)) do {
                    _minePoints pushBack (selectRandom _roads);
                };
                
                {
                    private _wp = _specialOpsGroup addWaypoint [getPos _x, 20];
                    _wp setWaypointType "MOVE";
                    _wp setWaypointBehaviour "STEALTH";
                    
                    private _wpPlaceMine = _specialOpsGroup addWaypoint [getPos _x, 0];
                    _wpPlaceMine setWaypointType "SCRIPTED";
                    _wpPlaceMine setWaypointScript "A3\functions_f\waypoints\fn_wpMine.sqf";
                } forEach _minePoints;
            };
        } 
        // Assault position
        else {
            // Use our waypoint action system to handle the special ops mission
            [_specialOpsGroup, _targetPosition] call FLO_fnc_attackArea;
            
            // Add an escape waypoint at the end to clean up the group
            private _wp = _specialOpsGroup addWaypoint [_insertionPoint, 100];
            _wp setWaypointType "MOVE";
            _wp setWaypointStatements ["true", "
                {deleteVehicle _x} forEach (units group this); 
                deleteGroup group this;
            "];
        };
        
        _self set ["_hasSpecialOps", true];
        _self set ["_lastSpecialOps", diag_tickTime];
        
        ["AI Commander", 3, format["Deployed special operations team to %1", _targetPos]] call FLO_fnc_log;
        true
    }],
    
    ["_assignTaskForceActions", {
        params ["_taskForceGroup", "_targetPosition", "_operationType"];
        
        // Ensure we have a valid group
        if (isNull _taskForceGroup) exitWith {
            ["AI Commander", 3, "Cannot assign actions to null group"] call FLO_fnc_log;
            false
        };
        
        // Assign the appropriate action based on the operation type
        switch (_operationType) do {
            case "ATTACK": {
                [_taskForceGroup, _targetPosition] call FLO_fnc_attackArea;
                ["AI Commander", 3, format["Assigned attack actions to group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
            };
            
            case "DEFEND": {
                [_taskForceGroup, _targetPosition] call FLO_fnc_defendArea;
                ["AI Commander", 3, format["Assigned defend actions to group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
            };
            
            case "PATROL": {
                [_taskForceGroup, _targetPosition] call FLO_fnc_patrolArea;
                ["AI Commander", 3, format["Assigned patrol actions to group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
            };
            
            case "SKIRMISH": {
                // For skirmish, we alternate between attack and recon based on the situation
                if (random 1 > 0.5) then {
                    [_taskForceGroup, _targetPosition] call FLO_fnc_attackArea;
                    ["AI Commander", 3, format["Assigned attack actions (skirmish) to group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
                } else {
                    [_taskForceGroup, _targetPosition] call FLO_fnc_reconArea;
                    ["AI Commander", 3, format["Assigned recon actions (skirmish) to group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
                };
            };
            
            case "RECON": {
                [_taskForceGroup, _targetPosition] call FLO_fnc_reconArea;
                ["AI Commander", 3, format["Assigned recon actions to group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
            };
            
            default {
                ["AI Commander", 3, format["Unknown operation type %1 for group %2", _operationType, _taskForceGroup]] call FLO_fnc_log;
                false
            };
        };
        
        true
    }],
    
    ["_update", {
     
        private _currentTime = diag_tickTime;
        private _lastUpdate = _self get "_lastUpdate";
        private _updateInterval = _self get "_commanderUpdateInterval";
        
        // Only update periodically
        if (_currentTime - _lastUpdate < _updateInterval) exitWith {};
        
        // Assess current threat situation
        private _threat = _self call ["_assessThreat", []];
        
        // Deploy task forces as needed
        _self call ["_deployTaskForces", []];
        
        // Occasionally check for BLUFOR in the field even outside regular task force deployment
        // This ensures direct response to BLUFOR incursions
        if (_self get "_operationMode" != "DEFEND" && random 1 > 0.7) then {
            _self call ["_attackBluforInField", [_self get "_taskForceStrengthFactor"]];
        };
        
        // Check if it's time for special operations (and we don't have an active team)
        private _lastSpecialOps = _self get "_lastSpecialOps";
        private _specialOpsInterval = _self get "_specialOpsUpdateInterval";
        
        if (_currentTime - _lastSpecialOps > _specialOpsInterval && !(_self get "_hasSpecialOps")) then {
            _self call ["_deploySpecialOperations", []];
        };
        
        // Update last update time
        _self set ["_lastUpdate", _currentTime];
    }],
    
    ["_processReconReport", {
        params ["_reportData", "_reportingGroup"];
        
        // Extract information from the report data
        _reportData params [
            "_position",
            "_enemyCount",
            "_infantry",
            "_vehicles",
            "_armor",
            "_air",
            "_enemyTypes"
        ];
        
        // Log the recon report at command level
        ["AI Commander", 2, format["RECON REPORT RECEIVED: %1 total enemies at %2 (%3 infantry, %4 vehicles, %5 armor, %6 air)", 
            _enemyCount, _position, _infantry, _vehicles, _armor, _air]] call FLO_fnc_log;
        
        // Decide whether to act on the information
        private _shouldRespond = false;
        private _responseType = "";
        private _operationMode = _self get "_operationMode";
        
        // Determine if this is a significant enemy presence worth responding to
        switch (_operationMode) do {
            case "ATTACK": {
                // In attack mode, only respond to significant forces
                if (_enemyCount >= 8 || _armor > 0 || _air > 0) then {
                    _shouldRespond = true;
                    _responseType = "ATTACK";
                };
            };
            
            case "DEFEND": {
                // In defend mode, respond to even small forces to protect territory
                if (_enemyCount >= 4 || _armor > 0) then {
                    _shouldRespond = true;
                    _responseType = "DEFEND";
                };
            };
            
            case "SKIRMISH": {
                // In skirmish mode, be selective about engagement
                if ((_enemyCount >= 6 && _infantry > 3) || _armor > 0) then {
                    _shouldRespond = true;
                    _responseType = "SKIRMISH";
                };
            };
        };
        
        // If we decide to respond, find a suitable outpost to deploy from
        if (_shouldRespond) then {
            // Get outposts that can deploy task forces
            private _outposts = keys (_self get "_outpostStatus");
            private _availableOutposts = _outposts select {
                private _data = ((_self get "_outpostStatus") get _x) select 0;
                _data < 0.4 // Only deploy from outposts not under heavy threat
            };
            
            if (count _availableOutposts == 0) exitWith {
                ["AI Commander", 3, "Cannot respond to recon report - no outposts available"] call FLO_fnc_log;
            };
            
            // Find the closest outpost to respond
            private _nearOutposts = [_availableOutposts, [], {(getMarkerPos _x) distance _position}, "ASCEND"] call BIS_fnc_sortBy;
            
            if (count _nearOutposts > 0) then {
                private _sourceOutpost = _nearOutposts select 0;
                private _taskForceStrengthFactor = _self get "_taskForceStrengthFactor";
                
                // Calculate appropriate task force size based on enemy force
                private _taskForceSize = round((_enemyCount * 1.5) * _taskForceStrengthFactor);
                _taskForceSize = _taskForceSize max 6 min 30; // Ensure reasonable size limits
                
                // Generate a unique task force ID
                private _taskForceID = format ["TF_RECON_RESPONSE_%1_%2", _sourceOutpost, floor(random 1000)];
                
                // Choose appropriate unit types based on enemy composition
                private _unitTypes = [];
                
                if (_armor > 0) then {
                    // If enemy has armor, prioritize AT units
                    private _atSpecialists = East_Units select {_x find "_AT_F" > 0};
                    _unitTypes = East_Units + _atSpecialists;
                } else {
                    if (_air > 0) then {
                        // If enemy has air, prioritize AA units
                        private _aaSpecialists = East_Units select {_x find "_AA_F" > 0};
                        _unitTypes = East_Units + _aaSpecialists;
                    } else {
                        // Regular infantry mix for general response
                        _unitTypes = East_Units;
                    };
                };
                
                // Pull units from the garrison
                private _units = FLO_TaskForce_Garrison_Integration call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                
                if (count _units > 0) then {
                    // Deploy task force with the pulled units
                    private _taskForceGroup = [_sourceOutpost, _position, _responseType, _taskForceStrengthFactor, _units, _taskForceID] call FLO_fnc_TaskForceSystem;
                    
                    // Assign appropriate actions based on response type
                    _self call ["_assignTaskForceActions", [_taskForceGroup, _position, _responseType]];
                    
                    // Create a temporary marker for the target location
                    private _markerName = format ["recon_response_%1_%2", floor random 1000, floor diag_tickTime];
                    private _marker = createMarker [_markerName, _position];
                    _marker setMarkerType "o_unknown";
                    _marker setMarkerColor "ColorRed";
                    _marker setMarkerAlpha 0.7;
                    _marker setMarkerText format ["Recon Target (%1)", _enemyCount];
                    
                    // Set up marker deletion after 5 minutes
                    [_markerName] spawn {
                        params ["_markerName"];
                        sleep 300;
                        deleteMarker _markerName;
                    };
                    
                    ["AI Commander", 2, format["Deploying %4 force from %1 to respond to recon report at %2 with %3 units", 
                        _sourceOutpost, _position, count _units, _responseType]] call FLO_fnc_log;
                } else {
                    ["AI Commander", 3, format["Failed to pull units from garrison at %1 for recon response", _sourceOutpost]] call FLO_fnc_log;
                };
            };
        } else {
            ["AI Commander", 3, "Recon report noted but no response required"] call FLO_fnc_log;
        };
    }]
]];

// Initialize Commander
_aiCommander set ["_commanderUpdateInterval", 300]; // 5 minutes
_aiCommander set ["_specialOpsUpdateInterval", 900]; // 15 minutes
_aiCommander set ["_threatThreshold", 0.6];

// Start the commander loop
[_aiCommander] spawn {
    params ["_commander"];
    
    while {true} do {
        // Update the commander
        _commander call ["_update", []];
        
        // Sleep for a bit to prevent excessive CPU usage
        sleep 60;
    };
};

// Set the global AI Commander variable for other scripts to reference
FLO_AI_Commander = _aiCommander;
["AI Commander", 3, "Global AI Commander variable set"] call FLO_fnc_log;

// Return the commander object
_aiCommander 