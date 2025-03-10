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
private _lastCommanderUpdate = diag_tickTime;
private _commanderUpdateInterval = 300; // 5 minutes between strategy updates
private _currentThreatLevel = 0;
private _threatThreshold = 0.6; // Threshold to switch to defensive mode if under heavy attack
private _taskForceStrengthFactor = 1.0; // Multiplier for task force size

// Set up the Commander object using a HashMap
private _aiCommander = createHashMapObject [[
    ["_operationMode", _operationMode], // Current operation mode
    ["_threatLevel", _currentThreatLevel], // Current threat level
    ["_lastUpdate", _lastCommanderUpdate], // Last time the commander updated
    ["_outpostStatus", createHashMap], // Tracks outpost status
    ["_virtualGroups", createHashMap], // Tracks virtual groups under commander control
    ["_activeTasksforvirtualGroups", createHashMap], // Tracks active tasks for virtual groups

    // Methods
    ["_updateOperationMode", {
        params ["_newMode"];
        private _oldMode = _self get "_operationMode";
        
        if (_oldMode != _newMode) then {
            _self set ["_operationMode", _newMode];
            ["AI Commander", 3, format["Operation mode changed from %1 to %2", _oldMode, _newMode]] call FLO_fnc_log;
            
            // Adjust task force behavior based on new mode
            switch (_newMode) do {
                case "Offensive": {
                    _self set ["_taskForceStrengthFactor", 1.5]; // More offensive units
                };
                case "Defensive": {
                    _self set ["_taskForceStrengthFactor", 0.8]; // Focus on defense
                }; 
                // TODO: Add Additional Operation Modes Here
            };
        }
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
            _self call ["_updateOperationMode", ["PATROL"]];
        };
        
        ["AI Commander", 3, format["Current threat assessment: %1", _totalThreat]] call FLO_fnc_log;
        
        _totalThreat
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
        
        // TOOD: GET THIS WORKING
        // if (_currentTime - _lastSpecialOps > _specialOpsInterval && !(_self get "_hasSpecialOps")) then {
        //     _self call ["_deploySpecialOperations", []];
        // };
        
        // Update last update time
        _self set ["_lastUpdate", _currentTime];
    }],
    
    // Add a new method to select the best outpost based on garrison strength
    // This will be converted to _selectBestOutpostToAssign VGroup Too
    // Pending Crashdome's Opinion
    ["_selectBestOutpostForTaskForce", {
        params ["_availableOutposts", "_requiredSize"];
        
        // Default to random selection if no specific size is provided
        if (isNil "_requiredSize" || {_requiredSize <= 0}) exitWith {
            selectRandom _availableOutposts
        };
        
        // Get frontline outposts from Logistics Network if available
        private _frontlineOutposts = [];
        if (!isNil "FLO_Logistics_Network") then {
            _frontlineOutposts = FLO_Logistics_Network call ["getFrontlineOutposts", []];
            ["AI Commander", 3, format["Found %1 frontline outposts from Logistics Network", count _frontlineOutposts]] call FLO_fnc_log;
        };
        
        // Filter available outposts to prioritize frontline outposts
        private _prioritizedOutposts = [];
        if (count _frontlineOutposts > 0) then {
            // Only include outposts that are both available and on the frontline
            _prioritizedOutposts = _availableOutposts select {_x in _frontlineOutposts};
            
            ["AI Commander", 3, format["%1 of %2 available outposts are on the frontline", 
                count _prioritizedOutposts, count _availableOutposts]] call FLO_fnc_log;
                
            // If we found frontline outposts among available ones, use only those
            if (count _prioritizedOutposts > 0) then {
                _availableOutposts = _prioritizedOutposts;
            } else {
                ["AI Commander", 3, "No frontline outposts available for task force, using standard available outposts"] call FLO_fnc_log;
            };
        } else {
            ["AI Commander", 3, "No frontline outposts data from Logistics Network, using standard available outposts"] call FLO_fnc_log;
        };
        
        private _bestOutpost = "";
        private _bestSurplus = 0;
        private _candidates = [];
        
        // First, check all outposts and calculate their surplus capacity
        {
            private _outpost = _x;
            // Get garrison data
            private _garrisonStrength = FLO_Garrison_Manager call ["_checkGarrisonStrength", [_outpost]];
            
            // Get minimum required garrison size based on marker type
            private _markerType = markerType _outpost;
            private _baseMinSize = switch (_markerType) do {
                case "o_installation": { 15 };
                case "n_installation": { 12 };
                case "o_support": { 8 };
                case "n_support": { 10 };
                case "loc_Power": { 6 };
                case "o_recon": { 2 };
                case "o_service": { 6 };
                case "o_antiair": { 8 };
                case "loc_Ruin": { 12 };
                default { 4 };
            };
            
            // Calculate adjusted minimum based on current strength
            private _adjustedMin = switch (true) do {
                case (_garrisonStrength >= 75): { _baseMinSize * 0.5 }; // Very large garrisons can go down to 50% of min
                case (_garrisonStrength >= 50): { _baseMinSize * 0.6 }; // Large garrisons can go down to 60% of min
                case (_garrisonStrength >= 30): { _baseMinSize * 0.7 }; // Medium garrisons can go down to 70% of min
                case (_garrisonStrength >= 20): { _baseMinSize * 0.8 }; // Smaller garrisons can go down to 80% of min
                default { _baseMinSize }; // Base minimum for small garrisons
            };
            _adjustedMin = round _adjustedMin max 2;
            
            // Calculate surplus - how many units can we pull without going below the adjusted minimum
            private _surplus = _garrisonStrength - _adjustedMin;
            
            // Add frontline bonus for outposts that are on the frontline
            private _frontlineBonus = if (_outpost in _frontlineOutposts) then {
                // Give extra weight to frontline outposts
                _surplus = _surplus * 1.5;
                " (FRONTLINE)"
            } else {
                ""
            };
            
            // Store as a candidate if it has sufficient surplus
            if (_surplus >= _requiredSize) then {
                // Include outpost, strength, surplus, and frontline status in the candidate data
                _candidates pushBack [_outpost, _garrisonStrength, _surplus, _adjustedMin, _outpost in _frontlineOutposts];
                
                // Track the outpost with the largest surplus as fallback
                if (_surplus > _bestSurplus) then {
                    _bestOutpost = _outpost;
                    _bestSurplus = _surplus;
                };
                
                ["AI Commander", 4, format["Candidate outpost: %1%2 with %3 units (surplus: %4, min: %5)", 
                    _outpost, _frontlineBonus, _garrisonStrength, _surplus, _adjustedMin]] call FLO_fnc_log;
            };
        } forEach _availableOutposts;
        
        // If we have candidates, select the best one
        if (count _candidates > 0) then {
            // First sort by frontline status (prioritize frontline outposts)
            _candidates = [_candidates, [], {if (_x select 4) then {0} else {1}}, "ASCEND"] call BIS_fnc_sortBy;
            
            // Then prioritize by surplus-to-strength ratio within each category (frontline vs non-frontline)
            private _frontlineCandidates = _candidates select {_x select 4};
            private _otherCandidates = _candidates select {!(_x select 4)};
            
            // Sort frontline candidates 
            if (count _frontlineCandidates > 0) then {
                _frontlineCandidates = [_frontlineCandidates, [], {(_x select 2) / (_x select 1)}, "DESCEND"] call BIS_fnc_sortBy;
                
                // Take the top 3 if available
                private _topCandidates = if (count _frontlineCandidates > 3) then {
                    _frontlineCandidates select [0, 3]
                } else {
                    _frontlineCandidates
                };
                
                // From the top candidates, pick the one closest to the task force size + buffer
                _topCandidates = [_topCandidates, [], {abs((_x select 1) - (_requiredSize + 8))}, "ASCEND"] call BIS_fnc_sortBy;
                
                // Select the best candidate
                _bestOutpost = (_topCandidates select 0) select 0;
                
                ["AI Commander", 3, format["Selected FRONTLINE outpost %1 with %2 units (surplus: %3, min: %4) for task force requiring %5 units", 
                    _bestOutpost, 
                    (_topCandidates select 0) select 1, 
                    (_topCandidates select 0) select 2,
                    (_topCandidates select 0) select 3,
                    _requiredSize]] call FLO_fnc_log;
            } else {
                // If no frontline candidates, use other candidates
                _otherCandidates = [_otherCandidates, [], {(_x select 2) / (_x select 1)}, "DESCEND"] call BIS_fnc_sortBy;
                
                // Take the top 3 if available
                private _topCandidates = if (count _otherCandidates > 3) then {
                    _otherCandidates select [0, 3]
                } else {
                    _otherCandidates
                };
                
                // From the top candidates, pick the one closest to the task force size + buffer
                _topCandidates = [_topCandidates, [], {abs((_x select 1) - (_requiredSize + 8))}, "ASCEND"] call BIS_fnc_sortBy;
                
                // Select the best candidate
                _bestOutpost = (_topCandidates select 0) select 0;
                
                ["AI Commander", 3, format["No frontline outposts available with sufficient units. Selected standard outpost %1 with %2 units (surplus: %3, min: %4) for task force requiring %5 units", 
                    _bestOutpost, 
                    (_topCandidates select 0) select 1, 
                    (_topCandidates select 0) select 2,
                    (_topCandidates select 0) select 3,
                    _requiredSize]] call FLO_fnc_log;
            };
        } else {
            // If no suitable candidates, pick the one with the largest garrison
            private _largestOutpost = "";
            private _largestStrength = 0;
            private _isFrontline = false;
            
            {
                private _outpost = _x;
                private _strength = FLO_Garrison_Manager call ["_checkGarrisonStrength", [_outpost]];
                private _outpostIsFrontline = _outpost in _frontlineOutposts;
                
                // Prioritize frontline outposts or ones with larger strength
                if ((_outpostIsFrontline && (!_isFrontline || _strength > _largestStrength * 0.7)) || 
                    (!_isFrontline && !_outpostIsFrontline && _strength > _largestStrength)) then {
                    _largestOutpost = _outpost;
                    _largestStrength = _strength;
                    _isFrontline = _outpostIsFrontline;
                };
            } forEach _availableOutposts;
            
            if (_largestStrength > 0) then {
                _bestOutpost = _largestOutpost;
                private _frontlineStatus = if (_isFrontline) then {"FRONTLINE "} else {""};
                ["AI Commander", 3, format["No outposts with sufficient surplus found. Using largest available: %1%2 with %3 units (need %4)", 
                    _frontlineStatus, _bestOutpost, _largestStrength, _requiredSize]] call FLO_fnc_log;
            } else {
                // Last resort - prioritize frontline outposts for random selection
                if (count _prioritizedOutposts > 0) then {
                    _bestOutpost = selectRandom _prioritizedOutposts;
                    ["AI Commander", 3, format["No outposts with units found. Randomly selected FRONTLINE outpost %1", _bestOutpost]] call FLO_fnc_log;
                } else {
                    // If no frontline outposts, use any available outpost
                    _bestOutpost = selectRandom _availableOutposts;
                    ["AI Commander", 3, format["No outposts with units found. Randomly selected outpost %1", _bestOutpost]] call FLO_fnc_log;
                };
            };
        };
        
        _bestOutpost
    }],
    
    // Issue waypoints to virtual group
    ["_issueVirtualGroupWaypoints", {
        params ["_self", "_groupId", "_waypoints"];
        
        // Skip if virtualization system is not initialized
        if (isNil "FLO_virtualGroups") exitWith {
            ["AI Commander", 2, "Cannot issue virtual group waypoints - virtualization system not initialized"] call FLO_fnc_log;
            false
        };
        
        // Update the virtual group's waypoints
        [_groupId, _waypoints] call FLO_fnc_updateVirtualGroupWaypoints;
        
        // Add to tracked virtual groups
        (_self get "_virtualGroups") set [_groupId, diag_tickTime];
        
        ["AI Commander", 3, format["Issued waypoints to virtual group %1", _groupId]] call FLO_fnc_log;
        true
    }],
    
    // Assign task to a single virtual group near objective
    ["_assignVirtualGroupsTask", {
        params ["_self", "_objectiveId", "_taskType", "_targetPos"];
        
        // Skip if virtualization system is not initialized
        if (isNil "FLO_virtualGroups") exitWith {
            ["AI Commander", 2, "Cannot assign task to virtual group - virtualization system not initialized"] call FLO_fnc_log;
            false
        };
        
        // Find the objective position
        private _objectivePos = getMarkerPos _objectiveId;
        if (_objectivePos isEqualTo [0,0,0]) exitWith {
            ["AI Commander", 3, format["Invalid objective marker: %1", _objectiveId]] call FLO_fnc_log;
            false
        };
        
        // Find a single group that is within 5000m of the objective
        private _selectedGroup = "";
        private _minDistance = 999999;
        private _allGroups = FLO_virtualGroups get "_groups";
        
        {
            private _groupData = _y;
            private _groupPos = _groupData getOrDefault ["position", [0,0,0]];
            private _dist = _groupPos distance _objectivePos;
            
            // If the group is close to this objective and closer than any previously found
            if (_dist < 5000 && _dist < _minDistance) then {
                _selectedGroup = _x;
                _minDistance = _dist;
            };
        } forEach _allGroups;
        
        if (_selectedGroup == "") exitWith {
            ["AI Commander", 3, format["No virtual group found near objective %1", _objectiveId]] call FLO_fnc_log;
            false
        };
        
        // Define waypoint parameters based on task type
        private _wpBehavior = "AWARE";
        private _wpSpeed = "NORMAL";
        private _wpFormation = "COLUMN";
        private _wpCombatMode = "YELLOW";
        
        switch (_taskType) do {
            case "ATTACK": {
                _wpBehavior = "COMBAT";
                _wpSpeed = "FULL";
                _wpCombatMode = "RED";
            };
            case "DEFEND": {
                _wpBehavior = "COMBAT";
                _wpFormation = "LINE";
            };
            case "PATROL": {
                _wpBehavior = "AWARE";
                _wpFormation = "STAG COLUMN";
            };
            case "RECON": {
                _wpBehavior = "STEALTH";
                _wpSpeed = "LIMITED";
            };
        };
        
        // Create waypoint data
        private _waypoints = [[_targetPos, _taskType, _wpBehavior, _wpSpeed, _wpFormation, _wpCombatMode]];
        
        // Issue waypoint to the single selected group
        [_self, _selectedGroup, _waypoints] call (_self get "_issueVirtualGroupWaypoints");
        
        ["AI Commander", 3, format["Assigned %1 task to virtual group %2 near objective %3", _taskType, _selectedGroup, _objectiveId]] call FLO_fnc_log;
        true
    }]
]];

// Initialize Commander
_aiCommander set ["_commanderUpdateInterval", 300];
_aiCommander set ["_threatThreshold", 0.6];

// Start the commander loop
[_aiCommander] spawn {
    params ["_commander"];
    
    while {true} do {
        // Update the commander
        _commander call ["_update", []];
        
        // Sleep for a bit
        sleep 60;
    };
};

// Set the global AI Commander variable for other scripts to reference
FLO_AI_Commander = _aiCommander;
["AI Commander", 3, "Global AI Commander variable set"] call FLO_fnc_log;

// Return the commander object
_aiCommander 