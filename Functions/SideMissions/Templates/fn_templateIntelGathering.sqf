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

private _template = createHashMapFromArray [
    ["name", "Gather Enemy Intel"],
    ["description", "Reports hint at enemy plans stored nearby. Investigate recon positions and gather intel."],
    ["icon", "mil_unknown"],
    ["color", "colorOPFOR"],
    ["cooldown", 600],
    ["timeout", 2400],
    ["maxActive", 2],
    ["reward", 30],
    ["isConvoy", false],
    
    ["fnc_setup", {
        params ["_typeName"];

        private _position = [0,0,0];
        private _canSpawn = false;

        // Helper to check if position is in OPFOR territory
        private _fnc_isInEnemyTerritory = {
            params ["_pos"];
            private _inEnemy = false;
            if (!isNil "FLO_Objectives") then {
                {
                    private _objData = FLO_Objectives get _x;
                    if (!isNil "_objData") then {
                        private _owner = _objData getOrDefault ["owner", east];
                        if (_owner isEqualTo east) then {
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

        if (count _validMounts > 0) then {
            _position = locationPosition (selectRandom _validMounts);
            _canSpawn = true;
        } else {
            // Fallback to house in enemy territory
            private _house = [getPos player] call FLO_fnc_findMissionHouse;
            if (!isNull _house) then {
                _position = getPos _house;
                _canSpawn = true;
            };
        };

        [_canSpawn, _position]
    }],
    
    ["fnc_spawn", {
        params ["_missionId"];
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _position = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        private _data = _instance get "data";
        _data set ["intelCollected", false];
        
        // Spawn recon composition
        ["Recon_OPF_1", _position, [0,0,0], 0, true] call LARs_fnc_spawnComp;
        
        // Find map board after composition spawns and add intel collection action
        [_position, _data, _missionId] spawn {
            params ["_position", "_data", "_missionId"];
            sleep 3;
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
                                    ["SIDE_MISSION", 3, format["Intel collected for mission %1 (synced)", _mid]] call FLO_fnc_log;
                                };
                            }
                        ] remoteExec ["call", 2];
                        
                        // Provide intel reward - reveal enemy groups
                        [player, 3000, "STR_FLO_INTEL_MIL"] call FLO_fnc_revealRandomEnemyGroup;
                        [player, 3000, "STR_FLO_INTEL_MIL"] call FLO_fnc_revealRandomEnemyGroup;
                        
                        // Success notification
                        ["STR_FLO_INTEL_TITLE", "STR_FLO_INTEL_FOUND", "success"] call FLO_fnc_sendNotification;
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
            _x setUnitLoadout (selectRandom East_Units);
            ["addEntity", [_missionId, _x]] call FLO_fnc_sideMissionEntityTracker;
        } forEach (nearestObjects [_position, ["Man"], 50] select { side _x == East });
        
        // Spawn patrol
        private _patrolGrp = [_position getPos [30, random 360], East, [
            selectRandom East_Units, selectRandom East_Units, selectRandom East_Units,
            selectRandom East_Units, selectRandom East_Units
        ]] call BIS_fnc_spawnGroup;
        _patrolGrp deleteGroupWhenEmpty true;
        [_patrolGrp, _position, 70, 4, "AWARE", "LIMITED"] call FLO_fnc_taskPatrol;
        ["addGroup", [_missionId, _patrolGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        // Additional positions based on difficulty
        if (_aggrScore > 5) then {
            private _mounts = nearestLocations [_position, ["Mount"], 500];
            if (count _mounts > 0) then {
                private _pos2 = locationPosition (selectRandom _mounts);
                ["Watchpost_8", _pos2, [0,0,0], 0, true] call LARs_fnc_spawnComp;
                
                private _grp = [_pos2 getPos [20, random 360], East, [
                    selectRandom East_Units, selectRandom East_Units
                ]] call BIS_fnc_spawnGroup;
                _grp deleteGroupWhenEmpty true;
                [_grp, _pos2, 50, 4, "AWARE", "LIMITED"] call FLO_fnc_taskPatrol;
                ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
            };
        };

        if (_aggrScore > 10) then {
            private _mounts = nearestLocations [_position, ["Mount"], 500];
            if (count _mounts > 0) then {
                private _pos3 = locationPosition (selectRandom _mounts);
                ["Recon_OPF_2", _pos3, [0,0,0], 0, true] call LARs_fnc_spawnComp;

                private _grp = [_pos3 getPos [20, random 360], East, [
                    selectRandom East_Units, selectRandom East_Units, selectRandom East_Units
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
        private _data = _instance get "data";
        
        // Check if intel was marked as collected
        if (_data getOrDefault ["intelCollected", false]) exitWith { true };
        
        // Or check if all nearby enemies eliminated (simpler check)
        private _position = _instance get "position";
        private _enemies = (_position nearEntities ["Man", 150]) select { side _x == East && alive _x };
        
        count _enemies == 0
    }],
    
    ["fnc_checkFail", {
        params ["_missionId", "_instance"];
        false
    }],
    
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
    }]
];

_template

