/*
 * Function: FLO_fnc_templateIntelGathering
 * Author: Frontline Operations Development Group
 * Description:
 *   Template for the Intel Gathering side mission.
 *   Investigate enemy positions and recover intel documents.
 *
 * Returns:
 *   HASHMAP - Mission template configuration
 */

private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
if !(_activeSide in [east, west]) then { _activeSide = west };
private _enemyColor = if (_activeSide isEqualTo east) then { "colorBLUFOR" } else { "colorOPFOR" };

private _template = createHashMapFromArray [
    ["name", "Gather Enemy Intel"],
    ["description", "Reports hint at enemy plans stored nearby. Investigate recon positions and gather intel."],
    ["icon", "mil_unknown"],
    ["color", _enemyColor],
    ["cooldown", 600],
    ["timeout", 2400],
    ["maxActive", 2],
    ["reward", 30],
    ["isConvoy", false],
    
    ["fnc_setup", {
        params ["_typeName"];

        private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_activeSide in [east, west]) then { _activeSide = west };
        private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };

        private _position = [0,0,0];
        private _canSpawn = false;

        // Helper to check if position is in enemy territory
        private _fnc_isInEnemyTerritory = {
            params ["_pos"];
            private _inEnemy = false;
            if (!isNil "FLO_Objectives") then {
                {
                    private _objData = FLO_Objectives get _x;
                    if (!isNil "_objData") then {
                        private _owner = _objData get "owner";
                        if (_owner isEqualType "") then {
                            private _ownerKey = toUpper _owner;
                            if (_ownerKey isEqualTo "EAST") then { _owner = east; };
                            if (_ownerKey isEqualTo "WEST") then { _owner = west; };
                        };
                        if (_owner isEqualTo _enemySide) then {
                            if ([_pos, _objData] call FLO_fnc_isPositionInObjective) then {
                                _inEnemy = true;
                            };
                        };
                    };
                    if (_inEnemy) then { break };
                } forEach (keys FLO_Objectives);
            };
            _inEnemy
        };

        // Look for elevated positions (mounts) in OPFOR territory
        private _mounts = nearestLocations [getPos player, ["Mount"], 1500];
        private _validMounts = _mounts select { [locationPosition _x] call _fnc_isInEnemyTerritory };

        if ((count _validMounts) > 0) then {
            _position = locationPosition (selectRandom _validMounts);
            _canSpawn = true;
        } else {
            // Fallback to house near enemy-controlled objective
            private _objId = [3000, getPos player, _enemySide] call FLO_fnc_getObjectiveNearPlayer;
            if (_objId != "") then {
                private _searchPos = [_objId] call FLO_fnc_getRandomObjectivePos;
                private _house = [_searchPos] call FLO_fnc_findMissionHouse;
                if (!isNull _house) then {
                    _position = getPos _house;
                    _canSpawn = true;
                };
            };
        };

        [_canSpawn, _position]
    }],
    
    ["fnc_spawn", {
        params ["_missionId"];

        private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_activeSide in [east, west]) then { _activeSide = west };
        private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };
        private _enemyKey = if (_enemySide isEqualTo east) then { "EAST" } else { "WEST" };
        private _enemyCatalog = missionNamespace getVariable ["FLO_FactionCatalog", createHashMap] getOrDefault [_enemyKey, createHashMap];
        private _enemyUnits = _enemyCatalog getOrDefault ["units", if (!isNil "East_Units") then { East_Units } else { ["O_Soldier_F"] }];
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _position = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        private _data = _instance get "data";
        _data set ["intelCollected", false];
        
        // Check if we are spawning at a house
        private _house = nearestBuilding _position;
        private _isHouse = (!isNull _house && {_house distance2D _position < 10});
        
        if (_isHouse) then {
            // INDOOR MODE: Do not spawn composition. Place intel inside.
            private _buildingPos = _house buildingPos -1;
            if ((count _buildingPos) == 0) then { _buildingPos = [getPos _house]; };
            
            // Spawn MapBoard inside
            private _mapBoardPos = selectRandom _buildingPos;
            createVehicle ["MapBoard_altis_F", _mapBoardPos, [], 0, "CAN_COLLIDE"];
            
            // Move position to match house for patrol/units logic
            _position = getPos _house;
        } else {
            // OUTDOOR MODE: Find flat position for composition
            private _flatPos = [_position, 0, 50, 5, 0, 0.25, 0] call BIS_fnc_findSafePos;
            _position = _flatPos;
            
            ["Recon_OPF_1", _position, [0,0,0], 0, true] call LARs_fnc_spawnComp;
        };
        
        // Find map board after spawning and add intel collection action
        [_position, _data, _missionId] spawn {
            params ["_position", "_data", "_missionId"];
            sleep 3;
            // Search for map board (either from composition or manually placed)
            private _mapBoard = nearestObjects [_position, ["MapBoard_altis_F"], 50] select 0;
            if (!isNull _mapBoard) then {
                _data set ["mapBoard", _mapBoard];
                ["addEntity", [_missionId, _mapBoard]] call FLO_fnc_sideMissionEntityTracker;
                
                // Add our mission-integrated hold action
                [
                    _mapBoard,
                    "Collect Intel Documents",
                    "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_search_ca.paa",
                    "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_search_ca.paa",
                    "_this distance _target < 5",
                    "_caller distance _target < 5",
                    {},
                    {},
                    {
                        params ["_target", "_caller", "_actionId", "_arguments"];
                        _arguments params ["_missionData", "_missionId"];
                        
                        // Mark intel as collected (Network Engineer in Arma :dedmanfix:)
                        _missionData set ["intelCollected", true];
                        
                        [
                            [_missionId],
                            {
                                params ["_mid"];
                                private _inst = ["get", [_mid]] call FLO_fnc_sideMissionRegistry;
                                if (!isNil "_inst") then {
                                    private _d = _inst get "data";
                                    _d set ["intelCollected", true];
                                    ["complete", [_mid, true, "Intel collected"]] call FLO_fnc_sideMissionManager;
                                    ["SIDE_MISSION", 3, format["Intel collected for mission %1 (synced)", _mid]] call FLO_fnc_log;
                                };
                            }
                        ] remoteExec ["call", 2];
                        
                        // Provide intel reward - reveal enemy groups
                        [player, 3000, "STR_FLO_INTEL_MIL"] call FLO_fnc_revealRandomEnemyGroup;
                        [player, 3000, "STR_FLO_INTEL_MIL"] call FLO_fnc_revealRandomEnemyGroup;
                        
                        // Success notification
                        ["STR_FLO_INTEL_FOUND", "success"] call FLO_fnc_sendNotification;
                        hint "Intel documents collected! Enemy positions revealed.";
                        
                        // Remove the action
                        [_target, _actionId] remoteExec ["BIS_fnc_holdActionRemove", 0];
                        
                        ["SIDE_MISSION", 3, format["Intel collected for mission %1", _missionId]] call FLO_fnc_log;
                    },
                    {},
                    [_data, _missionId],
                    8,
                    0,
                    true,
                    false
                ] remoteExec ["BIS_fnc_holdActionAdd", 0, _mapBoard];
            };
        };
        
        // Set proper loadouts on spawned units
        {
            _x setUnitLoadout (selectRandom _enemyUnits);
            ["addEntity", [_missionId, _x]] call FLO_fnc_sideMissionEntityTracker;
        } forEach (nearestObjects [_position, ["Man"], 50] select { side _x == _enemySide });
        
        // Spawn patrol
        private _patrolGrp = [_position getPos [30, random 360], _enemySide, [
            selectRandom _enemyUnits, selectRandom _enemyUnits, selectRandom _enemyUnits,
            selectRandom _enemyUnits, selectRandom _enemyUnits
        ]] call BIS_fnc_spawnGroup;
        _patrolGrp deleteGroupWhenEmpty true;
        [_patrolGrp, _position, 70, 4, "AWARE", "LIMITED"] call FLO_fnc_taskPatrol;
        ["addGroup", [_missionId, _patrolGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        // Additional positions based on difficulty
        if (_aggrScore > 5) then {
            private _mounts = nearestLocations [_position, ["Mount"], 500];
            if ((count _mounts) > 0) then {
                private _pos2 = locationPosition (selectRandom _mounts);
                ["Watchpost_8", _pos2, [0,0,0], 0, true] call LARs_fnc_spawnComp;
                
                private _grp = [_pos2 getPos [20, random 360], _enemySide, [
                    selectRandom _enemyUnits, selectRandom _enemyUnits
                ]] call BIS_fnc_spawnGroup;
                _grp deleteGroupWhenEmpty true;
                [_grp, _pos2, 50, 4, "AWARE", "LIMITED"] call FLO_fnc_taskPatrol;
                ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
            };
        };

        if (_aggrScore > 10) then {
            private _mounts = nearestLocations [_position, ["Mount"], 500];
            if ((count _mounts) > 0) then {
                private _pos3 = locationPosition (selectRandom _mounts);
                ["Recon_OPF_2", _pos3, [0,0,0], 0, true] call LARs_fnc_spawnComp;

                private _grp = [_pos3 getPos [20, random 360], _enemySide, [
                    selectRandom _enemyUnits, selectRandom _enemyUnits, selectRandom _enemyUnits
                ]] call BIS_fnc_spawnGroup;
                _grp deleteGroupWhenEmpty true;
                [_grp, _pos3, 70, 4, "AWARE", "LIMITED"] call FLO_fnc_taskPatrol;
                ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
            };
        };
        
        // Add intel items nearby
        [_position, 300] call FLO_fnc_addIntelItems;
        
        [_missionId] call FLO_fnc_sideMissionTaskCreate;
    }],
    
    // Success - intel collected (via action on map board or all enemies killed)
    ["fnc_checkSuccess", {
        params ["_missionId", "_instance"];
        private _enemySide = if ((missionNamespace getVariable ["FLO_ActivePlayerSide", west]) isEqualTo east) then { west } else { east };
        private _data = _instance get "data";
        
        // Check if intel was marked as collected
        if (_data getOrDefault ["intelCollected", false]) exitWith { true };
        
        // Or check if all nearby enemies eliminated (simpler check)
        private _position = _instance get "position";
        private _units = _position nearEntities ["Man", 150];
        private _enemyCount = 0;

        {
            if (!alive _x) then { continue };
            private _uSide = side _x;
            if (isPlayer _x) then {
                _uSide = side group _x;
            };
            if (_uSide isEqualTo _enemySide) then {
                _enemyCount = _enemyCount + 1;
            };
        } forEach _units;

        {
            if (!alive _x) then { continue };
            if ((_x distance2D _position) > 150) then { continue };
            if (_x in _units) then { continue };
            if ((side group _x) isEqualTo _enemySide) then {
                _enemyCount = _enemyCount + 1;
            };
        } forEach allPlayers;

        _enemyCount == 0
    }],
    
    ["fnc_checkFail", {
        params ["_missionId", "_instance"];
        private _data = _instance get "data";
        private _mapBoard = _data getOrDefault ["mapBoard", objNull];
        private _intelCollected = _data getOrDefault ["intelCollected", false];
        
        // Fail if the intel source is destroyed before collection
        if (!_intelCollected && {!isNull _mapBoard} && {!alive _mapBoard}) exitWith { 
            true 
        };
        
        false
    }],
    
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
    }]
];

_template
